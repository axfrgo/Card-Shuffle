// lib/src/widgets/perspective_wrapper.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A small helper that applies a perspective transform, optional pan and zoom,
/// and an X-angle rotation to its child. Similar in purpose to the React
/// `Perspective` wrapper in the example.
class PerspectiveWrapper extends StatelessWidget {
  final double perspective; // in pixels (larger = shallower perspective)
  final double angle; // rotateX in degrees
  final double zoom; // uniform scale
  final Offset pan; // translate in px
  final Duration duration;
  final Widget child;

  const PerspectiveWrapper({
    Key? key,
    required this.perspective,
    required this.angle,
    this.zoom = 1.0,
    this.pan = Offset.zero,
    this.duration = const Duration(milliseconds: 240),
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final m = Matrix4.identity();
    // set perspective (avoid div by zero)
    final p = perspective <= 0 ? 1000.0 : perspective;
    m.setEntry(3, 2, 1.0 / p);

    // apply pan/zoom and rotateX
    m.translate(pan.dx, pan.dy);
    m.scale(zoom, zoom, 1.0);
    m.rotateX(angle * math.pi / 180.0);

    return AnimatedContainer(
      duration: duration,
      // preserve size and let the child layout itself
      child: Transform(
        transform: m,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
