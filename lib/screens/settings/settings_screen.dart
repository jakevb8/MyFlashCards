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
// FEAT-002 adds an "AI Settings" section (first in the list) where users can
// save, view, and clear their Gemini API key via a bottom sheet. The key itself
// is never rendered in plain text — only the last 4 characters are shown as a
// masked suffix. The SettingsBloc is instantiated at screen level so it survives
// the bottom sheet opening and closing.
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
//   - SettingsBloc is created in initState (not inside build) so that it is not
//     re-created on every rebuild — critical for the bottom sheet which reads
//     bloc state after the sheet is dismissed.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../repositories/hive_deck_repository.dart';
import '../../repositories/hive_flashcard_repository.dart';
import '../../services/account_deletion_service.dart';
import '../../services/firebase_backup_service.dart';
import 'gemini_key_walkthrough.dart';
import 'privacy_policy_screen.dart';

/// Main Settings screen.
///
/// Shows an AI Settings section always (for Gemini key management), an Account
/// section when the user is signed in (user card, sign-out, delete account),
/// and an About section (privacy policy, version) always.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseBackupService _service = FirebaseBackupService();
  final AccountDeletionService _deletionService = AccountDeletionService();

  // SettingsBloc is class-level so it is shared between the screen and the
  // bottom sheet — the sheet reads the same bloc instance, meaning state
  // (e.g. errorMessage, geminiKeyStatus) is consistent even after the sheet
  // is shown and dismissed.
  late final SettingsBloc _settingsBloc;

  // True while account deletion is in progress — drives the loading overlay.
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _settingsBloc = SettingsBloc();
    // Hydrate the bloc from secure storage / SharedPreferences immediately on open.
    _settingsBloc.add(GeminiKeyLoaded());
    _settingsBloc.add(NotificationPrefsLoaded());
  }

  @override
  void dispose() {
    _settingsBloc.close();
    super.dispose();
  }

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

  /// Opens the system time picker and dispatches [ReminderTimeChanged] if the
  /// user selects a new time. Safe to call whether or not the reminder is on.
  Future<void> _pickReminderTime(
    BuildContext context,
    TimeOfDay current,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null && mounted) {
      _settingsBloc.add(ReminderTimeChanged(picked));
    }
  }

  /// Opens the Gemini API key bottom sheet.
  ///
  /// The sheet reads from and writes to [_settingsBloc], which is provided via
  /// BlocProvider.value so the existing instance (not a new one) is used.
  /// This ensures that state changes made inside the sheet (e.g. validation
  /// errors) are visible to the settings screen after the sheet closes.
  void _showKeyBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Provide the existing bloc — do NOT create a new one here.
      builder: (sheetContext) => BlocProvider.value(
        value: _settingsBloc,
        child: const _GeminiKeyBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final signedIn = _service.isSignedIn;
    final user = _service.currentUser;

    return BlocProvider.value(
      value: _settingsBloc,
      child: BlocListener<SettingsBloc, SettingsState>(
        listenWhen: (p, c) =>
            c.notificationError != null &&
            p.notificationError != c.notificationError,
        listener: (context, state) =>
            _snack(state.notificationError!, isError: true),
        child: Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: Stack(
            children: [
              ListView(
                children: [
                  // ── AI Settings section (always visible) ──────────────────────
                  _SectionHeader(
                    label: 'AI Settings',
                    textTheme: textTheme,
                    cs: cs,
                  ),

                  // Key status tile — shows masked status, never the raw key.
                  BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      final String subtitle;
                      if (state.geminiKeyStatus == GeminiKeyStatus.set) {
                        // Show last 4 chars of the draft if available, otherwise
                        // generic confirmation. We avoid reading from storage here
                        // to keep the build method synchronous.
                        final draft = state.draftKey;
                        final suffix = draft.length >= 4
                            ? draft.substring(draft.length - 4)
                            : null;
                        subtitle = suffix != null
                            ? 'Key saved ✓ (ends in ••••$suffix)'
                            : 'Key saved ✓';
                      } else {
                        subtitle = 'No key saved';
                      }
                      return ListTile(
                        leading: Icon(
                          state.geminiKeyStatus == GeminiKeyStatus.set
                              ? Icons.vpn_key
                              : Icons.vpn_key_outlined,
                          color: state.geminiKeyStatus == GeminiKeyStatus.set
                              ? cs.primary
                              : cs.outline,
                        ),
                        title: const Text('Gemini API Key'),
                        subtitle: Text(subtitle),
                      );
                    },
                  ),

                  // Edit key tile — opens the bottom sheet.
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Edit API Key'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showKeyBottomSheet(context),
                  ),

                  const SizedBox(height: 8),

                  // ── Reminders section (always visible) ───────────────────────
                  _SectionHeader(
                    label: 'Reminders',
                    textTheme: textTheme,
                    cs: cs,
                  ),

                  BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          SwitchListTile(
                            secondary: state.isScheduling
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.notifications_outlined),
                            title: const Text('Daily reminder'),
                            subtitle: state.reminderEnabled
                                ? Text(
                                    'Fires at ${state.reminderTime.format(context)}',
                                  )
                                : const Text('Off'),
                            value: state.reminderEnabled,
                            onChanged: state.isScheduling
                                ? null
                                : (v) => context.read<SettingsBloc>().add(
                                    ReminderToggled(v),
                                  ),
                          ),
                          if (state.reminderEnabled)
                            ListTile(
                              leading: const Icon(Icons.access_time_outlined),
                              title: const Text('Reminder time'),
                              trailing: Text(
                                state.reminderTime.format(context),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              onTap: () => _pickReminderTime(
                                context,
                                state.reminderTime,
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // ── Account section (signed-in only) ─────────────────────────
                  if (signedIn) ...[
                    _SectionHeader(
                      label: 'Account',
                      textTheme: textTheme,
                      cs: cs,
                    ),

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

                  // ── About section (always visible) ────────────────────────────
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
        ),
      ),
    );
  }
}

// ── Gemini Key Bottom Sheet ───────────────────────────────────────────────────

/// Bottom sheet that lets the user enter, save, or clear their Gemini API key.
///
/// Uses the SettingsBloc provided by the parent SettingsScreen — NOT a new
/// bloc instance — so that state survives sheet open/close cycles.
class _GeminiKeyBottomSheet extends StatefulWidget {
  const _GeminiKeyBottomSheet();

  @override
  State<_GeminiKeyBottomSheet> createState() => _GeminiKeyBottomSheetState();
}

class _GeminiKeyBottomSheetState extends State<_GeminiKeyBottomSheet> {
  final TextEditingController _keyController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<SettingsBloc, SettingsState>(
      // Close the sheet automatically when the key is successfully saved.
      // We listen for a transition to `set` status so we don't close on the
      // initial load event if the user already had a key stored.
      listenWhen: (previous, current) =>
          previous.geminiKeyStatus != GeminiKeyStatus.set &&
          current.geminiKeyStatus == GeminiKeyStatus.set &&
          !current.isSaving,
      listener: (context, state) => Navigator.pop(context),
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            // Shift content above the keyboard when it opens.
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Gemini API Key',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // Key text field — obscured by default for security.
              TextField(
                controller: _keyController,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AIza...',
                  border: const OutlineInputBorder(),
                  // Toggle visibility button.
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                    tooltip: _obscure ? 'Show key' : 'Hide key',
                  ),
                  // Inline validation error from the bloc.
                  errorText: state.errorMessage,
                ),
                onChanged: (value) =>
                    context.read<SettingsBloc>().add(GeminiKeyChanged(value)),
              ),

              const SizedBox(height: 12),

              // Action row: how-to link | spacer | Clear | Save
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GeminiKeyWalkthrough(),
                      ),
                    ),
                    child: const Text('How to get a key'),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: state.isSaving
                        ? null
                        : () {
                            _keyController.clear();
                            context.read<SettingsBloc>().add(
                              GeminiKeyCleared(),
                            );
                          },
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: state.isSaving
                        ? null
                        : () {
                            context.read<SettingsBloc>().add(GeminiKeySaved());
                          },
                    child: state.isSaving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

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
