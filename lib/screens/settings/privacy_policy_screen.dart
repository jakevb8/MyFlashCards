// privacy_policy_screen.dart
//
// Static, scrollable privacy policy screen required for Play Store compliance.
// Describes what data the app collects, where it is stored, and how users can
// request deletion.
//
// Why this screen exists: Google Play requires apps that collect user data to
// display a privacy policy accessible from within the app. This screen serves
// as that in-app policy; the Play Store listing will eventually link to a hosted
// version of the same content (see TODO below).
//
// No business logic lives here — it is purely informational UI.

// TODO(FEAT-009): Replace with hosted URL for Play Store listing

import 'package:flutter/material.dart';

/// A static, scrollable Privacy Policy screen.
///
/// Displayed from SettingsScreen. Contains sections covering data collection,
/// storage, deletion, third-party services, and a contact email.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Last updated: May 2026',
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),

          // ── What we collect ──────────────────────────────────────────────────
          Text('What We Collect', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'MyFlashCards collects only the data you explicitly create inside '
            'the app:\n\n'
            '• Flashcard content (questions and answers you type)\n'
            '• Deck names and descriptions\n'
            '• Theme preferences (color scheme, dark mode, kids mode)\n\n'
            'We do not collect your name, location, contacts, or any other '
            'personal information beyond your Google/GitHub account email and '
            'display name, which are used solely to identify your backup data.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // ── Where it is stored ───────────────────────────────────────────────
          Text('Where Your Data Is Stored', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Your data is stored in two places:\n\n'
            '• On-device (Hive): All flashcard data is stored locally on your '
            'device using Hive, a lightweight key-value database. This data '
            'never leaves your device unless you explicitly choose to back up.\n\n'
            '• Google Firebase Firestore: When you sign in and use the cloud '
            'backup feature, your decks, flashcards, and theme preferences are '
            'uploaded to Google Firebase Firestore under your unique account ID. '
            'Firebase is operated by Google LLC. See Google\'s privacy policy at '
            'https://policies.google.com/privacy.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // ── How to delete ────────────────────────────────────────────────────
          Text('How to Delete Your Data', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'You can permanently delete all your data at any time:\n\n'
            '• Go to Settings → Account → "Delete my account"\n\n'
            'This will permanently delete all your flashcards and decks from '
            'Firebase Firestore and remove your Firebase Auth account. Your '
            'local on-device data will also be cleared. This action cannot be '
            'undone.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // ── Third-party services ─────────────────────────────────────────────
          Text('Third-Party Services', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'MyFlashCards does not use any third-party analytics or advertising '
            'SDKs. The only third-party service used is Google Firebase (Auth '
            'and Firestore) for optional cloud backup. No data is sold or shared '
            'with any other third parties.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // ── AI feature ───────────────────────────────────────────────────────
          Text('AI-Assisted Card Generation', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'The optional AI generation feature sends text you provide (e.g. '
            'pasted notes) to the Google Gemini API to generate flashcard '
            'suggestions. This text is processed by Google and subject to '
            'Google\'s API terms. Do not paste sensitive or confidential '
            'information into the AI generation field.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // ── Contact ──────────────────────────────────────────────────────────
          Text('Contact', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'If you have any questions about this privacy policy or want to '
            'request data deletion manually, contact us at:\n\n'
            'jakevb8@gmail.com',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
