import 'dart:async';
import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime target;
  final bool compact;
  final TextStyle? textStyle;

  const CountdownTimer({
    super.key,
    required this.target,
    this.compact = false,
    this.textStyle,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final diff = widget.target.difference(DateTime.now());
    if (diff.isNegative) {
      _timer?.cancel();
      if (mounted) setState(() => _remaining = Duration.zero);
    } else {
      if (mounted) setState(() => _remaining = diff);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remaining.inMinutes <= 5 && _remaining.inMinutes > 0;
    final isWarning = _remaining.inMinutes <= 30 && _remaining.inMinutes > 0;

    final color = isUrgent
        ? Colors.red
        : isWarning
            ? AppColors.primary
            : AppColors.textSecondary;

    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    final timeText = widget.compact
        ? '${hours > 0 ? '${hours}h ' : ''}${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${hours > 0 ? '${hours}h ' : ''}${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.compact)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              isUrgent ? Icons.alarm : Icons.timer_outlined,
              size: 14,
              color: color,
            ),
          ),
        Text(
          timeText,
          style: (widget.textStyle ?? const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)).copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}
