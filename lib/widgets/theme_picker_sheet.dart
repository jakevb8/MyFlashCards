import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../blocs/theme/theme_event.dart';
import '../../blocs/theme/theme_state.dart';
import '../../core/theme/app_theme.dart';

class ThemePickerSheet extends StatelessWidget {
  const ThemePickerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ThemeBloc>(),
        child: const ThemePickerSheet(),
      ),
    );
  }

  // ── Adult themes ──────────────────────────────────────────────────────────
  static const _adultThemes = [
    (
      type: AppThemeType.classic,
      label: 'Classic',
      desc: 'Indigo & Violet',
      icon: Icons.auto_awesome,
      color: Color(0xFF4F46E5),
    ),
    (
      type: AppThemeType.oceanBlue,
      label: 'Ocean Blue',
      desc: 'Bold & Energetic',
      icon: Icons.waves,
      color: Color(0xFF0369A1),
    ),
    (
      type: AppThemeType.roseGarden,
      label: 'Rose Garden',
      desc: 'Elegant & Warm',
      icon: Icons.local_florist,
      color: Color(0xFFBE185D),
    ),
    (
      type: AppThemeType.executive,
      label: 'Executive',
      desc: 'Clean & Professional',
      icon: Icons.business_center,
      color: Color(0xFF0F766E),
    ),
  ];

  // ── Kids themes ───────────────────────────────────────────────────────────
  static const _kidsThemes = [
    (
      type: AppThemeType.sunshine,
      label: 'Sunshine',
      desc: 'Sunny & Cheerful',
      icon: Icons.wb_sunny,
      color: Color(0xFFD97706),
    ),
    (
      type: AppThemeType.jungle,
      label: 'Jungle',
      desc: 'Fresh & Adventurous',
      icon: Icons.park,
      color: Color(0xFF16A34A),
    ),
    (
      type: AppThemeType.bubblegum,
      label: 'Bubblegum',
      desc: 'Sweet & Bubbly',
      icon: Icons.bubble_chart,
      color: Color(0xFFDB2777),
    ),
    (
      type: AppThemeType.superHero,
      label: 'Super Hero',
      desc: 'Bold & Powerful',
      icon: Icons.bolt,
      color: Color(0xFFEA580C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final themes = state.isKidsMode ? _kidsThemes : _adultThemes;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Kids / Adult toggle ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose Theme',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Text('👶', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Switch(
                    value: state.isKidsMode,
                    onChanged: (_) =>
                        context.read<ThemeBloc>().add(ToggleKidsMode()),
                    thumbIcon: WidgetStateProperty.resolveWith((states) {
                      return Icon(
                        state.isKidsMode
                            ? Icons.child_care
                            : Icons.person_outline,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.isKidsMode ? 'Kids' : 'Adult',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Theme grid ───────────────────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.3,
                children: [
                  for (final t in themes)
                    _ThemeCard(
                      label: t.label,
                      desc: t.desc,
                      icon: t.icon,
                      color: t.color,
                      selected: state.themeType == t.type,
                      onTap: () =>
                          context.read<ThemeBloc>().add(ChangeThemeType(t.type)),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Brightness',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              _brightnessRow(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _brightnessRow(BuildContext context, ThemeState state) {
    final options = [
      (mode: ThemeMode.system, label: 'System', icon: Icons.brightness_auto),
      (mode: ThemeMode.light, label: 'Light', icon: Icons.light_mode),
      (mode: ThemeMode.dark, label: 'Dark', icon: Icons.dark_mode),
    ];
    return SegmentedButton<ThemeMode>(
      segments: [
        for (final o in options)
          ButtonSegment(
            value: o.mode,
            label: Text(o.label),
            icon: Icon(o.icon),
          ),
      ],
      selected: {state.themeMode},
      onSelectionChanged: (s) =>
          context.read<ThemeBloc>().add(SetBrightness(s.first)),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.desc,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: selected ? color : cs.onSurface,
                    ),
                  ),
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: cs.outline),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
