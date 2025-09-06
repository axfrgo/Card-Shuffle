import 'dart:async';
import 'package:flutter/material.dart';
import '../services/capture_recorder.dart';

class ScreenRecordingOverlay extends StatefulWidget {
  const ScreenRecordingOverlay({super.key});

  @override
  State<ScreenRecordingOverlay> createState() => _ScreenRecordingOverlayState();
}

class _ScreenRecordingOverlayState extends State<ScreenRecordingOverlay> {
  final _recorder = CaptureRecorder();
  Timer? _autoTimer;
  Duration _elapsed = Duration.zero;
  DateTime? _startedAt;
  String? _lastFrame;

  Future<void> _toggleRecording() async {
    if (_recorder.isRecording) {
      await _recorder.stop();
      _autoTimer?.cancel();
      setState(() {});
      // Removed obsolete screen recording overlay.
                    await _recorder.captureFrame();
                    setState(() => _lastFrame = _recorder.lastPath);
                  }
                }),
              ],
            ),
            if (_lastFrame != null) ...[
              const SizedBox(height: 6),
              Text('Last: ${_lastFrame!.split('/').last}', style: const TextStyle(color: Colors.white54, fontSize: 10), overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            const Text('PNG seq in temp dir', style: TextStyle(color: Colors.white30, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _btn(String label, VoidCallback onTap, {Color? color}) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color ?? Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
      );
}
