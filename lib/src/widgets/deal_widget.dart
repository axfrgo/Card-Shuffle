import 'dart:async';
import 'package:flutter/material.dart';
import 'tarot_card_3d.dart';

class DealWidget extends StatefulWidget {
  final VoidCallback? onReadyShuffle;
  final VoidCallback? onReset;

  const DealWidget({super.key, this.onReadyShuffle, this.onReset});

  @override
  State<DealWidget> createState() => _DealWidgetState();
}

class _DealWidgetState extends State<DealWidget> with TickerProviderStateMixin {
  bool _isShufflingLocal = false;
  bool _canFinishLocal = false;
  Timer? _finishTimer;

  @override
  void dispose() {
    _finishTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Action buttons column on left
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              ElevatedButton(onPressed: widget.onReset, child: const Text('Reset')),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _isShufflingLocal ? Colors.redAccent : Colors.blueAccent),
                onPressed: () {
                  if (!_isShufflingLocal) {
                    widget.onReadyShuffle?.call();
                    setState(() {
                      _isShufflingLocal = true;
                      _canFinishLocal = false;
                    });
                    _finishTimer?.cancel();
                    _finishTimer = Timer(const Duration(milliseconds: 900), () {
                      if (mounted) setState(() => _canFinishLocal = true);
                    });
                  } else if (_isShufflingLocal && _canFinishLocal) {
                    widget.onReadyShuffle?.call();
                    _finishTimer?.cancel();
                    setState(() {
                      _isShufflingLocal = false;
                      _canFinishLocal = false;
                    });
                  }
                },
                child: Text(_isShufflingLocal ? (_canFinishLocal ? 'Done shuffling' : 'Shuffling...') : 'Ready to shuffle'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
