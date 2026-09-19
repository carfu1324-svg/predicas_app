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
    final colorTexto = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
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
      // Estructura simple: encabezado fijo (hero + buscador + chips)
      // arriba, y solo la lista de abajo hace scroll. Sin slivers.
      body: Column(
        children: [
          // ================= HERO: título + versículo =================
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              children: [
                Text(
                  'Prédicas',
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: colorPrimario,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _versiculo,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    height: 1.4,
                    color: colorTexto.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '— $_referenciaVersiculo',
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorPrimario,
                  ),
                ),
              ],
            ),
          ),

          // ================= BUSCADOR + CHIPS (siempre visibles) =================
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                if (_hayChipsActivos(provider)) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (provider.filtroActivo != PredicasProvider.filtroTodas)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              avatar: Icon(
                                provider.mostrarSoloFavoritos ? Icons.favorite : Icons.label,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: Text(
                                provider.mostrarSoloFavoritos
                                    ? 'Favoritos'
                                    : provider.categoriaSeleccionada ?? '',
                                style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              backgroundColor: colorPrimario,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              deleteIcon: const Icon(Icons.close, color: Colors.white, size: 16),
                              onDeleted: () => provider.seleccionarFiltro(PredicasProvider.filtroTodas),
                            ),
                          ),
                        if (provider.tieneFiltroFecha)
                          Chip(
                            avatar: const Icon(Icons.calendar_month, color: Colors.white, size: 16),
                            label: Text(
                              provider.etiquetaFecha ?? '',
                              style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                            backgroundColor: colorPrimario,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            deleteIcon: const Icon(Icons.close, color: Colors.white, size: 16),
                            onDeleted: () => provider.limpiarFiltroFecha(),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ================= LISTA DE PRÉDICAS (esto sí hace scroll) =================
          Expanded(
            child: provider.cargando
                ? const Center(child: CircularProgressIndicator())
                : provider.predicas.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No hay prédicas para este filtro.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100, top: 4),
                        itemCount: provider.predicas.length,
                        itemBuilder: (context, index) {
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

  // --- BOTTOM SHEET DE FILTROS (Todas / Favoritos / Categorías / Orden / Fecha) ---
  void _mostrarFiltros(BuildContext contextExterno, PredicasProvider provider) {
    showModalBottomSheet(
      context: contextExterno,
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
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
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

                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            'Ordenar por',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        _opcionOrden(
                          context: context,
                          provider: prov,
                          alfabetico: false,
                          icono: Icons.access_time,
                          texto: 'Más recientes primero',
                        ),
                        _opcionOrden(
                          context: context,
                          provider: prov,
                          alfabetico: true,
                          icono: Icons.sort_by_alpha,
                          texto: 'Alfabético (A-Z)',
                        ),

                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            'Fecha específica',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.calendar_month,
                            color: prov.tieneFiltroFecha
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[500],
                          ),
                          title: Text(
                            prov.tieneFiltroFecha
                                ? prov.etiquetaFecha ?? ''
                                : 'Elegir mes y año',
                            style: TextStyle(
                              fontWeight: prov.tieneFiltroFecha ? FontWeight.bold : FontWeight.normal,
                              color: prov.tieneFiltroFecha ? Theme.of(context).colorScheme.primary : null,
                            ),
                          ),
                          trailing: prov.tieneFiltroFecha
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Quitar filtro de fecha',
                                  onPressed: () => prov.limpiarFiltroFecha(),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(context);
                            _mostrarSelectorFecha(contextExterno, provider);
                          },
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

  Widget _opcionOrden({
    required BuildContext context,
    required PredicasProvider provider,
    required bool alfabetico,
    required IconData icono,
    required String texto,
  }) {
    final bool seleccionado = provider.ordenAlfabetico == alfabetico;
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
      onTap: () => provider.alternarOrdenAlfabetico(alfabetico),
    );
  }

  // --- SELECTOR DE MES Y AÑO ---
  void _mostrarSelectorFecha(BuildContext context, PredicasProvider provider) {
    if (provider.aniosDisponibles.isEmpty) return;

    int anioSel = provider.anioSeleccionado ?? provider.aniosDisponibles.first;
    int mesSel = provider.mesSeleccionado ?? 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtrar por fecha'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: anioSel,
                    decoration: const InputDecoration(labelText: 'Año'),
                    items: provider.aniosDisponibles
                        .map((a) => DropdownMenuItem(value: a, child: Text('$a')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => anioSel = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: mesSel,
                    decoration: const InputDecoration(labelText: 'Mes'),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(PredicasProvider.nombresMeses[m - 1]),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => mesSel = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    provider.seleccionarFecha(anioSel, mes: mesSel);
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _hayChipsActivos(PredicasProvider provider) {
    return provider.filtroActivo != PredicasProvider.filtroTodas || provider.tieneFiltroFecha;
  }
}