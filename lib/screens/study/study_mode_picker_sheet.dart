// StudyModePickerSheet — bottom sheet shown before a study session starts.
//
// Lets the user choose between the three study modes:
//   flashcard: tap to flip, then rate (classic)
//   multipleChoice: pick the correct answer from 4 options
//   typeAnswer: type the answer from memory
//
// Returns the selected [StudyModeSelection] to the caller via Navigator.pop.
// Does not push to StudyScreen itself — the caller drives navigation so that
// BlocProviders above in the tree remain available inside StudyScreen.

import 'package:flutter/material.dart';
import '../../models/study_mode.dart';

/// Carries the user's choices back to the caller.
class StudyModeSelection {
  final StudyMode mode;
  final bool randomize;
  final bool flipped;
  final bool tolerantMatching;

  const StudyModeSelection({
    required this.mode,
    this.randomize = false,
    this.flipped = false,
    this.tolerantMatching = false,
  });
}

class StudyModePickerSheet extends StatefulWidget {
  const StudyModePickerSheet({super.key});

  /// Shows the sheet and returns the selection, or null if dismissed.
  static Future<StudyModeSelection?> show(BuildContext context) {
    return showModalBottomSheet<StudyModeSelection>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const StudyModePickerSheet(),
    );
  }

  @override
  State<StudyModePickerSheet> createState() => _StudyModePickerSheetState();
}

class _StudyModePickerSheetState extends State<StudyModePickerSheet> {
  StudyMode _mode = StudyMode.flashcard;
  bool _randomize = false;
  bool _flipped = false;
  bool _tolerant = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose Study Mode',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _ModeTile(
              icon: Icons.style_outlined,
              title: 'Flashcard Flip',
              subtitle: 'Tap to reveal the answer, then rate yourself',
              selected: _mode == StudyMode.flashcard,
              onTap: () => setState(() => _mode = StudyMode.flashcard),
            ),
            const SizedBox(height: 8),
            _ModeTile(
              icon: Icons.checklist_outlined,
              title: 'Multiple Choice',
              subtitle: 'Pick the correct answer from 4 options',
              selected: _mode == StudyMode.multipleChoice,
              onTap: () => setState(() => _mode = StudyMode.multipleChoice),
            ),
            const SizedBox(height: 8),
            _ModeTile(
              icon: Icons.keyboard_outlined,
              title: 'Type the Answer',
              subtitle: 'Type the answer from memory',
              selected: _mode == StudyMode.typeAnswer,
              onTap: () => setState(() => _mode = StudyMode.typeAnswer),
            ),

            // Tolerance toggle — only relevant for typeAnswer
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _mode == StudyMode.typeAnswer
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SwitchListTile.adaptive(
                        value: _tolerant,
                        onChanged: (v) => setState(() => _tolerant = v),
                        title: const Text('Close-enough matching'),
                        subtitle: const Text(
                          'Accepts minor typos (up to 2 character edits)',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Session options row
            Row(
              children: [
                _OptionChip(
                  icon: Icons.shuffle,
                  label: 'Shuffle',
                  selected: _randomize,
                  onTap: () => setState(() => _randomize = !_randomize),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  icon: Icons.flip_camera_android_outlined,
                  label: 'Flip deck',
                  selected: _flipped,
                  onTap: () => setState(() => _flipped = !_flipped),
                ),
              ],
            ),
            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: () => Navigator.pop(
                context,
                StudyModeSelection(
                  mode: _mode,
                  randomize: _randomize,
                  flipped: _flipped,
                  tolerantMatching: _tolerant,
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Session'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? cs.primary : cs.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.onPrimaryContainer : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected
                          ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: cs.primary, size: 20)
            else
              Icon(Icons.circle_outlined, color: cs.outlineVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
    );
  }
}
