import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TarotCard3D extends StatefulWidget {
  final String id;
  final String assetPath; // front
  final bool faceUp;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool reversed;
  final bool disableAnimation; // New parameter to force immediate display without animation

  const TarotCard3D({
    super.key,
    required this.id,
    required this.assetPath,
    this.faceUp = false,
    this.onTap,
    this.width = 100,
    this.height = 160,
    this.reversed = false,
    this.disableAnimation = false, // Default to false to maintain existing behavior
  });

  @override
  State<TarotCard3D> createState() => _TarotCard3DState();
}

class _TarotCard3DState extends State<TarotCard3D> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool _faceUp = false;

  @override
  void initState() {
    super.initState();
    _faceUp = widget.faceUp;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (_faceUp) {
      _controller.value = 1.0; // Show front
    } else {
      _controller.value = 0.0; // Show back
    }
  }

  @override
  void didUpdateWidget(covariant TarotCard3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.faceUp != widget.faceUp) {
      _faceUp = widget.faceUp;
      if (_faceUp) _controller.forward(); else _controller.reverse();
    }
  }

  void _handleTap() {
    // If parent provided onTap it will manage faceUp state; call it and don't toggle internal state.
    if (widget.onTap != null) {
      widget.onTap!.call();
      return;
    }

    setState(() => _faceUp = !_faceUp);
    if (_faceUp) _controller.forward(); else _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return GestureDetector(
      onTap: _handleTap,
      child: widget.disableAnimation 
        ? Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.6 * 255).toInt()), blurRadius: 6, offset: const Offset(0, 4))],
            ),
            child: widget.faceUp ? _buildFront(borderRadius) : _buildBack(borderRadius),
          )
        : AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final angle = _controller.value * pi; // 0 -> pi
              final isFront = angle > pi / 2;
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle);

              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.6 * 255).toInt()), blurRadius: 6, offset: const Offset(0, 4))],
                  ),
                  child: isFront ? _buildFront(borderRadius) : _buildBack(borderRadius),
                ),
              );
            },
          ),
    );
  }

  Widget _buildBack(BorderRadius borderRadius) {
    // Back rendering: if an SVG asset with suffix _back.svg exists, use it; otherwise fallback to color.
    final backSvg = 'assets/tarot/cards/back.svg';
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        color: const Color(0xFF1B1B3A),
        child: FutureBuilder<bool>(
          future: _assetExists(backSvg),
          builder: (context, snap) {
            if (snap.hasData && snap.data == true) {
              return SvgPicture.asset(backSvg, fit: BoxFit.cover);
            }
            return Center(child: Text('Back', style: TextStyle(color: Colors.white.withAlpha((0.9 * 255).toInt()), fontFamily: 'HelveticaNeue')));
          },
        ),
      ),
    );
  }

  Widget _buildFront(BorderRadius borderRadius) {
    // Placeholder front, load PNG/SVG
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        color: Colors.white,
        child: Transform(
          alignment: Alignment.center,
          transform: widget.reversed ? (Matrix4.rotationZ(pi)) : Matrix4.identity(),
          child: _buildFrontAsset(),
        ),
      ),
    );
  }

  Widget _buildFrontAsset() {
    final asset = widget.assetPath;
    if (asset.isEmpty) return Center(child: Text(widget.id, style: const TextStyle(color: Colors.black, fontFamily: 'TimesNewRoman')));

    return FutureBuilder<String>(
      future: DefaultAssetBundle.of(context).loadString('AssetManifest.json'),
      builder: (context, snap) {
        if (!snap.hasData) return Center(child: Text(widget.id, style: const TextStyle(color: Colors.black, fontFamily: 'TimesNewRoman')));
        final manifest = snap.data!;
        if (!manifest.contains(asset)) return Center(child: Text(widget.id, style: const TextStyle(color: Colors.black, fontFamily: 'TimesNewRoman')));

        if (asset.toLowerCase().endsWith('.svg')) {
          return SvgPicture.asset(asset, fit: BoxFit.cover);
        }
        return Image.asset(asset, fit: BoxFit.cover, errorBuilder: (c, e, s) => Center(child: Text(widget.id, style: const TextStyle(color: Colors.black, fontFamily: 'TimesNewRoman'))));
      },
    );
  }

  Future<bool> _assetExists(String asset) async {
    try {
      final bundle = DefaultAssetBundle.of(context);
      final manifest = await bundle.loadString('AssetManifest.json');
      return manifest.contains(asset);
    } catch (e) {
      return false;
    }
  }
}
