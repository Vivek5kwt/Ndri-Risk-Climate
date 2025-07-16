import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:math' as math;

pw.Widget socioClimaticGaugePDF({
  required double score,
  required String dateText,
  String label = 'Socio-climatic Risk Status',
}) {
  final double width = 340;
  final double height = 180;
  final double centerX = width / 2;
  final double centerY = height * 1.02;
  final double radius = width * 0.45;

  final double startAngle = math.pi;
  final double endAngle = 0;
  final double pointerAngle = startAngle + (endAngle - startAngle) * score;

  PdfColor colorForScore(double v) {
    if (v < 0.2) return PdfColors.green;
    if (v < 0.4) return PdfColors.lightGreen;
    if (v < 0.6) return PdfColors.yellow;
    if (v < 0.8) return PdfColors.orange;
    return PdfColors.red;
  }

  return pw.Container(
    width: width,
    height: height + 34,
    child: pw.Stack(
      alignment: pw.Alignment.center,
      children: [
        pw.Positioned.fill(
          child: pw.CustomPaint(
            size: PdfPoint(width, height),
            painter: (PdfGraphics canvas, PdfPoint size) {
              final n = 80;
              for (int i = 0; i < n; i++) {
                final frac = i / n;
                final angle = startAngle + (endAngle - startAngle) * frac;
                final color = colorForScore(frac);
                final paint = PdfColor.fromInt(color.toInt()); // just for clarity, color is PdfColor already!

                final x0 = centerX + radius * math.cos(angle);
                final y0 = centerY + radius * math.sin(angle);
                final x1 = centerX + radius * math.cos(angle + 0.04);
                final y1 = centerY + radius * math.sin(angle + 0.04);

                canvas
                  ..setStrokeColor(paint)
                  ..setLineWidth(15)
                  ..drawLine(x0, y0, x1, y1)
                  ..strokePath();
              }

              // Draw ticks at 0 and 1
              for (double f in [0.0, 1.0]) {
                final angle = startAngle + (endAngle - startAngle) * f;
                final x0 = centerX + (radius - 10) * math.cos(angle);
                final y0 = centerY + (radius - 10) * math.sin(angle);
                final x1 = centerX + (radius + 14) * math.cos(angle);
                final y1 = centerY + (radius + 14) * math.sin(angle);
                canvas
                  ..setStrokeColor(PdfColors.black)
                  ..setLineWidth(2)
                  ..drawLine(x0, y0, x1, y1)
                  ..strokePath();
              }
            },
          ),

        ),
        // Pointer (white circle)
        pw.Positioned(
          left: centerX + radius * math.cos(pointerAngle) - 17,
          top: centerY + radius * math.sin(pointerAngle) - 17,
          child: pw.Container(
            width: 34,
            height: 34,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: PdfColors.black, width: 3),
            ),
          ),
        ),
        // Date
        pw.Positioned(
          top: height * 0.38,
          left: 0,
          right: 0,
          child: pw.Center(
            child: pw.Text(
              dateText,
              style: pw.TextStyle(fontSize: 23, fontWeight: pw.FontWeight.normal),
            ),
          ),
        ),
        // Score number (big)
        pw.Positioned(
          top: height * 0.26,
          left: 0,
          right: 0,
          child: pw.Center(
            child: pw.Text(
              score.toStringAsFixed(2),
              style: pw.TextStyle(
                fontSize: 41,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
          ),
        ),
        // "Socio-climatic Risk Status" bar at bottom
        pw.Positioned(
          bottom: 0,
          left: 40,
          right: 40,
          child: pw.Container(
            height: 36,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#099ca3'),
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 23,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.yellow,
              ),
            ),
          ),
        ),
        // 0 and 1 labels
        pw.Positioned(
          left: 18,
          top: height * 0.67,
          child: pw.Text(
            '0',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Positioned(
          right: 18,
          top: height * 0.67,
          child: pw.Text(
            '1',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

