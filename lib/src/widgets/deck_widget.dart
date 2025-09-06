import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';

class DeckWidget extends StatefulWidget {
  final int cardCount;
  final Size cardSize;
  final VoidCallback? onShuffleComplete;

  const DeckWidget({
    super.key,
    this.cardCount = 72,
    this.cardSize = const Size(80, 120),
    this.onShuffleComplete,
  });

  @override
  State<DeckWidget> createState() => DeckWidgetState();
}

class DeckWidgetState extends State<DeckWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late List<Animation<Offset>> _offsetAnimations;
  late List<Animation<double>> _rotationAnimations;
  late AnimationController _reorderController;
  late Animation<double> _reorderAnimation;
  late AnimationController _spreadController;
  late List<Animation<Offset>> _spreadAnimations;
  late AnimationController _collapseController; // controller for collapsing spread
  late List<Animation<Offset>> _collapseAnimations; // animations from spread back to deck center
  late AnimationController _perspectiveController;
  late Animation<double> _rotationXAnimation;
  late Animation<double> _rotationYAnimation;

  final Duration _collapseDuration = const Duration(milliseconds: 900);

  bool _isShuffling = false;
  bool _isSpread = false;
  bool _pendingSpreadToShuffle = false; // indicates first shuffle cycle after spread
  final Random _random = Random();

  List<int> _cardOrder = [];
  List<int> _targetOrder = [];
  final Map<int, CardInfo> _cardInfos = {};
  Offset _cursorPosition = Offset.zero;

  bool get isShuffling => _isShuffling;
  bool get canFinishShuffling => true; // Always allow finishing
  bool get isReadyForShuffle => !_isShuffling && !_isSpread && !_collapseController.isAnimating;

  List<Map<String, dynamic>> drawTopCards(int count) {
    final drawn = <Map<String, dynamic>>[];
    for (int i = 0; i < count && _cardOrder.isNotEmpty; i++) {
      final cardIndex = _cardOrder.removeLast();
      drawn.add({
        'name': 'Card ${cardIndex + 1}',
        'asset': '',
      });
    }
    return drawn;
  }

  void consumeCardByName(String name) {
    _cardOrder.removeWhere((index) => 'Card ${index + 1}' == name);
    setState(() {});
  }

  void randomizeDeck() {
    setState(() {
      _cardOrder.shuffle(_random);
      _targetOrder = List.from(_cardOrder);
      _buildAnimations();
    });
  }

  void stopShuffle() {
    if (_isShuffling) {
      setState(() {
        _isShuffling = false;
      });
      _controller.stop();
      _reorderController.stop();
      _startSpreadAnimation();
    }
  }

  void _startSpreadAnimation() {
    setState(() {
      _isSpread = true;
    });
    _resetPerspective();
    _spreadController.forward(from: 0);
  }

  void _resetPerspective() {
    _rotationXAnimation = Tween<double>(
      begin: _rotationXAnimation.value,
      end: 0,
    ).animate(_perspectiveController);

    _rotationYAnimation = Tween<double>(
      begin: _rotationYAnimation.value,
      end: 0,
    ).animate(_perspectiveController);

    _perspectiveController.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _reorderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _reorderAnimation =
        CurvedAnimation(parent: _reorderController, curve: Curves.easeInOut);

    _spreadController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Slower transition
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onShuffleComplete?.call();
          // Once spread is complete, update the interactive positions
          for (int j = 0; j < widget.cardCount; j++) {
            final cardIndex = _cardOrder[j];
            _cardInfos[cardIndex]?.position = _spreadAnimations[j].value;
          }
        }
      });

    _collapseController = AnimationController(vsync: this, duration: _collapseDuration);

    _perspectiveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _rotationXAnimation = Tween<double>(begin: 0, end: 0).animate(_perspectiveController);
    _rotationYAnimation = Tween<double>(begin: 0, end: 0).animate(_perspectiveController);

    _cardOrder = List.generate(widget.cardCount, (i) => i);
    _targetOrder = List.from(_cardOrder);
    for (int i = 0; i < widget.cardCount; i++) {
      _cardInfos[i] = CardInfo(position: Offset.zero, index: i);
    }
    _buildAnimations();
    // Don't call _buildSpreadAnimations() here - will be called in didChangeDependencies

    _controller.addStatusListener((status) {
      if (!_isShuffling) return;

      if (status == AnimationStatus.completed) {
        setState(() {
          _targetOrder = List.from(_cardOrder);
          _targetOrder.shuffle(_random);
        });
        if (_pendingSpreadToShuffle) {
          _pendingSpreadToShuffle = false;
          _buildAnimations();
        }
        _reorderController.forward(from: 0).whenComplete(() {
          setState(() {
            _cardOrder = List.from(_targetOrder);
          });
          if (_isShuffling) {
            _controller.reverse();
          }
        });
      } else if (status == AnimationStatus.dismissed) {
        if (_isShuffling) {
          _controller.forward(from: 0);
        } else {
          widget.onShuffleComplete?.call();
        }
      }
    });
  }

  void _buildAnimations() {
    _offsetAnimations = List.generate(widget.cardCount, (i) {
      final dx = (_random.nextDouble() - 0.5) * 2 * 120;
      final dy = (_random.nextDouble() - 0.5) * 2 * 100;
      return Tween<Offset>(
        begin: Offset.zero,
        end: Offset(dx, dy),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
    });

    _rotationAnimations = List.generate(widget.cardCount, (i) {
      final angle = (_random.nextDouble() - 0.5) * pi / 6;
      return Tween<double>(
        begin: 0,
        end: angle,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
    });
  }

  void _buildSpreadAnimations() {
    // Only access MediaQuery if context is ready
    if (!mounted) return;
    
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Because the Stack is center-aligned, (0,0) is the center of the screen.
    // To place a card so its TOP is a fixed margin from the bottom, we translate
    // downward by: halfHeight - (cardHeight/2) - bottomMargin.
    const double bottomMargin = 20.0; // visible gap from bottom edge
    const double leftMargin = 10.0;   // gap from left edge
    final double halfW = screenWidth / 2;
    final double halfH = screenHeight / 2;

    final double baseY = halfH - (widget.cardSize.height / 2) - bottomMargin;

    // Available horizontal width for laying out the spread (inside margins)
    final double availableWidth = screenWidth - (leftMargin * 2) - widget.cardSize.width;
    // Spacing so that we don't push cards off the right edge. Clamp to a max for overlap effect.
    double cardSpacing = widget.cardCount > 1
        ? availableWidth / (widget.cardCount - 1)
        : 0;
    // Limit spacing so there is a nice overlap when many cards.
    cardSpacing = min(cardSpacing, widget.cardSize.width * 0.4);

    // Starting X so the first card's LEFT edge is at leftMargin.
    // Since (0,0) is center and a centered card's left edge is at -cardWidth/2, we need to shift:
    // shiftX = -(halfW) + leftMargin + cardWidth/2
    final double startX = -halfW + leftMargin + (widget.cardSize.width / 2);

    _spreadAnimations = List.generate(widget.cardCount, (i) {
      final double targetX = startX + i * cardSpacing;
      final endPosition = Offset(targetX, baseY);
      return Tween<Offset>(
        begin: Offset.zero,
        end: endPosition,
      ).animate(
        CurvedAnimation(
          parent: _spreadController,
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  void _buildAnimationsFromSpread() {
    if (_spreadAnimations.isEmpty) {
      _buildAnimations();
      return;
    }
    _offsetAnimations = List.generate(widget.cardCount, (i) {
      final begin = _spreadAnimations[i].value;
      final dx = (_random.nextDouble() - 0.5) * 2 * 120;
      final dy = (_random.nextDouble() - 0.5) * 2 * 100;
      final end = Offset(dx, dy);
      return Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    });
    _rotationAnimations = List.generate(widget.cardCount, (i) {
      final angle = (_random.nextDouble() - 0.5) * pi / 6;
      return Tween<double>(
        begin: 0,
        end: angle,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    });
  }

  void startShuffle() {
    if (_isSpread) {
      _buildAnimationsFromSpread();
      setState(() {
        _isSpread = false;
        _isShuffling = true;
        _pendingSpreadToShuffle = true;
      });
      _controller.forward(from: 0);
      return;
    }
    _buildAnimations();
    setState(() {
      _isShuffling = true;
    });
    _controller.forward(from: 0);
  }

  void resetDeck() {
    // If currently spread, animate collapse then finalize full reset
    if (_isSpread) {
      _prepareCollapseAnimations();
      setState(() {
        _isSpread = false;
        _isShuffling = false;
      });
      _collapseController.forward(from: 0).whenComplete(() {
        _collapseController.stop();
        _finalizeDeckReset();
      });
      return;
    }
    // If shuffling, stop animations gracefully
    if (_isShuffling) {
      _controller.stop();
      _reorderController.stop();
    }
    _finalizeDeckReset();
  }

  void _finalizeDeckReset() {
    setState(() {
      _isShuffling = false;
      _isSpread = false;
      _pendingSpreadToShuffle = false;
      // Restore original ordered deck
      _cardOrder = List.generate(widget.cardCount, (i) => i);
      _targetOrder = List.from(_cardOrder);
    });
    // Reset controllers to initial positions
    _controller.reset();
    _reorderController.reset();
    _spreadController.reset();
    _collapseController.reset();
    // Rebuild animations for fresh shuffle start
    _buildAnimations();
    // Rebuild spread positions next frame (needs context)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _buildSpreadAnimations();
    });
  }

  void _prepareCollapseAnimations() {
    if (_spreadAnimations.isEmpty) return;
    // Target deck center (0,0) because deck is centered in Stack
    _collapseAnimations = List.generate(widget.cardCount, (i) {
      final begin = _spreadAnimations[i].value; // current spread position
      return Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _collapseController, curve: Curves.easeInOutCubic));
    });
  }

  Future<void> collapseToDeck({required bool andReshuffle}) async {
    if (!_isSpread) return;
    setState(() {
      _isSpread = false; // will trigger AnimatedBuilder branch
    });
    // Build collapse tweens from current spread values
    _prepareCollapseAnimations();
    await _collapseController.forward(from: 0);
    _collapseController.stop();
    if (andReshuffle) {
      startShuffle();
    } else {
      // Neat stacked deck state
      setState(() {
        _isShuffling = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build spread animations here since they depend on MediaQuery
    _buildSpreadAnimations();
  }

  @override
  void dispose() {
    _controller.dispose();
    _reorderController.dispose();
    _spreadController.dispose();
    _collapseController.dispose();
    _perspectiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        if (_isSpread) {
          // If spread, animate back to zero rotation if not already there
          if (_rotationXAnimation.value != 0 || _rotationYAnimation.value != 0) {
            _resetPerspective();
          }
          return;
        }
        final screenCenter = MediaQuery.of(context).size.center(Offset.zero);
        final cursorOffset = event.position - screenCenter;

        final rotationY = (cursorOffset.dx / screenCenter.dx) * 0.8;
        final rotationX = -(cursorOffset.dy / screenCenter.dy) * 0.8;

        _rotationXAnimation = Tween<double>(
          begin: _rotationXAnimation.value,
          end: rotationX,
        ).animate(_perspectiveController);

        _rotationYAnimation = Tween<double>(
          begin: _rotationYAnimation.value,
          end: rotationY,
        ).animate(_perspectiveController);

        _perspectiveController.forward(from: 0);
      },
      child: AnimatedBuilder(
        animation: _perspectiveController,
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_rotationXAnimation.value)
              ..rotateY(_rotationYAnimation.value),
            alignment: FractionalOffset.center,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (int j = 0; j < widget.cardCount; j++)
              AnimatedBuilder(
                animation: Listenable.merge([_controller, _reorderController, _spreadController, _collapseController, _perspectiveController]),
                builder: (context, _) {
                  final int cardIndex = _cardOrder[j];
                  Offset currentOffset;
                  double currentRotation;

                  if (_spreadController.isAnimating) {
                    currentOffset = _spreadAnimations[j].value;
                    currentRotation = 0;
                  } else if (_isSpread) {
                    currentOffset = _cardInfos[cardIndex]!.position;
                    currentRotation = 0;
                  } else if (_isShuffling) {
                    final reorderProgress = _reorderAnimation.value;
                    final startOffset = _offsetAnimations[_cardOrder[j]].value;
                    final endOffset = _offsetAnimations[_targetOrder[j]].value;
                    currentOffset = Offset.lerp(startOffset, endOffset, reorderProgress)!;

                    final startRotation = _rotationAnimations[_cardOrder[j]].value;
                    final endRotation = _rotationAnimations[_targetOrder[j]].value;
                    currentRotation = _lerpDouble(startRotation, endRotation, reorderProgress);
                  } else {
                    // Neatly stacked deck with 3D offset
                    final tiltY = _rotationYAnimation.value;
                    final tiltX = _rotationXAnimation.value;
                    final dx = j * -tiltY * 2.5; // Fan out horizontally
                    final dy = (j * 0.5) + (j * tiltX * 2.5); // Vertical stack + fan out
                    currentOffset = Offset(dx, dy);
                    currentRotation = 0;
                  }

                  if (_collapseController.isAnimating || (!_isSpread && _collapseController.value > 0)) {
                    // Collapsing animation has priority when active
                    if (_collapseAnimations.isNotEmpty) {
                      currentOffset = _collapseAnimations[j].value;
                      currentRotation = 0;
                    }
                  }

                  return Transform.translate(
                    offset: currentOffset,
                    child: Transform.rotate(
                      angle: currentRotation,
                      child: _buildCard(cardIndex),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(int i, {double opacity = 1.0}) {
    final isFlipped = _cardInfos[i]?.rotationY == pi;
    final cardContent = isFlipped
        ? Center(child: Text('Card ${i + 1}'))
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: SvgPicture.asset(
              'assets/tarot/cards/card_back.svg',
              fit: BoxFit.contain,
            ),
          );

    return GestureDetector(
      onTap: () {
        if (_isSpread) {
          setState(() {
            final card = _cardInfos[i]!;
            card.rotationY = isFlipped ? 0 : pi;
          });
        }
      },
      onPanUpdate: (details) {
        if (_isSpread) {
          setState(() {
            _cardInfos[i]!.position += details.delta;
          });
        }
      },
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateY(_cardInfos[i]?.rotationY ?? 0),
        alignment: FractionalOffset.center,
        child: Container(
          margin: const EdgeInsets.all(4),
          width: widget.cardSize.width,
          height: widget.cardSize.height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black26),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: cardContent,
        ),
      ),
    );
  }
}

// Helper for rotation interpolation
double _lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

class CardInfo {
  Offset position;
  double rotationY;
  int
 
index;

  CardInfo({
    required this.position,
    this.rotationY = 0.0,
    required this.index,
  });
}
