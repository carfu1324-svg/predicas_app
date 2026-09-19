import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:developer'; 
import '../models/predica.dart'; // Asegúrate de que el nombre del archivo coincida

class PredicasProvider extends ChangeNotifier {
  // --- VARIABLES DE DATOS ---
  List<Predica> _predicasOriginales = []; 
  List<Predica> _predicasFiltradas = [];
  List<String> _idsFavoritos = [];
  
  bool _mostrarSoloFavoritos = false;
  bool _cargando = true;

  // --- CATEGORÍAS ---
  List<String> _categoriasDisponibles = [];
  String? _categoriaSeleccionada; // null = "Todas"

  // --- FILTRO POR FECHA (año/mes) ---
  List<int> _aniosDisponibles = [];
  int? _anioSeleccionado;
  int? _mesSeleccionado;

  static const List<String> nombresMeses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  // --- BÚSQUEDA ---
  String _queryBusqueda = '';

  // --- ORDEN (independiente del filtro: aplica sobre lo que esté visible) ---
  bool _ordenAlfabetico = false;

  // --- CONFIGURACIÓN DE ACTUALIZACIÓN ---
  static const String _urlGitHub = "https://gist.githubusercontent.com/carfu1324-svg/5a9ff6c40fec0c78ef673714152f4abf/raw/predicas.json";
  static const String _nombreArchivoLocal = "predicas_local_v1.json";

  // Getters
  List<Predica> get predicas => _predicasFiltradas;
  bool get cargando => _cargando;
  bool get mostrarSoloFavoritos => _mostrarSoloFavoritos;
  List<String> get categorias => _categoriasDisponibles;
  String? get categoriaSeleccionada => _categoriaSeleccionada;
  List<int> get aniosDisponibles => _aniosDisponibles;
  int? get anioSeleccionado => _anioSeleccionado;
  int? get mesSeleccionado => _mesSeleccionado;
  bool get tieneFiltroFecha => _anioSeleccionado != null;
  bool get ordenAlfabetico => _ordenAlfabetico;

  /// Etiqueta legible del filtro de fecha activo, o null si no hay ninguno.
  String? get etiquetaFecha {
    if (_anioSeleccionado == null) return null;
    if (_mesSeleccionado == null) return '$_anioSeleccionado';
    return '${nombresMeses[_mesSeleccionado! - 1]} $_anioSeleccionado';
  }

  /// Devuelve los meses (1-12) que sí tienen prédicas para el año dado.
  List<int> mesesConContenido(int anio) {
    final anioStr = anio.toString();
    return _predicasOriginales
        .where((p) => p.fecha.startsWith(anioStr))
        .map((p) => int.parse(p.fecha.substring(5, 7)))
        .toSet()
        .toList()
      ..sort();
  }

  PredicasProvider() {
    log("Inicializando Provider de Prédicas...", name: 'PredicasProvider');
    cargarDatosHibridos();
  }

  // ==========================================================
  //  FUNCIÓN PARA EL BOTÓN "ACTUALIZAR"
  // ==========================================================
  Future<bool> recargarLista() async {
    _cargando = true;
    notifyListeners(); 

    bool exito = await _buscarActualizacionesEnNube(aplicarCambiosVisuales: true);
    
    if (!exito) {
      _cargando = false;
      notifyListeners();
    }
    
    return exito; 
  }
  // ==========================================================

  // 1. EL CEREBRO DE CARGA
  Future<void> cargarDatosHibridos() async {
    await _cargarFavoritosGuardados();
    try {
      String jsonString;

      if (kIsWeb) {
        // En la web no existe "almacenamiento local de archivos" (path_provider
        // no aplica ahí), así que vamos directo a los assets empaquetados.
        log("Web: cargando prédicas desde Assets", name: 'PredicasProvider');
        jsonString = await rootBundle.loadString('assets/fonts/predicas.json');
      } else {
        final directorio = await getApplicationDocumentsDirectory();
        final archivoLocal = File('${directorio.path}/$_nombreArchivoLocal');

        if (await archivoLocal.exists()) {
          log("Cargando prédicas desde almacenamiento local", name: 'PredicasProvider');
          jsonString = await archivoLocal.readAsString();
        } else {
          log("Cargando prédicas desde Assets", name: 'PredicasProvider');
          jsonString = await rootBundle.loadString('assets/fonts/predicas.json');
        }
      }

      _procesarJson(jsonString);

      _buscarActualizacionesEnNube(aplicarCambiosVisuales: false);

    } catch (e) {
      log("Error crítico cargando datos", name: 'PredicasProvider', error: e);
      await _cargarDesdeAssetsEmergencia();
    }
  }

  // 2. PROCESAR JSON
  void _procesarJson(String jsonString) {
    try {
      final List<dynamic> datosList = json.decode(jsonString);
      _predicasOriginales = datosList.map((item) => Predica.fromJson(item)).toList();

      // Orden por defecto: de más reciente a más antigua.
      // El formato "YYYY-MM-DD" permite ordenar como texto sin convertir a DateTime.
      _predicasOriginales.sort((a, b) => b.fecha.compareTo(a.fecha));

      // Recalculamos las categorías disponibles a partir de la data nueva
      _categoriasDisponibles = _predicasOriginales
          .map((p) => p.categoria)
          .where((c) => c.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      // Si la categoría seleccionada ya no existe en la nueva data, la reseteamos
      if (_categoriaSeleccionada != null &&
          !_categoriasDisponibles.contains(_categoriaSeleccionada)) {
        _categoriaSeleccionada = null;
      }

      // Recalculamos los años disponibles (para el filtro de fecha)
      _aniosDisponibles = _predicasOriginales
          .map((p) => int.tryParse(p.fecha.substring(0, 4)) ?? 0)
          .where((a) => a != 0)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // más reciente primero

      if (_anioSeleccionado != null && !_aniosDisponibles.contains(_anioSeleccionado)) {
        _anioSeleccionado = null;
        _mesSeleccionado = null;
      }

      _aplicarFiltros();

      _cargando = false;
      notifyListeners();
    } catch (e) {
      log("Error procesando JSON", name: 'PredicasProvider', error: e);
    }
  }

  // 3. ACTUALIZACIÓN DESDE INTERNET (CON TRUCO ANTI-CACHÉ)
  Future<bool> _buscarActualizacionesEnNube({required bool aplicarCambiosVisuales}) async {
    try {
      log("Buscando actualizaciones en GitHub...", name: 'PredicasProvider');
      
      final String urlSinCache = "$_urlGitHub?v=${DateTime.now().millisecondsSinceEpoch}";
      
      final respuesta = await http.get(Uri.parse(urlSinCache));

      if (respuesta.statusCode == 200) {
        final contenidoNube = respuesta.body;
        json.decode(contenidoNube); 

        if (!kIsWeb) {
          // Guardar en disco solo tiene sentido fuera de la web
          final directorio = await getApplicationDocumentsDirectory();
          final archivoLocal = File('${directorio.path}/$_nombreArchivoLocal');
          await archivoLocal.writeAsString(contenidoNube);
        }
        log("¡Prédicas actualizadas y guardadas!", name: 'PredicasProvider');
        
        if (aplicarCambiosVisuales) {
           _procesarJson(contenidoNube);
        }
        
        return true; 
      } else {
        log("Error conectando con GitHub: ${respuesta.statusCode}", name: 'PredicasProvider');
        return false; 
      }
    } catch (e) {
      log("No se pudo actualizar (sin internet)", name: 'PredicasProvider');
      return false; 
    }
  }

  // Auxiliar de emergencia
  Future<void> _cargarDesdeAssetsEmergencia() async {
    final jsonString = await rootBundle.loadString('assets/fonts/predicas.json');
    _procesarJson(jsonString);
  }

  // ==========================================================
  //  MOTOR ÚNICO DE FILTRADO
  //  Combina: categoría + favoritos + búsqueda, siempre juntos.
  // ==========================================================
  void _aplicarFiltros() {
    Iterable<Predica> resultado = _predicasOriginales;

    if (_mostrarSoloFavoritos) {
      resultado = resultado.where((p) => _idsFavoritos.contains(p.id.toString()));
    }

    if (_categoriaSeleccionada != null) {
      resultado = resultado.where((p) => p.categoria == _categoriaSeleccionada);
    }

    if (_anioSeleccionado != null) {
      final anioStr = _anioSeleccionado.toString();
      resultado = resultado.where((p) => p.fecha.startsWith(anioStr));

      if (_mesSeleccionado != null) {
        final mesStr = _mesSeleccionado.toString().padLeft(2, '0');
        resultado = resultado.where((p) => p.fecha.substring(5, 7) == mesStr);
      }
    }

    if (_queryBusqueda.isNotEmpty) {
      final consulta = _queryBusqueda.toLowerCase();
      resultado = resultado.where((p) => p.titulo.toLowerCase().contains(consulta));
    }

    final lista = resultado.toList();

    // El orden alfabético se aplica encima de cualquier filtro/búsqueda activa.
    // Si está apagado, respetamos el orden base (por fecha, más reciente primero).
    if (_ordenAlfabetico) {
      lista.sort((a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()));
    }

    _predicasFiltradas = lista;
    notifyListeners();
  }

  // --- ORDEN ---
  void alternarOrdenAlfabetico(bool alfabetico) {
    _ordenAlfabetico = alfabetico;
    _aplicarFiltros();
  }

  // --- FILTRO DE FECHA ---
  void seleccionarFecha(int anio, {int? mes}) {
    _anioSeleccionado = anio;
    _mesSeleccionado = mes;
    _aplicarFiltros();
  }

  void limpiarFiltroFecha() {
    _anioSeleccionado = null;
    _mesSeleccionado = null;
    _aplicarFiltros();
  }

  // --- LÓGICA DE FILTRADO (TODAS / FAVORITAS) ---
  void alternarVistaFavoritos(bool verFavoritos) {
    _mostrarSoloFavoritos = verFavoritos;
    _aplicarFiltros();
  }

  // --- CATEGORÍAS ---
  void seleccionarCategoria(String? categoria) {
    // Pasar null selecciona "Todas"
    _categoriaSeleccionada = categoria;
    _aplicarFiltros();
  }

  // ==========================================================
  //  SELECTOR UNIFICADO: Todas / Favoritos / Categoría
  //  Se usan como mutuamente excluyentes en el bottom sheet.
  // ==========================================================
  static const String filtroTodas = '__todas__';
  static const String filtroFavoritos = '__favoritos__';

  /// Devuelve el identificador del filtro activo actualmente,
  /// para resaltar la opción correcta en el bottom sheet.
  String get filtroActivo {
    if (_mostrarSoloFavoritos) return filtroFavoritos;
    if (_categoriaSeleccionada != null) return _categoriaSeleccionada!;
    return filtroTodas;
  }

  void seleccionarFiltro(String filtro) {
    if (filtro == filtroTodas) {
      _categoriaSeleccionada = null;
      _mostrarSoloFavoritos = false;
    } else if (filtro == filtroFavoritos) {
      _categoriaSeleccionada = null;
      _mostrarSoloFavoritos = true;
    } else {
      _categoriaSeleccionada = filtro;
      _mostrarSoloFavoritos = false;
    }
    _aplicarFiltros();
  }

  // --- BUSCADOR ---
  void buscar(String query) {
    _queryBusqueda = query;
    _aplicarFiltros();
  }

  // --- LÓGICA DE FAVORITOS ---
  bool esFavorito(int id) {
    return _idsFavoritos.contains(id.toString());
  }

  Future<void> toggleFavorito(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final idStr = id.toString();

    if (_idsFavoritos.contains(idStr)) {
      _idsFavoritos.remove(idStr);
    } else {
      _idsFavoritos.add(idStr);
    }
    
    await prefs.setStringList('predicas_favoritas', _idsFavoritos);
    _aplicarFiltros();
  }

  Future<void> _cargarFavoritosGuardados() async {
    final prefs = await SharedPreferences.getInstance();
    _idsFavoritos = prefs.getStringList('predicas_favoritas') ?? [];
    notifyListeners();
  }
}