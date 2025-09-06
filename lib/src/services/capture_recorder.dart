import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Very lightweight frame recorder capturing widget frames to PNG sequence.
/// Call start(boundaryKey), then periodically call captureFrame(), and finally stop() to get the folder path.
class CaptureRecorder {
  GlobalKey? _boundaryKey;
  bool _recording = false;
  late Directory _dir;
  int _frame = 0;

  bool get isRecording => _recording;
  String? _lastPath;
  String? get lastPath => _lastPath;

  Future<void> start(GlobalKey boundaryKey) async {
    if (_recording) return;
    _boundaryKey = boundaryKey;
    final docs = await getTemporaryDirectory();
    _dir = await Directory('${docs.path}/capture_${DateTime.now().millisecondsSinceEpoch}').create(recursive: true);
    _frame = 0;
    // Removed obsolete capture recorder service.
  }
