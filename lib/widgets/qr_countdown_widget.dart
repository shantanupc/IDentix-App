import 'dart:async';
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QRCountdownWidget extends StatefulWidget {
  final int seconds;
  final VoidCallback onComplete;
  final int generation;

  const QRCountdownWidget({
    Key? key,
    required this.seconds,
    required this.onComplete,
    required this.generation,
  }) : super(key: key);

  @override
  State<QRCountdownWidget> createState() => _QRCountdownWidgetState();
}

class _QRCountdownWidgetState extends State<QRCountdownWidget>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  late AnimationController _animationController;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _startTimer();
  }

  @override
  void didUpdateWidget(QRCountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.generation != oldWidget.generation) {
      _resetTimer();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remaining = widget.seconds;
      _isGenerating = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining > 0) {
        setState(() {
          _remaining--;
        });
      } else {
        timer.cancel();
        _showGeneratingAnimation();
      }
    });
  }

  void _showGeneratingAnimation() {
    setState(() {
      _isGenerating = true;
    });
    _animationController.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Color get _timerColor {
    if (_remaining > 20) {
      return AppTheme.success;
    } else if (_remaining > 10) {
      return AppTheme.warning;
    } else {
      return AppTheme.error;
    }
  }

  double get _progress {
    return _remaining / widget.seconds;
  }

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) {
      return _buildGeneratingView();
    }

    return Column(
      children: [
        // Circular Countdown
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              // Progress Arc
              CustomPaint(
                size: const Size(120, 120),
                painter: _CircularProgressPainter(
                  progress: _progress,
                  color: _timerColor,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  strokeWidth: 8,
                ),
              ),
              // Timer Text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_remaining',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: _timerColor,
                    ),
                  ),
                  Text(
                    'sec',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        // Status Text
        Text(
          'QR Code refreshes in $_remaining seconds',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratingView() {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating outer ring
              RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0).animate(_animationController),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryLight.withOpacity(0.3),
                      width: 4,
                    ),
                  ),
                ),
              ),
              // Inner rotating ring
              RotationTransition(
                turns: Tween(begin: 1.0, end: 0.0).animate(_animationController),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryLight.withOpacity(0.5),
                      width: 4,
                    ),
                  ),
                ),
              ),
              // Center icon
              Icon(
                Icons.refresh,
                size: 40,
                color: AppTheme.primaryLight,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          'Generating secure code...',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
