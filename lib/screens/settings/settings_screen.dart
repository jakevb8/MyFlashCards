// settings_screen.dart
//
// App-wide Settings screen providing account management (sign-out, account
// deletion) and informational links (privacy policy, version).
//
// Why this screen exists: FEAT-009 (Privacy & Account Management) requires a
// Settings entry point accessible from the main deck list. It centralises
// account lifecycle actions — sign-out and permanent deletion — so they are
// discoverable without cluttering the BackupScreen, and surfaces the privacy
// policy required for Play Store compliance.
//
// Key design decisions:
//   - Account deletion is a multi-step operation orchestrated by
//     AccountDeletionService; this screen only drives the confirmation UX and
//     responds to success/failure.
//   - After successful deletion we call setState() to refresh the UI into the
//     signed-out state rather than popping the route. Popping would leave the
//     user on the DeckListScreen with stale signed-in state visible in the
//     AppBar; staying on Settings and showing the signed-out view is cleaner.
//   - HiveDeckRepository and HiveFlashcardRepository are obtained from
//     context.read<>() to stay consistent with how the rest of the app accesses
//     repositories (via RepositoryProvider in main.dart).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/hive_deck_repository.dart';
import '../../repositories/hive_flashcard_repository.dart';
import '../../services/account_deletion_service.dart';
import '../../services/firebase_backup_service.dart';
import 'privacy_policy_screen.dart';

/// Main Settings screen.
///
/// Shows an Account section when the user is signed in (user card, sign-out,
/// delete account) and an About section (privacy policy, version) always.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseBackupService _service = FirebaseBackupService();
  final AccountDeletionService _deletionService = AccountDeletionService();

  // True while account deletion is in progress — drives the loading overlay.
  bool _deleting = false;

  /// Shows a brief SnackBar message. [isError] tints the background error-red.
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

  /// Handles the sign-out action: delegates to FirebaseBackupService then
  /// refreshes the screen to show the signed-out state.
  Future<void> _signOut() async {
    await _service.signOut();
    if (mounted) setState(() {});
  }

  /// Shows a confirmation dialog, then calls AccountDeletionService.deleteAccount().
  ///
  /// On success: refreshes state to show the signed-out view.
  /// On [ReauthRequiredException]: shows a SnackBar with actionable guidance.
  /// On other errors: shows a generic error SnackBar.
  Future<void> _confirmAndDelete() async {
    // Capture repos before any async gap — BuildContext must not be used across
    // an await without a mounted check.
    final deckRepo = context.read<HiveDeckRepository>();
    final cardRepo = context.read<HiveFlashcardRepository>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete all your flashcard data from '
          'Firebase and remove your account. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _deletionService.deleteAccount(
        deckRepo: deckRepo,
        cardRepo: cardRepo,
      );
      // Refresh the UI to reflect signed-out state without popping the screen.
      if (mounted) setState(() {});
      _snack('Account deleted.');
    } on ReauthRequiredException {
      // Firebase requires a recent sign-in for account deletion — guide the user.
      _snack(
        'Please sign out and sign back in, then try again.',
        isError: true,
      );
    } catch (e) {
      _snack('Deletion failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final signedIn = _service.isSignedIn;
    final user = _service.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          ListView(
            children: [
              // ── Account section (signed-in only) ─────────────────────────────
              if (signedIn) ...[
                _SectionHeader(label: 'Account', textTheme: textTheme, cs: cs),

                // Signed-in user card — mirrors the style from BackupScreen.
                _UserCard(user: user!),
                const Divider(indent: 16, endIndent: 16),

                // Sign out
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: _deleting ? null : _signOut,
                ),

                // Delete account — destructive action uses error colour.
                ListTile(
                  leading: Icon(Icons.delete_forever, color: cs.error),
                  title: Text(
                    'Delete my account',
                    style: TextStyle(color: cs.error),
                  ),
                  onTap: _deleting ? null : _confirmAndDelete,
                ),
                const SizedBox(height: 8),
              ],

              // ── About section (always visible) ────────────────────────────────
              _SectionHeader(label: 'About', textTheme: textTheme, cs: cs),

              // Navigate to the in-app Privacy Policy screen.
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
              ),

              // Static version tile — value comes from pubspec.yaml at build time
              // via the package_info_plus package if needed in the future.
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
            ],
          ),

          // Loading overlay shown while account deletion is in progress.
          // Prevents user interaction and communicates that work is happening.
          if (_deleting)
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

/// Section header label — used to visually group related settings tiles.
class _SectionHeader extends StatelessWidget {
  final String label;
  final TextTheme textTheme;
  final ColorScheme cs;

  const _SectionHeader({
    required this.label,
    required this.textTheme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: cs.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Compact user info card showing avatar, display name, and email.
///
/// Matches the visual style of _UserCard in backup_screen.dart so the two
/// screens feel consistent when the user navigates between them.
class _UserCard extends StatelessWidget {
  final User user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
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
            ],
          ),
        ),
      ),
    );
  }
}
