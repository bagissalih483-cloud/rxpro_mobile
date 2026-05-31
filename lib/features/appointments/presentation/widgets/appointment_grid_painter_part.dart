part of 'appointment_dashboard_views.dart';

class AppointmentGridPainter extends CustomPainter {
  const AppointmentGridPainter({
    required this.staffCount,
    required this.slotCount,
    required this.timeWidth,
    required this.cellWidth,
    required this.headerHeight,
    required this.rowHeight,
    required this.lineWidth,
  });

  final int staffCount;
  final int slotCount;
  final double timeWidth;
  final double cellWidth;
  final double headerHeight;
  final double rowHeight;
  final double lineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.white;
    final timeBgPaint = Paint()..color = const Color(0xFFF1F5F9);
    final headerBgPaint = Paint()..color = Colors.white;
    final linePaint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Offset.zero & size, bgPaint);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, headerHeight),
      headerBgPaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(0, headerHeight, timeWidth, size.height - headerHeight),
      timeBgPaint,
    );

    // Dış çerçeve
    canvas.drawRect(
      Rect.fromLTWH(
        lineWidth / 2,
        lineWidth / 2,
        size.width - lineWidth,
        size.height - lineWidth,
      ),
      linePaint,
    );

    // Header alt çizgisi
    canvas.drawLine(
      Offset(0, headerHeight),
      Offset(size.width, headerHeight),
      linePaint,
    );

    // Yatay saat çizgileri, tüm genişlik boyunca tek parça
    for (var i = 0; i <= slotCount; i++) {
      final y = headerHeight + (i * rowHeight);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Saat sütunu ayrımı
    canvas.drawLine(
      Offset(timeWidth, 0),
      Offset(timeWidth, size.height),
      linePaint,
    );

    // Personel kolon çizgileri
    for (var i = 1; i <= staffCount; i++) {
      final x = timeWidth + (i * cellWidth);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AppointmentGridPainter oldDelegate) {
    return oldDelegate.staffCount != staffCount ||
        oldDelegate.slotCount != slotCount ||
        oldDelegate.timeWidth != timeWidth ||
        oldDelegate.cellWidth != cellWidth ||
        oldDelegate.headerHeight != headerHeight ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.lineWidth != lineWidth;
  }
}

// ignore: unused_element
