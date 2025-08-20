import 'package:fl_carmax/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerItem({super.key, required this.videoUrl});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late final VideoPlayerController _controller;
  bool _showPlayIcon = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        _controller.setLooping(false);
        _controller.seekTo(Duration.zero);
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      setState(() => _showPlayIcon = true);
    } else {
      _controller.play();
      setState(() => _showPlayIcon = false);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (!_controller.value.isInitialized) const Center(child: CircularProgressIndicator()),
        GestureDetector(
          onTap: _togglePlayPause,
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        if (_showPlayIcon || !_controller.value.isPlaying) const Icon(Icons.play_circle_filled, size: 60, color: Colors.white),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller,
                builder: (context, value, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(value.position),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          _formatDuration(value.duration),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                colors: const VideoProgressColors(playedColor: primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
