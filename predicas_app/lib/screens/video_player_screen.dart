import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String titulo;
  final String url;
  final String? fecha;
  final String? categoria;
  final List<String> versiculos;

  const VideoPlayerScreen({
    Key? key,
    required this.titulo,
    required this.url,
    this.fecha,
    this.categoria,
    this.versiculos = const [],
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;
  StreamSubscription<Duration>? _subPosicion;
  StreamSubscription<YoutubePlayerValue>? _subEstado;

  bool _urlValida = true;
  bool _listo = false;

  String? _videoId;
  double _ultimaPosicion = 0; // segundos

  // Se guarda por ID del video de YouTube (no por el id del JSON), así el
  // minuto sigue siendo válido aunque renumeres los ids de las prédicas.
  String get _clavePosicion => 'posicion_$_videoId';

  // Si el video se detuvo antes de este umbral no vale la pena "continuar".
  static const double _minimoParaReanudar = 5;

  @override
  void initState() {
    super.initState();

    _videoId = YoutubePlayerController.convertUrlToId(widget.url);

    if (_videoId == null) {
      // No se pudo extraer el ID del video desde la URL del JSON
      _urlValida = false;
      return;
    }

    _inicializar(_videoId!);
  }

  Future<void> _inicializar(String videoId) async {
    double inicio = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      inicio = prefs.getDouble(_clavePosicion) ?? 0;
    } catch (_) {
      // Si falla la lectura, simplemente empezamos desde el principio.
    }
    if (inicio < _minimoParaReanudar) inicio = 0;

    if (!mounted) return;

    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      startSeconds: inicio > 0 ? inicio : null,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true, // evita mostrar videos sugeridos de otros canales
      ),
    );

    _ultimaPosicion = inicio;

    // Guardado periódico mientras se reproduce (cada 5 s).
    _subPosicion = controller
        .getCurrentPositionStream(period: const Duration(seconds: 5))
        .listen((posicion) {
      final segundos = posicion.inSeconds.toDouble();
      if (segundos <= 0) return;
      _ultimaPosicion = segundos;
      _guardarPosicion(segundos);
    });

    // Guardado inmediato al pausar, y borrado del minuto al terminar el video.
    _subEstado = controller.listen((valor) {
      if (valor.playerState == PlayerState.paused) {
        _guardarPosicion(_ultimaPosicion);
      } else if (valor.playerState == PlayerState.ended) {
        _ultimaPosicion = 0;
        _borrarPosicion();
      }
    });

    setState(() {
      _controller = controller;
      _listo = true;
    });

    if (inicio > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Continuando desde ${_formatear(inicio)}'),
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }
  }

  Future<void> _guardarPosicion(double segundos) async {
    if (_videoId == null || segundos < _minimoParaReanudar) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_clavePosicion, segundos);
    } catch (_) {
      // El guardado del minuto es "best effort": nunca debe romper el reproductor.
    }
  }

  Future<void> _borrarPosicion() async {
    if (_videoId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clavePosicion);
    } catch (_) {}
  }

  String _formatear(double segundos) {
    final total = segundos.round();
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    String dos(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${dos(m)}:${dos(s)}' : '${dos(m)}:${dos(s)}';
  }

  @override
  void dispose() {
    // Último guardado al salir de la pantalla (antes de cerrar el controller,
    // porque después de close() el controller ignora cualquier llamada).
    if (_ultimaPosicion > 0) {
      _guardarPosicion(_ultimaPosicion);
    }
    _subPosicion?.cancel();
    _subEstado?.cancel();
    _controller?.close();
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

    // Mientras se lee el minuto guardado, mostramos un cargando breve.
    if (!_listo || _controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final detalles = [
      if (widget.fecha != null && widget.fecha!.isNotEmpty) widget.fecha!,
      if (widget.categoria != null && widget.categoria!.isNotEmpty) widget.categoria!,
    ].join(' · ');

    return YoutubePlayerScaffold(
      controller: _controller!,
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
          body: SingleChildScrollView(
            child: Column(
              children: [
                player,
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.titulo,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (detalles.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            detalles,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        // Versículos citados en la prédica (solo si hay alguno)
                        if (widget.versiculos.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(
                                Icons.menu_book,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Versículos',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.versiculos
                                .map((v) => Chip(label: Text(v)))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}