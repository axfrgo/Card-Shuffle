// lib/src/widgets/cursor_perspective.dart
import 'package:flutter/material.dart';
import 'perspective_wrapper.dart';

class CursorPerspective extends StatefulWidget {
  final double perspective;
  final double angle;
  final double zoom;

  const CursorPerspective({
    Key? key,
    this.perspective = 800.0,
    this.angle = 14.0,
    this.zoom = 1.0,
  }) : super(key: key);

  @override
  _CursorPerspectiveState createState() => _CursorPerspectiveState();
}

class _CursorPerspectiveState extends State<CursorPerspective> {
  Offset _pos = const Offset(-200, -200);
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    // We'll render a full-screen MouseRegion that tracks pointer movement.
    return Positioned.fill(
      child: MouseRegion(
        onHover: (event) {
          setState(() {
            _pos = event.position;
            _visible = true;
          });
        },
        onExit: (_) {
          setState(() => _visible = false);
        },
        child: IgnorePointer(
          child: Stack(
            children: [
              // The cursor visual
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                left: _pos.dx - 18,
                top: _pos.dy - 18,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: _visible ? 1.0 : 0.0,
                  child: PerspectiveWrapper(
                    perspective: widget.perspective,
                    angle: widget.angle,
                    zoom: widget.zoom,
                    pan: Offset(0, 0),
                    duration: const Duration(milliseconds: 120),
                    child: _buildCursor(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCursor() {
    // simple circular cursor with a hand icon feel
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Center(
          child: Icon(
            Icons.pan_tool,
            size: 18,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
