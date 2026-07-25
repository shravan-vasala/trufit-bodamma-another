import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../theme/app_colors.dart';

class YoutubePlayerScreen extends StatefulWidget {
  const YoutubePlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    required this.subtitle,
    required this.reps,
  });

  final String videoId;
  final String title;
  final String subtitle;
  final String reps;

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );

    _controller.setFullScreenListener((isFullScreen) {
      if (!mounted) return;
      setState(() {
        _isFullScreen = isFullScreen;
      });
      if (isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvoked: (didPop) {
        if (!didPop && _isFullScreen) {
          _controller.exitFullScreen();
        }
      },
      child: YoutubePlayerScaffold(
        controller: _controller,
        builder: (context, player) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: _isFullScreen
                ? null
                : AppBar(
                    backgroundColor: Colors.black,
                    title: const Text(
                      'Exercise Video',
                      style: TextStyle(color: AppColors.white, fontSize: 16),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onDoubleTap: () {
                    if (_isFullScreen) {
                      _controller.exitFullScreen();
                    } else {
                      _controller.enterFullScreen();
                    }
                  },
                  child: player,
                ),
                if (!_isFullScreen) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (widget.reps.isNotEmpty)
                          Text(
                            'Reps: ${widget.reps}',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _controller.enterFullScreen(),
                            icon: const Icon(Icons.fullscreen, color: AppColors.primary),
                            label: const Text(
                              'Enter Fullscreen',
                              style: TextStyle(color: AppColors.primary, fontSize: 16),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
