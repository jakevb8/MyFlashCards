import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/analytics/analytics_bloc.dart';
import '../../blocs/analytics/analytics_event.dart';
import '../../blocs/analytics/analytics_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<AnalyticsBloc>().add(const LoadAnalytics()),
          ),
        ],
      ),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading || state is AnalyticsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AnalyticsError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is AnalyticsLoaded) {
            return _AnalyticsBody(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final AnalyticsLoaded state;
  const _AnalyticsBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // --- Streak card ---
        _SectionCard(
          child: Row(
            children: [
              Icon(Icons.local_fire_department, color: cs.primary, size: 48),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.streak}',
                    style: tt.displayMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    state.streak == 1 ? 'day streak' : 'day streak',
                    style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- 7-day bar chart ---
        Text('Last 7 Days', style: tt.titleMedium),
        const SizedBox(height: 12),
        _SectionCard(child: _WeeklyBarChart(days: state.last7Days)),
        const SizedBox(height: 20),

        // --- Accuracy + total cards ---
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.check_circle_outline,
                label: 'Accuracy',
                value: state.accuracy != null
                    ? '${(state.accuracy! * 100).round()}%'
                    : '—',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.style_outlined,
                label: 'Cards Reviewed',
                value: '${state.totalCardsReviewed}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Card-shaped container used for each analytics section.
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// Inline stat tile — icon, big value, small label.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Custom 7-day bar chart using only Flutter built-in widgets.
/// Each bar is a Container whose height is proportional to the day with the
/// most cards reviewed. A minimum stub height (4 px) is shown even for 0 so
/// the bar is always visible.
class _WeeklyBarChart extends StatelessWidget {
  final List<DailyCount> days;
  const _WeeklyBarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final maxCount = days.map((d) => d.count).fold(0, max);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++) ...[
            Expanded(
              child: _Bar(
                day: days[i],
                maxCount: maxCount,
                barColor: cs.primary,
                labelStyle:
                    tt.labelSmall?.copyWith(color: cs.onSurfaceVariant) ??
                    const TextStyle(fontSize: 10),
              ),
            ),
            if (i < days.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

/// Returns a 2-letter weekday abbreviation without requiring the intl package.
/// [weekday] is DateTime.weekday (1=Mon … 7=Sun).
String _shortWeekday(int weekday) {
  const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  return labels[(weekday - 1) % 7];
}

class _Bar extends StatelessWidget {
  final DailyCount day;
  final int maxCount;
  final Color barColor;
  final TextStyle labelStyle;

  const _Bar({
    required this.day,
    required this.maxCount,
    required this.barColor,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    const maxBarHeight = 80.0;
    const minBarHeight = 4.0;
    final ratio = maxCount > 0 ? day.count / maxCount : 0.0;
    final barHeight = max(minBarHeight, ratio * maxBarHeight);

    final dayLabel = _shortWeekday(day.date.weekday);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Count label above bar — only shown when count > 0
        if (day.count > 0)
          Text('${day.count}', style: labelStyle)
        else
          const SizedBox(height: 14),
        const SizedBox(height: 2),
        Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: day.count > 0 ? barColor : barColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(dayLabel, style: labelStyle),
      ],
    );
  }
}
