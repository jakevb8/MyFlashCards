// gemini_key_walkthrough.dart
//
// A 4-step onboarding walkthrough that guides the user through obtaining a
// free Gemini API key from Google AI Studio and entering it in Settings.
//
// WHY THIS EXISTS:
//   Most users have never used Google AI Studio. Without guidance they will
//   either abandon the feature or enter an invalid key. This walkthrough trades
//   a small amount of screen real-estate for dramatically improved first-time
//   success rate — a pattern well-established in OAuth login flows.
//
// NAVIGATION CONTRACT:
//   - This screen is pushed onto the Navigator stack from the Settings bottom
//     sheet via `Navigator.push(...)`.
//   - Both the Skip (AppBar action) and the Done button on the final page call
//     `Navigator.pop(context)` — no return value is expected.
//   - The screen does NOT itself save any key; that happens in SettingsBloc.
//
// KEY DEPENDENCIES:
//   - url_launcher: opens Google AI Studio in the device browser (page 2).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 4-step walkthrough teaching users how to obtain a Gemini API key.
class GeminiKeyWalkthrough extends StatefulWidget {
  const GeminiKeyWalkthrough({super.key});

  @override
  State<GeminiKeyWalkthrough> createState() => _GeminiKeyWalkthroughState();
}

class _GeminiKeyWalkthroughState extends State<GeminiKeyWalkthrough> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Final page — Done tapped.
      Navigator.pop(context);
    }
  }

  /// Opens Google AI Studio in the platform browser.
  ///
  /// Falls back gracefully if the URL cannot be launched on this device.
  Future<void> _openAiStudio() async {
    final uri = Uri.parse('https://aistudio.google.com/app/apikey');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open browser. Visit aistudio.google.com manually.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLastPage = _currentPage == _pageCount - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get a Gemini API Key'),
        actions: [
          // Skip button — always visible, pops the walkthrough immediately.
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Page content ───────────────────────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _WalkthroughPage(
                  icon: Icons.auto_awesome,
                  iconColor: cs.primary,
                  title: 'What is Gemini?',
                  body:
                      'Gemini is Google\'s AI model that can understand topics and '
                      'create high-quality flashcards tailored to any subject.\n\n'
                      'It\'s free and takes 30 seconds to set up.',
                ),
                _WalkthroughPage(
                  icon: Icons.open_in_new,
                  iconColor: cs.secondary,
                  title: 'Go to Google AI Studio',
                  body:
                      'Google AI Studio is where you create and manage your '
                      'free Gemini API key. Open it now to get started.',
                  action: FilledButton.icon(
                    onPressed: _openAiStudio,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Google AI Studio'),
                  ),
                ),
                const _WalkthroughPage(
                  icon: Icons.vpn_key_outlined,
                  title: 'Create an API Key',
                  body:
                      '1. Click "Create API key"\n\n'
                      '2. Select or create a Google Cloud project\n\n'
                      '3. Copy the key that starts with "AIza"',
                ),
                const _WalkthroughPage(
                  icon: Icons.check_circle_outline,
                  title: 'Paste it here',
                  body:
                      'Go back to Settings and paste your key into the '
                      '"Gemini API Key" field, then tap Save.',
                ),
              ],
            ),
          ),

          // ── Page indicator dots ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pageCount, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage ? cs.primary : cs.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          // ── Next / Done button ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _nextPage,
                child: Text(isLastPage ? 'Done' : 'Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single page in the walkthrough — icon, title, body text, and an optional
/// action widget (e.g. a button to open a URL).
class _WalkthroughPage extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String body;
  final Widget? action;

  const _WalkthroughPage({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: iconColor ?? cs.primary),
          const SizedBox(height: 32),
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 32), action!],
        ],
      ),
    );
  }
}
