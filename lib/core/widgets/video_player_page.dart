import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Fullscreen player opened when a user taps a video portfolio tile.
///
/// [url] is normally a Supabase Storage URL. A "asset:" prefix instead loads
/// a bundled local file (assets/videos/) — used for demo data so playback
/// never depends on network conditions during a live presentation.
class VideoPlayerPage extends StatefulWidget {
  final String url;

  const VideoPlayerPage({super.key, required this.url});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = widget.url.startsWith('asset:')
        ? VideoPlayerController.asset(widget.url.substring('asset:'.length))
        : VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    }).catchError((e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    });
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _error != null
            ? Text('Could not play video.\n$_error',
                style: const TextStyle(color: Colors.white))
            : !_ready
                ? const CircularProgressIndicator(color: Colors.white)
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      }),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller),
                          if (!_controller.value.isPlaying)
                            const Icon(Icons.play_arrow,
                                size: 64, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
