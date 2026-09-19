import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Asegúrate de importar tus archivos correctamente
import '../providers/predicas_provider.dart'; 
import '../providers/theme_provider.dart';
import 'video_player_screen.dart';
//import '../models/predica.dart';

class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({Key? key}) : super(key: key);

  // ==========================================================
  //  VERSÍCULO DEL ENCABEZADO — cámbialo aquí cuando quieras
  // ==========================================================
  static const String _versiculo =
      '"Porque yo sé los pensamientos que tengo acerca de vosotros, dice '
      'Jehová, pensamientos de paz, y no de mal, para daros el fin que '
      'esperáis."';
  static const String _referenciaVersiculo = 'Jeremías 29:11';

  @override
  Widget build(BuildContext context) {
    // Obtenemos el provider para leer los datos
    final provider = Provider.of<PredicasProvider>(context);
    final colorPrimario = Theme.of(context).colorScheme.primary;
    final alturaPantalla = MediaQuery.of(context).size.height;
    final colorTexto = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().modoOscuro
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: colorTexto,
            ),
            tooltip: 'Cambiar tema',
            onPressed: () => context.read<ThemeProvider>().alternarTema(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ================= ENCABEZADO =================
          // Título + versículo + buscador. Empieza a ~10% de la altura
          // de pantalla para que el buscador caiga cerca del centro.
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, alturaPantalla * 0.08, 24, 24),
                child: Column(
                  children: [
                    Text(
                      'Prédicas',
                      style: GoogleFonts.nunito(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: colorPrimario,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _versiculo,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                        height: 1.5,
                        color: colorTexto.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '— $_referenciaVersiculo',
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorPrimario,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // BUSCADOR
                    TextField(
                      onChanged: (value) => provider.buscar(value),
                      style: GoogleFonts.nunito(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                        labelText: 'Buscar por título...',
                        labelStyle: GoogleFonts.nunito(),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    // Chip indicando el filtro activo (si no es "Todas")
                    if (provider.filtroActivo != PredicasProvider.filtroTodas) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          avatar: Icon(
                            provider.mostrarSoloFavoritos ? Icons.favorite : Icons.label,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            provider.mostrarSoloFavoritos
                                ? 'Favoritos'
                                : provider.categoriaSeleccionada ?? '',
                            style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: colorPrimario,
                          deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
                          onDeleted: () => provider.seleccionarFiltro(PredicasProvider.filtroTodas),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ================= LISTA DE PRÉDICAS =================
          if (provider.cargando)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.predicas.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No hay prédicas para este filtro.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100, top: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final predica = provider.predicas[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(Icons.play_circle_fill, color: colorPrimario, size: 40),
                        title: Text(
                          predica.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${predica.fecha} · ${predica.categoria}',
                          style: GoogleFonts.nunito(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            provider.esFavorito(predica.id) ? Icons.favorite : Icons.favorite_border,
                            color: provider.esFavorito(predica.id) ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => provider.toggleFavorito(predica.id),
                        ),
                        // ACCIÓN: Abrir el reproductor in-app
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlayerScreen(
                              titulo: predica.titulo,
                              url: predica.url,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: provider.predicas.length,
                ),
              ),
            ),
        ],
      ),
      // Dos botones flotantes: filtrar por categoría y actualizar lista
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'fab_categorias',
            onPressed: () => _mostrarFiltros(context, provider),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: colorPrimario,
            child: const Icon(Icons.category),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'fab_refresh',
            onPressed: () async {
              bool exito = await provider.recargarLista();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(exito ? 'Lista actualizada' : 'Error al actualizar')),
              );
            },
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM SHEET DE FILTROS (Todas / Favoritos / Categorías) ---
  void _mostrarFiltros(BuildContext context, PredicasProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Usamos Consumer para que el sheet se actualice al elegir una opción
        return Consumer<PredicasProvider>(
          builder: (context, prov, _) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Filtrar por',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        _opcionFiltro(
                          context: context,
                          provider: prov,
                          valor: PredicasProvider.filtroTodas,
                          icono: Icons.list,
                          texto: 'Todas',
                        ),
                        _opcionFiltro(
                          context: context,
                          provider: prov,
                          valor: PredicasProvider.filtroFavoritos,
                          icono: Icons.favorite,
                          texto: 'Favoritos',
                        ),
                        if (prov.categorias.isNotEmpty) const Divider(),
                        ...prov.categorias.map(
                          (categoria) => _opcionFiltro(
                            context: context,
                            provider: prov,
                            valor: categoria,
                            icono: Icons.label_outline,
                            texto: categoria,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _opcionFiltro({
    required BuildContext context,
    required PredicasProvider provider,
    required String valor,
    required IconData icono,
    required String texto,
  }) {
    final bool seleccionado = provider.filtroActivo == valor;
    final colorPrimario = Theme.of(context).colorScheme.primary;
    final colorTexto = Theme.of(context).textTheme.bodyLarge?.color;
    return ListTile(
      leading: Icon(icono, color: seleccionado ? colorPrimario : Colors.grey[500]),
      title: Text(
        texto,
        style: TextStyle(
          fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
          color: seleccionado ? colorPrimario : colorTexto,
        ),
      ),
      trailing: seleccionado ? Icon(Icons.check, color: colorPrimario) : null,
      onTap: () {
        provider.seleccionarFiltro(valor);
        Navigator.pop(context);
      },
    );
  }

}