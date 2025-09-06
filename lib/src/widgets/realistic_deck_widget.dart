import 'dart:math';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'tarot_card_3d.dart';
import 'infinite_board.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class RealisticDeckWidget extends StatefulWidget {
  const RealisticDeckWidget({super.key});

  @override
  RealisticDeckWidgetState createState() => RealisticDeckWidgetState();
}

class RealisticDeckWidgetState extends State<RealisticDeckWidget> 
    with TickerProviderStateMixin {
  
  // Realistic shuffle animation parameters
  static const int _levitationDurationMs = 2000; // Cards rise together
  static const int _shuffleDurationMs = 3000; // Natural shuffle motion
  static const int _realignDurationMs = 1500; // Return to pile
  static const double _maxLevitationHeight = 150.0; // How high cards float
  static const double _shuffleRadius = 80.0; // Shuffle movement radius
  static const double _cardSpacing = 2.0; // Stack spacing when in pile
  
  // Shuffle motion phases
  enum ShufflePhase { pile, levitating, shuffling, realigning }
  ShufflePhase _currentPhase = ShufflePhase.pile;

  // Core state
  List<Map<String, dynamic>> _cardData = [];
  List<Map<String, dynamic>> _deckPile = []; // Main deck pile
  List<Map<String, dynamic>> _placedCards = []; // Cards on infinite board
  bool _loaded = false;
  bool _canFinishShuffling = false;

  // Animation controllers
  late AnimationController _levitationController;
  late AnimationController _shuffleController;
  late AnimationController _realignController;

  // Per-card shuffle targets (randomized positions during shuffle)
  List<Offset> _shuffleTargets = [];
  List<double> _shuffleRotations = [];

  @override
  void initState() {
    super.initState();
    
    _levitationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _levitationDurationMs),
    );
    
    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _shuffleDurationMs),
    );
    
    _realignController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _realignDurationMs),
    );

    _loadCards();
  }

  @override
  void dispose() {
    _levitationController.dispose();
    _shuffleController.dispose();
    _realignController.dispose();
    super.dispose();
  }

  // Public interface methods
  bool get isShuffling => _currentPhase != ShufflePhase.pile;
  bool get canFinishShuffling => _canFinishShuffling;

  void startShuffle() async {
    if (_currentPhase != ShufflePhase.pile) return;
    
    setState(() {
      _currentPhase = ShufflePhase.levitating;
      _canFinishShuffling = false;
    });

    _generateShuffleTargets();
    
    // Phase 1: Levitation
    await _levitationController.forward();
    
    setState(() => _currentPhase = ShufflePhase.shuffling);
    
    // Phase 2: Shuffle motion
    _shuffleController.repeat();
    
    // Allow finishing after a delay
    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _canFinishShuffling = true);
    });
  }

  void stopShuffle() async {
    if (_currentPhase != ShufflePhase.shuffling || !_canFinishShuffling) return;
    
    _shuffleController.stop();
    setState(() => _currentPhase = ShufflePhase.realigning);
    
    // Randomize deck order
    _deckPile.shuffle();
    
    // Phase 3: Realign to pile
    await _realignController.forward();
    
    _levitationController.reset();
    _shuffleController.reset();
    _realignController.reset();
    
    setState(() => _currentPhase = ShufflePhase.pile);
  }

  void randomizeDeck() {
    setState(() => _deckPile.shuffle());
  }

  List<Map<String, dynamic>> drawTopCards(int count) {
    final drawn = <Map<String, dynamic>>[];
    for (int i = 0; i < count && _deckPile.isNotEmpty; i++) {
      drawn.add(_deckPile.removeAt(0));
    }
    setState(() {});
    return drawn;
  }

  void _generateShuffleTargets() {
    _shuffleTargets.clear();
    _shuffleRotations.clear();
    
    final random = Random();
    for (int i = 0; i < _deckPile.length; i++) {
      // Random position within shuffle radius
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * _shuffleRadius;
      
      _shuffleTargets.add(Offset(
        cos(angle) * distance,
        sin(angle) * distance,
      ));
      
      _shuffleRotations.add((random.nextDouble() - 0.5) * 0.5); // Small rotation
    }
  }

  void _placeCardOnBoard(Map<String, dynamic> card, Offset position) {
    card['boardPosition'] = position;
    card['boardRotation'] = (Random().nextDouble() - 0.5) * 0.3;
    
    setState(() {
      _placedCards.add(card);
    });
  }

  void _removeCardFromBoard(String cardName) {
    setState(() {
      _placedCards.removeWhere((card) => card['name'] == cardName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Infinite board background
            Positioned.fill(
              child: InfiniteBoard(
                placedCards: _placedCards,
                onCardPlaced: _placeCardOnBoard,
                onCardRemoved: _removeCardFromBoard,
              ),
            ),
            
            // Deck pile area
            Positioned(
              left: 50,
              top: 50,
              child: _buildDeckPile(context),
            ),
            
            // Shuffle controls
            Positioned(
              bottom: 50,
              left: 50,
              child: _buildShuffleControls(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeckPile(BuildContext context) {
    const pileWidth = 120.0;
    const pileHeight = 180.0;
    
    return SizedBox(
      width: pileWidth + 100, // Extra space for shuffle motion
      height: pileHeight + 200,
      child: Stack(
        children: [
          // Deck outline when empty
          if (_deckPile.isEmpty)
            Positioned(
              left: 50,
              top: 50,
              child: Container(
                width: pileWidth,
                height: pileHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Deck Empty',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            ),
          
          // Cards in pile/shuffle
          ...List.generate(_deckPile.length, (index) {
            return _buildShuffleCard(
              context,
              index,
              _deckPile[index],
              pileWidth,
              pileHeight,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShuffleCard(
    BuildContext context,
    int index,
    Map<String, dynamic> card,
    double pileWidth,
    double pileHeight,
  ) {
    Offset position;
    double rotation = 0.0;
    double elevation = index * _cardSpacing;
    
    switch (_currentPhase) {
      case ShufflePhase.pile:
        position = Offset(50, 50);
        break;
        
      case ShufflePhase.levitating:
        final t = _levitationController.value;
        final targetY = 50 - _maxLevitationHeight;
        position = Offset(
          50,
          ui.lerpDouble(50, targetY, Curves.easeOut.transform(t))!,
        );
        elevation = index * _cardSpacing + (t * 20); // Spread out vertically
        break;
        
      case ShufflePhase.shuffling:
        final t = _shuffleController.value;
        final targetPos = _shuffleTargets.length > index 
            ? _shuffleTargets[index] 
            : Offset.zero;
        
        // Oscillate around target position
        final oscillation = Offset(
          sin(t * 2 * pi + index * 0.5) * 20,
          cos(t * 2 * pi + index * 0.3) * 15,
        );
        
        position = Offset(
          50 + targetPos.dx + oscillation.dx,
          50 - _maxLevitationHeight + targetPos.dy + oscillation.dy,
        );
        
        rotation = _shuffleRotations.length > index 
            ? _shuffleRotations[index] * sin(t * 2 * pi + index)
            : 0.0;
            
        elevation = index * _cardSpacing + 20;
        break;
        
      case ShufflePhase.realigning:
        final t = _realignController.value;
        final currentPos = _shuffleTargets.length > index 
            ? Offset(50 + _shuffleTargets[index].dx, 50 - _maxLevitationHeight + _shuffleTargets[index].dy)
            : Offset(50, 50 - _maxLevitationHeight);
        
        position = Offset(
          ui.lerpDouble(currentPos.dx, 50, Curves.easeInOut.transform(t))!,
          ui.lerpDouble(currentPos.dy, 50, Curves.easeInOut.transform(t))!,
        );
        
        final currentRotation = _shuffleRotations.length > index 
            ? _shuffleRotations[index]
            : 0.0;
        rotation = ui.lerpDouble(currentRotation, 0.0, Curves.easeInOut.transform(t))!;
        elevation = ui.lerpDouble(index * _cardSpacing + 20, index * _cardSpacing, t)!;
        break;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_levitationController, _shuffleController, _realignController]),
      builder: (context, child) {
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..translate(0.0, 0.0, elevation)
              ..rotateZ(rotation),
            child: Draggable<Map<String, dynamic>>(
              data: card,
              feedback: Material(
                color: Colors.transparent,
                child: Transform.scale(
                  scale: 1.1,
                  child: TarotCard3D(
                    id: card['name'] as String,
                    assetPath: card['asset'] as String? ?? '',
                    width: pileWidth,
                    height: pileHeight,
                    faceUp: false,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: TarotCard3D(
                  id: card['name'] as String,
                  assetPath: card['asset'] as String? ?? '',
                  width: pileWidth,
                  height: pileHeight,
                  faceUp: false,
                ),
              ),
              onDragStarted: () {
                // Remove from deck when dragging starts
                setState(() {
                  _deckPile.removeAt(index);
                });
              },
              child: TarotCard3D(
                id: card['name'] as String,
                assetPath: card['asset'] as String? ?? '',
                width: pileWidth,
                height: pileHeight,
                faceUp: false,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShuffleControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: _currentPhase == ShufflePhase.pile ? startShuffle : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Start Shuffle'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _currentPhase == ShufflePhase.shuffling && _canFinishShuffling
              ? stopShuffle
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Done Shuffling'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: randomizeDeck,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Randomize'),
        ),
        const SizedBox(height: 16),
        Text(
          'Cards in deck: ${_deckPile.length}',
          style: const TextStyle(color: Colors.white70),
        ),
        Text(
          'Cards placed: ${_placedCards.length}',
          style: const TextStyle(color: Colors.white70),
        ),
        Text(
          'Phase: ${_currentPhase.name}',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Future<void> _loadCards() async {
    try {
      final raw = await rootBundle.loadString('assets/cards.json');
      final list = json.decode(raw) as List<dynamic>;
      _cardData = list.cast<Map<String, dynamic>>();
      _cardData.sort(
          (a, b) => (a['name'] as String).compareTo(b['name'] as String));

      // Initialize deck pile with all cards
      _deckPile = List<Map<String, dynamic>>.from(_cardData);
      
      setState(() => _loaded = true);
    } catch (_) {
      // Fallback data
      _cardData = List.generate(
          22, (i) => {'id': '$i', 'name': 'Card ${i + 1}', 'asset': ''});
      _deckPile = List<Map<String, dynamic>>.from(_cardData);
      setState(() => _loaded = true);
    }
  }
}
