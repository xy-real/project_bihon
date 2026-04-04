import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:project_bihon/shared/shared.dart';

class PreparednessScoreCard extends StatelessWidget {
  final int score;
  final VoidCallback? onImprove;

  const PreparednessScoreCard({super.key, this.score = 72, this.onImprove});

  @override
  Widget build(BuildContext context) {
    final normalizedScore = score.clamp(0, 100).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BihonTheme.bihonOrange,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Your Preparedness Score',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _PreparednessArcPainter(
                    progress: normalizedScore / 100,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      normalizedScore.round().toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const Text(
                      '/100',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "You're almost there! Update your go-bag to improve.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 16),
          AppButton(
            variant: AppButtonVariant.secondary,
            onPressed: onImprove,
            child: const Text(
              'Improve Score',
              style: TextStyle(
                color: Color(0xFF7C2D12),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreparednessArcPainter extends CustomPainter {
  final double progress;

  const _PreparednessArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final rect = Offset.zero & size;

    final backgroundPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final foregroundPaint = Paint()
      ..color = BihonTheme.bihonYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, backgroundPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PreparednessArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
