import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const double _frontPageIdleAngle = math.pi / 30;
const double _backPageIdleAngle = -math.pi / 25;

class TwodosIcon extends StatefulWidget {
  const TwodosIcon({
    required this.progress,
    required this.angle,
    super.key,
  });

  /// Determines the check progress.
  ///
  /// The value has to be in range [0, 1].
  final ValueListenable<double> progress;

  /// Determines the pages' rotation angle.
  ///
  /// The value has to be in the range [0, n], where n is a positive number.
  /// The value will be used to scale the pages' idle angles via multiplication.
  /// A higher value will result in a larger angle, while a lower value will
  /// result in a smaller angle.
  final ValueListenable<double> angle;

  @override
  State<TwodosIcon> createState() => _TwodosIconState();
}

class _TwodosIconState extends State<TwodosIcon> {
  final _pagePainter = _PagePainter();

  @override
  void dispose() {
    _pagePainter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 112, maxWidth: 112),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              ValueListenableBuilder(
                valueListenable: widget.angle,
                builder: (context, angle, child) {
                  return Transform.rotate(
                    angle: _backPageIdleAngle * angle,
                    alignment: const Alignment(0.5, 0.2),
                    child: child,
                  );
                },
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.white.withValues(alpha: 0.5),
                    BlendMode.srcOver,
                  ),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _pagePainter,
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: widget.angle,
                builder: (context, angle, child) {
                  return Transform.rotate(
                    angle: _frontPageIdleAngle * angle,
                    alignment: const Alignment(0.5, 1),
                    child: child,
                  );
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _pagePainter,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: widget.angle,
                builder: (context, angle, child) {
                  return Transform.rotate(
                    angle: _frontPageIdleAngle * angle,
                    alignment: const Alignment(0.5, 1),
                    child: child,
                  );
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _CheckPainter(progress: widget.progress),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PagePainter extends CustomPainter {
  /// Rect for which [_picture] was recorded.
  Rect? _cachedRect;

  /// Recorded picture of the page.
  Picture? _picture;

  void dispose() {
    _picture?.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Check if we need to construct _picture.
    // The construction may happen in 2 cases:
    // 1) _picture == null || _cachedRect == null (first paint);
    // 2) _cachedRect != rect (size has changed).
    if (_picture == null || rect != _cachedRect) {
      _picture?.dispose();
      _cachedRect = rect;

      // Creating the recorder and canvas to record on.
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Drawing shadows.
      const shadows = <BoxShadow>[
        BoxShadow(
          color: Color(0x40E49907),
          blurRadius: 2,
          offset: Offset(2.5, 2),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Color(0x40E49907),
          blurRadius: 2,
          offset: Offset(-2.5, 2),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Color(0x7FB45D03),
          blurRadius: 4,
          offset: Offset(0, 3),
          spreadRadius: -2,
        ),
      ];

      final backgroundRRect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(24),
      );

      for (final shadow in shadows) {
        final paint = shadow.toPaint();
        final rrect = backgroundRRect
            .shift(shadow.offset)
            .inflate(shadow.spreadRadius);
        canvas.drawRRect(rrect, paint);
      }

      // Applying clipping of the lines' parts overflowing the page shape.
      canvas.clipRRect(backgroundRRect);

      // Drawing the page background.
      const backgroundGradient = LinearGradient(
        colors: [
          Color(0xFFFEF9EE),
          Color(0xFFFEF5E3),
          Color(0xFFFDF1D6),
        ],
        stops: [0, 0.5, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
      final backgroundPaint = Paint()
        ..shader = backgroundGradient.createShader(rect);

      canvas.drawRRect(backgroundRRect, backgroundPaint);

      // Drawing the border.
      const borderWidth = 0.5;
      const borderGradient = LinearGradient(
        colors: [
          Color(0xFFFCF7EF),
          Color(0xFFF6EBE1),
          Color(0xFFDCCEBC),
          Color(0xFFDCCEBA),
          Color(0xFFE0C1A0),
          Color(0xFFD5B58E),
        ],
        stops: [0, 0.1, 0.35, 0.5, 0.8, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
      final borderPaint = Paint()
        ..shader = borderGradient.createShader(rect)
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(
        backgroundRRect.deflate(borderWidth / 2),
        borderPaint,
      );

      // Drawing red vertical line.
      const lineWidth = 0.75;
      const spaceBetween = 16.55;
      const totalHeight = spaceBetween * 5 + lineWidth * 6;
      final topPadding = (rect.height - totalHeight) / 2;

      var dy = topPadding + lineWidth / 2;
      for (var i = 0; i < 6; i++) {
        canvas.drawLine(
          Offset(rect.left, dy),
          Offset(rect.right, dy),
          Paint()
            ..color = const Color(0xFF154EE1).withValues(alpha: 0.2)
            ..strokeWidth = lineWidth,
        );
        dy += spaceBetween + lineWidth;
      }

      // Drawing blue horizontal lines.
      const dx = 12 + lineWidth / 2;
      canvas.drawLine(
        Offset(dx, rect.top),
        Offset(dx, rect.bottom),
        Paint()
          ..color = const Color(0xFFCA3100).withValues(alpha: 0.2)
          ..strokeWidth = lineWidth,
      );

      _picture = recorder.endRecording();
    }

    assert(_picture != null, 'On this step picture have to be initialized');

    // Drawing the cached picture.
    canvas.drawPicture(_picture!);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress}) : super(repaint: progress);

  final ValueListenable<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Drawing the border.
    const radius = 20.0;
    const checkBorderWidth = 7.0;

    final checkBorderRRect = RRect.fromRectAndRadius(
      rect.deflate(20 + checkBorderWidth / 2),
      const Radius.circular(radius),
    );
    final checkBorderPaint = Paint()
      ..color = const Color(0x33E5A901)
      ..style = PaintingStyle.stroke
      ..strokeWidth = checkBorderWidth;
    canvas.drawRRect(checkBorderRRect, checkBorderPaint);

    // Drawing the check.
    final checkRect = Rect.fromCenter(
      center: rect.center,
      width: 36,
      height: 36,
    );
    final checkPath = Path()
      ..moveTo(checkRect.left + 4.95, checkRect.top + 22.9)
      ..lineTo(checkRect.left + 15.97, checkRect.top + 32)
      ..lineTo(checkRect.left + 31.02, checkRect.top + 7.54);

    canvas.drawPath(
      checkPath,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeMiterLimit = 30,
    );

    // Skip further drawings if progress equals 0.
    if (progress.value == 0) {
      return;
    }

    final progressPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = checkBorderWidth
      ..strokeCap = StrokeCap.round;

    // If progress equals 1, then drawing solid RRect to improve performance.
    if (progress.value == 1) {
      canvas.drawRRect(checkBorderRRect, progressPaint);
      return;
    }

    // Drawing the progress border.
    final progressPath = Path()
      ..moveTo(
        checkBorderRRect.right - checkBorderRRect.width / 2,
        checkBorderRRect.top,
      )
      ..lineTo(checkBorderRRect.right - radius, checkBorderRRect.top)
      ..arcToPoint(
        Offset(checkBorderRRect.right, checkBorderRRect.top + radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(checkBorderRRect.right, checkBorderRRect.bottom - radius)
      ..arcToPoint(
        Offset(checkBorderRRect.right - radius, checkBorderRRect.bottom),
        radius: const Radius.circular(radius),
      )
      ..lineTo(checkBorderRRect.left + radius, checkBorderRRect.bottom)
      ..arcToPoint(
        Offset(checkBorderRRect.left, checkBorderRRect.bottom - radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(checkBorderRRect.left, checkBorderRRect.top + radius)
      ..arcToPoint(
        Offset(checkBorderRRect.left + radius, checkBorderRRect.top),
        radius: const Radius.circular(radius),
      )
      ..close();

    final metric = progressPath.computeMetrics().first;

    canvas.drawPath(
      metric.extractPath(0, metric.length * progress.value),
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
