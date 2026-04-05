import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoControllerPreloader {
  static final VideoControllerPreloader _instance =
      VideoControllerPreloader._internal();

  VideoPlayerController? _controller;
  bool _isPreloading = false;
  bool _isReady = false;

  factory VideoControllerPreloader() {
    return _instance;
  }

  VideoControllerPreloader._internal();

  Future<VideoPlayerController?> preloadLogoVideo() async {
    if (_isReady) {
      return _controller;
    }

    if (_isPreloading) {
      int attempts = 0;
      while (_isPreloading && attempts < 100) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }
      return _controller;
    }

    _isPreloading = true;

    try {
      _controller = VideoPlayerController.asset('assets/logo_opener.mp4');
      await _controller!.initialize();
      _isReady = true;
    } catch (e) {
      debugPrint('Video preload failed: $e');
      _controller = null;
      _isReady = false;
    } finally {
      _isPreloading = false;
    }

    return _controller;
  }

  bool get isReady => _isReady;

  VideoPlayerController? get controller => _controller;

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isReady = false;
    _isPreloading = false;
  }
}
