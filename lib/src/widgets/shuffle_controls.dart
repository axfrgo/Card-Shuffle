import 'dart:math' as math;

import 'package:flutter/material.dart';

typedef PointerMoveCallback = void Function(double rotX, double rotY);

class ShuffleControls extends StatefulWidget {
  final bool isShuffling;
  final bool isFinishedShuffling;
  final bool canFinishShuffling;
  final bool isOnMobile;
  final bool isMobileMessageActive;
  final VoidCallback? onStartShuffle;
  final VoidCallback? onFinishShuffle;
  final VoidCallback? onRandomizeDeck;
  final PointerMoveCallback? onPointerMove;
  final bool showActionButton;

  const ShuffleControls({
    Key? key,
    required this.isShuffling,
    required this.isFinishedShuffling,
    required this.canFinishShuffling,
    this.isOnMobile = false,
    this.isMobileMessageActive = false,
    this.onStartShuffle,
    this.onFinishShuffle,
    this.onRandomizeDeck,
    this.onPointerMove,
  this.showActionButton = false,
  }) : super(key: key);

  @override
  State<ShuffleControls> createState() => _ShuffleControlsState();
}

class _ShuffleControlsState extends State<ShuffleControls> with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  static const double _rotJitter = 5;
  static const double _rotX = 10;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    if (widget.isShuffling) _spinController.repeat();
  }

  @override
  void didUpdateWidget(covariant ShuffleControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShuffling && !_spinController.isAnimating) {
      _spinController.repeat();
    } else if (!widget.isShuffling && _spinController.isAnimating) {
      _spinController.stop();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  // Map pointer to rotation values similar to the React example
  void _handlePointer(PointerEvent e) {
    if (widget.onPointerMove == null) return;
    final x = e.position.dx;
    final y = e.position.dy;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    // map y [0..h] -> [0..-ROT_X]
    final rotX = _map(y, 0, h, 0, -_rotX);
    // map x [0..w] -> [-_rotJITTER.._rotJITTER]
    final rotY = _map(x, 0, w, -_rotJitter, _rotJitter);
    widget.onPointerMove?.call(rotX, rotY);
  }

  double _map(double v, double a, double b, double c, double d) {
    if (b - a == 0) return c;
    final t = (v - a) / (b - a);
    return c + (d - c) * t.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowDone = widget.isShuffling || widget.isFinishedShuffling;

    return Listener(
      onPointerHover: _handlePointer,
      onPointerMove: _handlePointer,
      child: Stack(
        children: [
          // Center tappable area that toggles shuffle/done
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (!widget.isShuffling && !widget.isFinishedShuffling) {
                  widget.onStartShuffle?.call();
                  widget.onRandomizeDeck?.call();
                } else if (widget.isShuffling && widget.canFinishShuffling) {
                  widget.onFinishShuffle?.call();
                }
              },
              child: Container(
                color: Colors.transparent,
                // padding to avoid covering other controls entirely
              ),
            ),
          ),

          // Animated spinning wrapper for visual affordance
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _spinController,
              builder: (context, child) {
                final angle = _spinController.value * 2 * math.pi;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(_rotX * (math.pi / 180))
                    ..rotateY(angle),
                  child: child,
                );
              },
              child: const SizedBox.shrink(),
            ),
          ),

          // Actions area (bottom-center) - optional; hidden when showActionButton == false
          if (widget.showActionButton)
            Positioned(
              left: 0,
              right: 0,
              bottom: widget.isOnMobile ? 80 : 30,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: shouldShowDone && widget.canFinishShuffling ? 1.0 : 1.0,
                  child: Visibility(
                    visible: shouldShowDone ? (widget.canFinishShuffling) : true,
                    child: ElevatedButton(
                      onPressed: () {
                        if (shouldShowDone) {
                          if (widget.canFinishShuffling) widget.onFinishShuffle?.call();
                        } else {
                          widget.onStartShuffle?.call();
                          widget.onRandomizeDeck?.call();
                        }
                      },
                      child: Text(shouldShowDone ? 'Done shuffling' : 'Ready to shuffle'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
