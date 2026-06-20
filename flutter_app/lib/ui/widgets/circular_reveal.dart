import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Circle clipper replicating Android's ViewAnimationUtils.createCircularReveal:
/// the clip is a circle around [center] whose radius is
/// `fraction x hypot(width, height)` - the original's end radius.
class CircularRevealClipper extends CustomClipper<Path> {
  const CircularRevealClipper({required this.fraction, this.center});

  /// 0 = fully hidden, 1 = circle of radius hypot(w, h) (covers everything).
  final double fraction;

  /// Reveal center in local coordinates; defaults to the widget center.
  final Offset? center;

  @override
  Path getClip(Size size) {
    final revealCenter = center ?? size.center(Offset.zero);
    final radius =
        fraction *
        math.sqrt(size.width * size.width + size.height * size.height);
    return Path()
      ..addOval(Rect.fromCircle(center: revealCenter, radius: radius));
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) =>
      oldClipper.fraction != fraction || oldClipper.center != center;
}
