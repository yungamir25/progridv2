import 'dart:math';
import 'package:flutter/material.dart';

// You will also need to define your TowerStatus enum and helper function
// Add this to the top of this file or a separate file
enum TowerStatus {
  surveyed,
  inProgress,
  unsurveyed,
  unknown,
}

TowerStatus getTowerStatusFromString(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
    case 'surveyed':
      return TowerStatus.surveyed;
    case 'in progress':
      return TowerStatus.inProgress;
    case 'unsurveyed':
      return TowerStatus.unsurveyed;
    default:
      return TowerStatus.unknown;
  }
}

class PieChartPainter extends CustomPainter {
  final Map<TowerStatus, double> percentages;
  final double strokeWidth;

  PieChartPainter(this.percentages, {this.strokeWidth = 0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..style = PaintingStyle.fill;
    double startAngle = -pi / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    percentages.forEach((status, percentage) {
      if (percentage > 0) {
        paint.color = _getColorForStatus(status);
        final sweepAngle = 2 * pi * percentage;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          true,
          paint,
        );
        startAngle += sweepAngle;
      }
    });

    if (strokeWidth > 0) {
      paint
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PieChartPainter) {
      return oldDelegate.percentages != percentages;
    }
    return true;
  }

  Color _getColorForStatus(TowerStatus status) {
    switch (status) {
      case TowerStatus.unsurveyed:
        return Colors.red.shade700;
      case TowerStatus.inProgress:
        return Colors.orange.shade700;
      case TowerStatus.surveyed:
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }
}