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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose Theme',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
              const SizedBox(height: 16),
              _themeGrid(context, state),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text('Brightness',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        letterSpacing: 1,
                      )),
              const SizedBox(height: 12),
              _brightnessRow(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _themeGrid(BuildContext context, ThemeState state) {
    const themes = [
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

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.6,
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
          color: selected ? color.withValues(alpha: 0.15) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: selected ? color : cs.onSurface,
                      )),
                  Text(desc,
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.outline,
                      )),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
