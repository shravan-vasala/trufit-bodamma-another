import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../theme/app_colors.dart';

class YoutubePlayerScreen extends StatefulWidget {
  const YoutubePlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  final String videoId;
  final String title;

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.title,
          style: const TextStyle(color: AppColors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.primary,
          progressColors: const ProgressBarColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primaryLight,
          ),
        ),
      ),
    );
  }
}
