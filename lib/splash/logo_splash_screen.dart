import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class LogoSplashScreen extends StatefulWidget {
  const LogoSplashScreen({
    super.key,
    this.resolveNextRoute,
  });

  final Future<String> Function()? resolveNextRoute;

  @override
  State<LogoSplashScreen> createState() => _LogoSplashScreenState();
}

class _LogoSplashScreenState extends State<LogoSplashScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  late final ValueNotifier<VideoPlayerValue> _videoStateNotifier;
  Timer? _fallbackTimer;
  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[SPLASH] initState called');
    WidgetsBinding.instance.addObserver(this);
    _videoStateNotifier = ValueNotifier(VideoPlayerValue(duration: Duration.zero));
    _scheduleFallbackNavigation();
    _initializeVideo();
  }

  void _scheduleFallbackNavigation() {
    _fallbackTimer?.cancel();
    debugPrint('[SPLASH] Scheduling fallback navigation in 3 seconds');
    _fallbackTimer = Timer(const Duration(seconds: 3), () {
      debugPrint('[SPLASH] Fallback timer fired, mounted=$mounted, triggered=$_navigationTriggered');
      if (mounted && !_navigationTriggered) {
        _navigateNext('[SPLASH] Fallback');
      }
    });
  }

  Future<void> _navigateNext(String reason) async {
    if (_navigationTriggered) {
      return;
    }
    _navigationTriggered = true;

    var routeName = '/home';
    try {
      final resolver = widget.resolveNextRoute;
      if (resolver != null) {
        routeName = await resolver();
      }
    } catch (e) {
      debugPrint('$reason route resolution error: $e');
    }

    if (!mounted) {
      return;
    }

    try {
      debugPrint('$reason: navigating to $routeName');
      Navigator.of(context).pushReplacementNamed(routeName);
    } catch (e) {
      debugPrint('$reason navigation error: $e');
    }
  }

  Future<void> _initializeVideo() async {
    try {
      debugPrint('[SPLASH] Starting video initialization');
      final controller = VideoPlayerController.asset('assets/logo_opener.mp4');
      _controller = controller;
      debugPrint('[SPLASH] Created controller, awaiting initialize');
      await controller.initialize();
      debugPrint('[SPLASH] Controller initialized successfully');

      if (!mounted) {
        debugPrint('[SPLASH] Widget unmounted, aborting');
        return;
      }

      controller.addListener(_onVideoStateChanged);
      _videoStateNotifier.value = controller.value;

      debugPrint('[SPLASH] Starting video playback');
      await controller.play();
    } catch (e) {
      debugPrint('[SPLASH] Video initialization failed: $e');
      if (mounted) {
        debugPrint('[SPLASH] Scheduling 1.5s delayed navigation after video error');
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && !_navigationTriggered) {
            _navigateNext('[SPLASH] Delayed nav after video error');
          }
        });
      }
    }
  }

  void _onVideoStateChanged() {
    if (!mounted) return;

    final controller = _controller;
    if (controller == null) {
      return;
    }

    _videoStateNotifier.value = controller.value;

    final isVideoEnded = controller.value.isInitialized &&
        controller.value.position >= controller.value.duration - const Duration(milliseconds: 100);

    if (isVideoEnded && !_navigationTriggered) {
      debugPrint('[SPLASH] Video completed, navigating to next route');
      _fallbackTimer?.cancel();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _navigateNext('[SPLASH] Video complete');
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller?.pause();
    } else if (state == AppLifecycleState.resumed) {
      final controller = _controller;
      if (controller != null &&
          controller.value.isInitialized &&
          !controller.value.isPlaying &&
          !_navigationTriggered) {
        controller.play();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fallbackTimer?.cancel();
    _controller?.removeListener(_onVideoStateChanged);
    _controller?.dispose();
    _videoStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _videoStateNotifier,
          builder: (context, videoState, _) {
            // If video is initialized and has no error, show video
            if (videoState.isInitialized && !videoState.hasError && _controller != null) {
              return Container(
                color: Colors.white,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: videoState.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              );
            }

            // Fallback: show static logo placeholder or text
            return SizedBox.expand(
              child: ColoredBox(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shield_rounded, size: 60, color: Color(0xFF4CAF50)),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Crisync',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}
