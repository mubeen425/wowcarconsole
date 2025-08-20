import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubePlayerWidget extends StatefulWidget {
  final String videoUrl;
  const YoutubePlayerWidget({super.key, required this.videoUrl});

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl);

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId ?? '',
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: YoutubePlayerScaffold(
        controller: _controller,
        aspectRatio: 16 / 9,
        builder: (context, player) {
          return Column(
            children: [
              player,
            ],
          );
        },
      ),
    );
  }
}
