import 'package:flutter/material.dart';

class DrawArea extends StatefulWidget {
  const DrawArea({super.key});

  @override
  State<DrawArea> createState() => _DrawAreaState();
}

class _DrawAreaState extends State<DrawArea> {
  final List<Offset?> points = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.grey[100],
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            points.add(details.localPosition);
          });
        },
        onPanUpdate: (details) {
          setState(() {
            points.add(details.localPosition);
          });
        },
        onPanEnd: (_) {
          points.add(null);
        },
        child: CustomPaint(
          painter: FingerPainter(points),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class FingerPainter extends CustomPainter {
  final List<Offset?> points;

  FingerPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(FingerPainter oldDelegate) => true;
}
