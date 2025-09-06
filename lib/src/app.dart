import 'package:flutter/material.dart';
import 'widgets/deck_widget.dart';
import 'widgets/deal_widget.dart';

class TarotApp extends StatelessWidget {
  const TarotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moonworld Tarot Shuffle',
      theme: ThemeData(
        primaryColor: const Color(0xFFA83535),
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'HelveticaNeue',
      ),
      home: const HomePage(),
    );
  }
}

// Scene controls removed per user request

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _deckKey = GlobalKey<DeckWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            DealWidget(
              onReset: () => _deckKey.currentState?.resetDeck(),
              onReadyShuffle: () {
                final s = _deckKey.currentState;
                if (s != null) {
                  if (s.isReadyForShuffle) {
                    s.startShuffle();
                  } else if (s.isShuffling) {
                    s.stopShuffle();
                  }
                }
              },
            ),
            Expanded(child: DeckWidget(key: _deckKey)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
