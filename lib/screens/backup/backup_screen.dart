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

  User? get _user => _service.currentUser;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
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

  Future<void> _signInGitHub() => _run(() async {
    // signInWithProvider (ASWebAuthenticationSession) crashes on the
    // iOS simulator. Show a clear message instead of crashing.
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        kDebugMode &&
        kIsWeb == false) {
      // We can't import dart:io in web builds but this path is iOS only.
      // The simulator identifier is injected via DART_VM_OPTIONS by Xcode,
      // so we detect it through the SIMULATOR_UDID env approach at build
      // time. Simplest safe guard: always allow on real devices (profile/
      // release), only warn in debug simulator runs.
      throw Exception(
        'GitHub sign-in is not supported on the iOS Simulator.\n'
        'Please run on a real device or use Android.',
      );
    }
    await _service.signInWithGitHub();
    setState(() {});
    _snack('Signed in as ${_user?.displayName ?? _user?.email ?? 'user'}');
  });

  Future<void> _signOut() => _run(() async {
    await _service.signOut();
    setState(() {});
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
    await _service.backupDecks(decks);
    await _service.backupFlashcards(cards);
    await _service.backupThemeSettings(
      themeTypeIndex: themeState.themeType.index,
      themeModeIndex: themeState.themeMode.index,
      isKidsMode: themeState.isKidsMode,
    );
    _snack('Backed up ${decks.length} decks and ${cards.length} cards ✓');
  });

  Future<void> _restore() => _run(() async {
    final decks = await _service.restoreDecks();
    final cards = await _service.restoreFlashcards();
    final themeData = await _service.restoreThemeSettings();

    // Clear local Hive data first so restore is a true replacement.
    final deckRepo = context.read<HiveDeckRepository>();
    final cardRepo = context.read<HiveFlashcardRepository>();
    await deckRepo.clearAll();
    await cardRepo.clearAll();

    // Write restored data into Hive.
    for (final deck in decks) {
      await deckRepo.addDeck(deck);
    }
    for (final card in cards) {
      await cardRepo.addFlashcard(card);
    }

    // Reload DeckBloc so the deck list screen updates immediately.
    if (mounted) context.read<DeckBloc>().add(LoadDecks());

    // Restore theme settings if present.
    if (mounted && themeData != null) {
      final typeIndex = themeData['themeTypeIndex'] as int;
      final modeIndex = themeData['themeModeIndex'] as int;
      final isKids = themeData['isKidsMode'] as bool;
      final type = AppThemeType
          .values[typeIndex.clamp(0, AppThemeType.values.length - 1)];
      final mode =
          ThemeMode.values[modeIndex.clamp(0, ThemeMode.values.length - 1)];
      context.read<ThemeBloc>()
        ..add(ChangeThemeType(type))
        ..add(SetBrightness(mode));
      if (isKids != context.read<ThemeBloc>().state.isKidsMode) {
        context.read<ThemeBloc>().add(ToggleKidsMode());
      }
    }

    _snack('Restored ${decks.length} decks and ${cards.length} cards ✓');
  });

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
                Text(
                  'Actions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: cs.outline,
                    letterSpacing: 1,
                  ),
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
                  subtitle: 'Download your decks and cards from Firestore',
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
