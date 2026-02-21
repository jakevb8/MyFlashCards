import 'package:flutter/material.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Backup')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.cloud_sync_outlined, size: 72, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'Back up your decks to Firebase',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to sync your flashcards across devices.\n'
            'Firebase Spark (free tier) is used — no cost to you.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.outline),
          ),
          const SizedBox(height: 32),
          _ActionCard(
            icon: Icons.email_outlined,
            title: 'Sign in with Email',
            subtitle: 'Use an email & password account',
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.code,
            title: 'Sign in with GitHub',
            subtitle: 'OAuth via Firebase — requires setup',
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Setup required',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: cs.outline, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            'Run `flutterfire configure` and add your google-services.json '
            '/ GoogleService-Info.plist to enable backup. See README.md for '
            'step-by-step instructions.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Firebase setup required — see README.md'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
