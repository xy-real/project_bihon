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
  late Future<void> _initializeVideoFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset('assets/logo_opener.mp4');
    _initializeVideoFuture = _controller.initialize().then((_) {
      debugPrint('[SPLASH] Video initialized successfully');
      if (mounted) {
        setState(() {});
        _controller.play();
        _controller.addListener(_onVideoStateChanged);
      }
    }).catchError((error) {
      debugPrint('[SPLASH] ERROR during initialization: $error');
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onVideoStateChanged() {
    if (!mounted) return;

    if (_controller.value.hasError) {
      debugPrint('[SPLASH] ERROR: ${_controller.value.errorDescription}');
    }

    if (_controller.value.position >= _controller.value.duration) {
      debugPrint('[SPLASH] Video playback completed');
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller.value.isInitialized && !_controller.value.isPlaying) {
        _controller.play();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onVideoStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeVideoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_controller.value.hasError) {
              debugPrint('[SPLASH] Showing fallback image due to error');
              return Container(
                color: Colors.black,
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.expand(
                        child: ColoredBox(
                          color: Colors.black,
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  color: Colors.black,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            debugPrint('[SPLASH] Snapshot error: ${snapshot.error}');
            return Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          } else {
            return Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
