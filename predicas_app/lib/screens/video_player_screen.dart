import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String titulo;
  final String url;

  const VideoPlayerScreen({
    Key? key,
    required this.titulo,
    required this.url,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final YoutubePlayerController _controller;
  bool _urlValida = true;

  @override
  void initState() {
    super.initState();

    final videoId = YoutubePlayerController.convertUrlToId(widget.url);

    if (videoId == null) {
      // No se pudo extraer el ID del video desde la URL del JSON
      _urlValida = false;
      _controller = YoutubePlayerController();
      return;
    }

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true, // evita mostrar videos sugeridos de otros canales
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Future<void> _abrirEnYouTube() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_urlValida) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.titulo)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                  'No se pudo cargar este video.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _abrirEnYouTube,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir en YouTube'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return YoutubePlayerScaffold(
      controller: _controller,
      aspectRatio: 16 / 9,
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Abrir en YouTube',
                onPressed: _abrirEnYouTube,
              ),
            ],
          ),
          body: Column(
            children: [
              player,
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}