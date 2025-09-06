import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'tarot_card_3d.dart';

class InfiniteBoard extends StatefulWidget {
  final List<Map<String, dynamic>> placedCards;
  final Function(Map<String, dynamic>, Offset)? onCardPlaced;
  final Function(String)? onCardRemoved;

  const InfiniteBoard({
    super.key,
    required this.placedCards,
    this.onCardPlaced,
    this.onCardRemoved,
  });

  @override
  State<InfiniteBoard> createState() => _InfiniteBoardState();
}

class _InfiniteBoardState extends State<InfiniteBoard> {
  final TransformationController _transformationController = TransformationController();
  final List<PlacedCard> _cards = [];

  @override
  void initState() {
    super.initState();
    _updateCardsFromWidget();
  }

  @override
  void didUpdateWidget(InfiniteBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placedCards != widget.placedCards) {
      _updateCardsFromWidget();
    }
  }

  void _updateCardsFromWidget() {
    _cards.clear();
    for (var card in widget.placedCards) {
      _cards.add(PlacedCard(
        data: card,
        position: card['boardPosition'] ?? Offset.zero,
        rotation: card['boardRotation'] ?? 0.0,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);
        
        // Convert screen position to board position accounting for transformation
        final Matrix4 transform = _transformationController.value;
        final Matrix4 invertedTransform = Matrix4.inverted(transform);
        final Vector3 transformed = invertedTransform.transform3(Vector3(
          localPosition.dx, 
          localPosition.dy, 
          0.0
        ));
        
        final boardPosition = Offset(transformed.x, transformed.y);
        
        widget.onCardPlaced?.call(details.data, boardPosition);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.05),
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 3.0,
            child: SizedBox(
              width: 4000, // Large canvas
              height: 4000,
              child: Stack(
                children: [
                  // Grid background
                  CustomPaint(
                    size: const Size(4000, 4000),
                    painter: GridPainter(),
                  ),
                  // Placed cards
                  ..._cards.map((placedCard) => Positioned(
                    left: placedCard.position.dx - 50,
                    top: placedCard.position.dy - 80,
                    child: Transform.rotate(
                      angle: placedCard.rotation,
                      child: GestureDetector(
                        onTap: () {
                          // Allow removal of cards
                          widget.onCardRemoved?.call(placedCard.data['name'] as String);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TarotCard3D(
                            id: placedCard.data['name'] as String,
                            assetPath: placedCard.data['asset'] as String? ?? '',
                            width: 100,
                            height: 160,
                            faceUp: true,
                          ),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}

class PlacedCard {
  final Map<String, dynamic> data;
  final Offset position;
  final double rotation;

  PlacedCard({
    required this.data,
    required this.position,
    this.rotation = 0.0,
  });
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;

    const gridSpacing = 50.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
