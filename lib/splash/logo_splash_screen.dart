import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LogoSplashScreen extends StatefulWidget {
  const LogoSplashScreen({super.key});

  @override
  State<LogoSplashScreen> createState() => _LogoSplashScreenState();
}

class _LogoSplashScreenState extends State<LogoSplashScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  late ValueNotifier<VideoPlayerValue> _videoStateNotifier;
  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videoStateNotifier = ValueNotifier(VideoPlayerValue(duration: Duration.zero));
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/logo_opener.mp4');
      await _controller.initialize();

      if (!mounted) return;

      _controller.addListener(_onVideoStateChanged);
      _videoStateNotifier.value = _controller.value;

      _controller.play();
    } catch (e) {
      debugPrint('[SPLASH] Video initialization failed: $e');
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && !_navigationTriggered) {
            _navigationTriggered = true;
            Navigator.of(context).pushReplacementNamed('/home');
          }
        });
      }
    }
  }

  void _onVideoStateChanged() {
    if (!mounted) return;

    _videoStateNotifier.value = _controller.value;

    final isVideoEnded = _controller.value.isInitialized &&
        _controller.value.position >= _controller.value.duration - const Duration(milliseconds: 100);

    if (isVideoEnded && !_navigationTriggered) {
      debugPrint('[SPLASH] Video completed, navigating to home');
      _navigationTriggered = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          debugPrint('[SPLASH] Navigating to HomePage now');
          Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller.value.isInitialized &&
          !_controller.value.isPlaying &&
          !_navigationTriggered) {
        _controller.play();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onVideoStateChanged);
    _controller.dispose();
    _videoStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _videoStateNotifier,
          builder: (context, videoState, _) {
            if (!videoState.isInitialized) {
              return const SizedBox.expand(
                child: ColoredBox(
                  color: Colors.white,
                ),
              );
            }

            if (videoState.hasError) {
              return const SizedBox.expand(
                child: ColoredBox(
                  color: Colors.white,
                ),
              );
            }

            return Container(
              color: Colors.white,
              child: Center(
                child: AspectRatio(
                  aspectRatio: videoState.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
