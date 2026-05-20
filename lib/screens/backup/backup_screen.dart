// backup_screen.dart
//
// Cloud Backup screen — lets the user sign in (Google or GitHub), manually
// back up all decks/cards/theme to Firestore, and restore from a prior backup.
//
// Key invariants:
//   - All Firebase operations are delegated to FirebaseBackupService; no
//     Firestore or Auth calls are made directly in this file.
//   - _loading gates every async action so the user cannot trigger concurrent
//     operations (e.g. tapping Back Up Now twice).
//   - Google sign-in is the recommended path (native picker, no browser);
//     GitHub OAuth is kept as an alternative for users who prefer it.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/deck/deck_bloc.dart';
import '../../blocs/deck/deck_event.dart';
import '../../blocs/deck/deck_state.dart';
import '../../blocs/flashcard/flashcard_bloc.dart';
import '../../blocs/flashcard/flashcard_state.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../blocs/theme/theme_event.dart';
import '../../core/theme/app_theme.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../repositories/hive_deck_repository.dart';
import '../../repositories/hive_flashcard_repository.dart';
import '../../services/firebase_backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _service = FirebaseBackupService();
  bool _loading = false;
  BackupMeta? _meta;

  User? get _user => _service.currentUser;

  @override
  void initState() {
    super.initState();
    if (_service.isSignedIn) _loadMeta();
  }

  /// Loads last-backup metadata from Firestore and updates the UI.
  Future<void> _loadMeta() async {
    final meta = await _service.readMeta();
    if (mounted) setState(() => _meta = meta);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } on BackupSchemaException catch (e) {
      _snack(e.toString(), isError: true);
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? e.code, isError: true);
    } catch (e) {
      _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  /// Starts the Google native account picker and signs into Firebase.
  /// No browser window is opened — the OS-level account picker is used,
  /// which is why Google is the recommended sign-in path.
  Future<void> _signInGoogle() => _run(() async {
    await _service.signInWithGoogle();
    setState(() {});
    _snack('Signed in as ${_user?.displayName ?? _user?.email ?? 'user'}');
    await _loadMeta();
  });

  /// Signs in with GitHub using Firebase's built-in OAuth flow.
  /// Not available on the iOS Simulator because ASWebAuthenticationSession
  /// (the underlying browser session API) is unsupported there.
  Future<void> _signInGitHub() => _run(() async {
    // signInWithProvider crashes on the iOS Simulator in debug mode —
    // ASWebAuthenticationSession is not supported there.
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        kDebugMode &&
        kIsWeb == false) {
      throw Exception(
        'GitHub sign-in is not supported on the iOS Simulator.\n'
        'Please run on a real device or use Android.',
      );
    }
    await _service.signInWithGitHub();
    setState(() {});
    _snack('Signed in as ${_user?.displayName ?? _user?.email ?? 'user'}');
    await _loadMeta();
  });

  Future<void> _signOut() => _run(() async {
    await _service.signOut();
    setState(() => _meta = null);
    _snack('Signed out');
  });

  Future<void> _backup() => _run(() async {
    final deckState = context.read<DeckBloc>().state;
    final cardState = context.read<FlashcardBloc>().state;
    final themeState = context.read<ThemeBloc>().state;
    final decks = deckState is DeckLoaded ? deckState.decks : <Deck>[];
    final cards = cardState is FlashcardLoaded
        ? cardState.flashcards
        : <Flashcard>[];
    await _service.backupAll(
      decks: decks,
      cards: cards,
      themeTypeIndex: themeState.themeType.index,
      themeModeIndex: themeState.themeMode.index,
      isKidsMode: themeState.isKidsMode,
    );
    await _loadMeta();
    _snack('Backed up ${decks.length} decks and ${cards.length} cards ✓');
  });

  Future<void> _restore() async {
    // Fetch meta first so the confirmation dialog can show counts.
    final meta = await _service.readMeta();
    if (!mounted) return;

    final deckCount = meta?.deckCount ?? 0;
    final cardCount = meta?.cardCount ?? 0;
    final countText = meta == null
        ? 'your cloud backup'
        : '$deckCount deck${deckCount == 1 ? '' : 's'} and '
              '$cardCount card${cardCount == 1 ? '' : 's'}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup?'),
        content: Text(
          'This will replace all local data with $countText from Firestore. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(() async {
      // Capture context-dependent objects before any awaits.
      final deckRepo = context.read<HiveDeckRepository>();
      final cardRepo = context.read<HiveFlashcardRepository>();
      final deckBloc = context.read<DeckBloc>();
      final themeBloc = context.read<ThemeBloc>();

      final decks = await _service.restoreDecks();
      final cards = await _service.restoreFlashcards();
      final themeData = await _service.restoreThemeSettings();

      // Clear local Hive data first so restore is a true replacement.
      await deckRepo.clearAll();
      await cardRepo.clearAll();

      for (final deck in decks) {
        await deckRepo.addDeck(deck);
      }
      for (final card in cards) {
        await cardRepo.addFlashcard(card);
      }

      if (mounted) deckBloc.add(LoadDecks());

      if (mounted && themeData != null) {
        final typeIndex = themeData['themeTypeIndex'] as int;
        final modeIndex = themeData['themeModeIndex'] as int;
        final isKids = themeData['isKidsMode'] as bool;
        final type = AppThemeType
            .values[typeIndex.clamp(0, AppThemeType.values.length - 1)];
        final mode =
            ThemeMode.values[modeIndex.clamp(0, ThemeMode.values.length - 1)];
        themeBloc
          ..add(ChangeThemeType(type))
          ..add(SetBrightness(mode));
        if (isKids != themeBloc.state.isKidsMode) {
          themeBloc.add(ToggleKidsMode());
        }
      }

      _snack('Restored ${decks.length} decks and ${cards.length} cards ✓');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final signedIn = _service.isSignedIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Backup')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(Icons.cloud_sync_outlined, size: 72, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                'Back up your decks to Firebase',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to sync your flashcards across devices.\n'
                'Firebase Spark (free tier) — no cost to you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.outline),
              ),
              const SizedBox(height: 32),
              if (!signedIn) ...[
                // Google is listed first as the recommended option — native
                // picker requires no browser and works on the iOS Simulator.
                _ActionCard(
                  icon: Icons.g_mobiledata,
                  title: 'Sign in with Google',
                  subtitle: 'Recommended — one tap, no browser window',
                  onTap: _loading ? null : _signInGoogle,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.code,
                  title: 'Sign in with GitHub',
                  subtitle: 'OAuth — opens a secure browser window',
                  onTap: _loading ? null : _signInGitHub,
                ),
              ] else ...[
                _UserCard(user: _user!, onSignOut: _loading ? null : _signOut),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Actions',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: cs.outline,
                        letterSpacing: 1,
                      ),
                    ),
                    if (_meta != null)
                      Text(
                        'Last backed up ${_relativeTime(_meta!.lastBackupAt)}',
                        style: TextStyle(fontSize: 12, color: cs.outline),
                      )
                    else
                      Text(
                        'Never backed up',
                        style: TextStyle(fontSize: 12, color: cs.outline),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.cloud_upload_outlined,
                  title: 'Back Up Now',
                  subtitle: 'Upload all decks and cards to Firestore',
                  onTap: _loading ? null : _backup,
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.cloud_download_outlined,
                  title: 'Restore',
                  subtitle: 'Replace local data with your Firestore backup',
                  onTap: _loading ? null : _restore,
                ),
              ],
            ],
          ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  /// Returns a human-readable relative time string (e.g. "2 hours ago").
  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    final d = diff.inDays;
    return '$d day${d == 1 ? '' : 's'} ago';
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback? onSignOut;
  const _UserCard({required this.user, this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : null,
              child: user.photoURL == null
                  ? Icon(Icons.person, color: cs.onPrimaryContainer)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'Signed in',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (user.email != null)
                    Text(
                      user.email!,
                      style: TextStyle(fontSize: 12, color: cs.outline),
                    ),
                ],
              ),
            ),
            TextButton(onPressed: onSignOut, child: const Text('Sign out')),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(icon, color: cs.onPrimaryContainer),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: onTap == null ? cs.outline : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
