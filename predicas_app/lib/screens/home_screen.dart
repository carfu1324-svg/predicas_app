import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Asegúrate de importar tus archivos correctamente
import '../providers/predicas_provider.dart'; 
//import '../models/predica.dart';

class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtenemos el provider para leer los datos
    final provider = Provider.of<PredicasProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prédicas'),
        actions: [
          // Botón para alternar entre todas o solo favoritas
          IconButton(
            icon: Icon(
              provider.mostrarSoloFavoritos ? Icons.favorite : Icons.favorite_border,
              color: provider.mostrarSoloFavoritos ? Colors.red : Colors.white,
            ),
            onPressed: () {
              provider.alternarVistaFavoritos(!provider.mostrarSoloFavoritos);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // BUSCADOR BÁSICO
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => provider.buscar(value),
              decoration: InputDecoration(
                labelText: 'Buscar por título...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          
          // LISTA DE PRÉDICAS
          Expanded(
            child: provider.cargando
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder( // Usamos ListView.builder para renderizar la lista eficientemente
                    itemCount: provider.predicas.length,
                    itemBuilder: (context, index) {
                      final predica = provider.predicas[index];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.play_circle_fill, color: Colors.red, size: 40),
                          title: Text(
                            predica.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(predica.fecha), // Mostramos la fecha
                          trailing: IconButton(
                            icon: Icon(
                              provider.esFavorito(predica.id) ? Icons.favorite : Icons.favorite_border,
                              color: provider.esFavorito(predica.id) ? Colors.red : Colors.grey,
                            ),
                            onPressed: () => provider.toggleFavorito(predica.id),
                          ),
                          // ACCIÓN: Redireccionar a YouTube al hacer clic
                          onTap: () => _abrirVideoEnYouTube(predica.url),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // Botón flotante para actualizar la lista desde internet
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool exito = await provider.recargarLista();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(exito ? 'Lista actualizada' : 'Error al actualizar')),
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // --- LÓGICA DE RESPALDO (FALLBACK) PARA ABRIR YOUTUBE ---
  Future<void> _abrirVideoEnYouTube(String urlVideo) async {
    final Uri url = Uri.parse(urlVideo);
    try {
      if (await canLaunchUrl(url)) {
        // Forzamos que se abra en la app externa de YouTube (o navegador)
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('No se pudo abrir el enlace: $urlVideo');
      }
    } catch (e) {
      debugPrint('Error lanzando URL: $e');
    }
  }
}