import 'package:flutter/material.dart';

class SpreadEditor extends StatefulWidget {
  final List<Widget> cards;
  final bool freePlacement; // toggle between structured spreads and free placement

  const SpreadEditor({
    super.key,
    required this.cards,
    this.freePlacement = true,
  });

  @override
  State<SpreadEditor> createState() => _SpreadEditorState();
}

class _SpreadEditorState extends State<SpreadEditor> {
  final Map<int, Offset> _cardPositions = {};
  final Map<int, bool> _isDragging = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.cards.length; i++) {
      _cardPositions[i] = const Offset(0, 0);
      _isDragging[i] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (_) => FocusScope.of(context).unfocus(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < widget.cards.length; i++)
                Positioned(
                  left: (widget.freePlacement
                          ? _cardPositions[i]!.dx
                          : (constraints.maxWidth / 2 - 40)) +
                      constraints.maxWidth / 2,
                  top: (widget.freePlacement
                          ? _cardPositions[i]!.dy
                          : (constraints.maxHeight / 2 - 60)) +
                      constraints.maxHeight / 2,
                  child: Draggable<int>(
                    data: i,
                    feedback: SizedBox(
                      width: 80,
                      height: 120,
                      child: widget.cards[i],
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.5,
                      child: SizedBox(
                        width: 80,
                        height: 120,
                        child: widget.cards[i],
                      ),
                    ),
                    onDragStarted: () => setState(() => _isDragging[i] = true),
                    onDraggableCanceled: (_, offset) {
                      if (widget.freePlacement) {
                        setState(() {
                          _isDragging[i] = false;
                          _cardPositions[i] = Offset(
                            offset.dx - constraints.maxWidth / 2,
                            offset.dy - constraints.maxHeight / 2,
                          );
                        });
                      }
                    },
                    onDragEnd: (details) {
                      if (widget.freePlacement) {
                        setState(() {
                          _isDragging[i] = false;
                          _cardPositions[i] = Offset(
                            details.offset.dx - constraints.maxWidth / 2,
                            details.offset.dy - constraints.maxHeight / 2,
                          );
                        });
                      }
                    },
                    child: SizedBox(
                      width: 80,
                      height: 120,
                      child: widget.cards[i],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
