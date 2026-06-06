import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/models/oferta_model.dart';

class WeeklyBarChart extends StatelessWidget {
  final List<OfertaModel> ofertas;

  const WeeklyBarChart({super.key, required this.ofertas});

  @override
  Widget build(BuildContext context) {
    final dailyCounts = _computeDailyCounts();
    final maxY = dailyCounts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxChartY = maxY < 5 ? 5.0 : (maxY + 2).toDouble();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxChartY,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = _dayLabels[group.x];
                return BarTooltipItem(
                  '$day\n${rod.toY.toInt()} oferta${rod.toY.toInt() == 1 ? '' : 's'}',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _dayLabels.length) return const SizedBox.shrink();
                  final short = _dayLabels[idx].substring(0, 3);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      short,
                      style: TextStyle(fontSize: 11, color: _isToday(idx) ? AppColors.primary : AppColors.textSecondary, fontWeight: _isToday(idx) ? FontWeight.bold : FontWeight.normal),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxChartY > 10 ? 5 : 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            final count = dailyCounts[i] ?? 0;
            final isTodayIdx = _isToday(i);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  color: isTodayIdx ? AppColors.primary : AppColors.primary.withValues(alpha: 0.45),
                  width: isTodayIdx ? 22 : 18,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  List<String> get _dayLabels {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
      return '${days[d.weekday - 1]} ${d.day}/${d.month}';
    });
  }

  bool _isToday(int index) {
    final now = DateTime.now();
    final d = now.subtract(Duration(days: 6 - index));
    return d.day == now.day && d.month == now.month && d.year == now.year;
  }

  Map<int, int> _computeDailyCounts() {
    final now = DateTime.now();
    final counts = <int, int>{};
    for (int i = 0; i < 7; i++) { counts[i] = 0; }

    for (final o in ofertas) {
      final created = (o.createdAt ?? o.pickupStart).toLocal();
      for (int i = 0; i < 7; i++) {
        final dayStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
        if (created.day == dayStart.day && created.month == dayStart.month && created.year == dayStart.year) {
          counts[i] = (counts[i] ?? 0) + 1;
          break;
        }
      }
    }
    return counts;
  }
}

class CategoryBar extends StatelessWidget {
  final String name;
  final int count;
  final int total;
  final Color color;

  const CategoryBar({
    super.key,
    required this.name,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              Text('$count', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
