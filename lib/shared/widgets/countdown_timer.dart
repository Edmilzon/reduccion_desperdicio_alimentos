import 'dart:async';
import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime target;
  final bool compact;

  const CountdownTimer({
    super.key,
    required this.target,
    this.compact = false,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final diff = widget.target.difference(DateTime.now());
    if (diff.isNegative) {
      _timer?.cancel();
    }
    if (mounted) {
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remaining.inMinutes <= 5;
    final isWarning = _remaining.inMinutes <= 30;

    Color textColor;
    if (isUrgent) {
      textColor = Colors.red;
    } else if (isWarning) {
      textColor = AppColors.primary;
    } else {
      textColor = AppColors.textSecondary;
    }

    if (_remaining.isNegative || _remaining == Duration.zero) {
      return Text(
        widget.compact ? 'Vencido' : 'Tiempo vencido',
        style: TextStyle(
          color: Colors.red,
          fontSize: widget.compact ? 11 : 14,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    if (widget.compact) {
      return Text(
        hours > 0
            ? '${hours}h ${minutes.toString().padLeft(2, '0')}m'
            : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      );
    }

    return Text(
      hours > 0
          ? '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s'
          : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: 2,
      ),
    );
  }
}
