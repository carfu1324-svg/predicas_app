import 'dart:convert';
import 'dart:io';
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
  
  bool _mostrarSoloFavoritos = false; // Reemplaza la antigua lógica de categorías
  bool _cargando = true;

  // --- CONFIGURACIÓN DE ACTUALIZACIÓN ---
  // IMPORTANTE: Aquí pondrás el enlace "Raw" de tu archivo JSON cuando lo subas a GitHub
  static const String _urlGitHub = "https://gist.githubusercontent.com/carfu1324-svg/5a9ff6c40fec0c78ef673714152f4abf/raw/predicas.json";
  static const String _nombreArchivoLocal = "predicas_local_v1.json";

  // Getters
  List<Predica> get predicas => _predicasFiltradas;
  bool get cargando => _cargando;
  bool get mostrarSoloFavoritos => _mostrarSoloFavoritos;

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
      final directorio = await getApplicationDocumentsDirectory();
      final archivoLocal = File('${directorio.path}/$_nombreArchivoLocal');

      String jsonString;

      // PASO A: ¿Existe una versión descargada en el celular?
      if (await archivoLocal.exists()) {
        log("Cargando prédicas desde almacenamiento local", name: 'PredicasProvider');
        jsonString = await archivoLocal.readAsString();
      } else {
        // PASO B: No existe, usamos la de fábrica
        log("Cargando prédicas desde Assets", name: 'PredicasProvider');
        jsonString = await rootBundle.loadString('assets/predicas_final.json');
      }

      // Procesamos los datos
      _procesarJson(jsonString);

      // PASO C: (Silencioso) Buscar actualizaciones en internet
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
      
      // Filtrado inicial (mostrar todas o solo favoritas)
      alternarVistaFavoritos(_mostrarSoloFavoritos);

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

        // VERIFICACIÓN DE SEGURIDAD
        json.decode(contenidoNube); 

        // Guardar en disco
        final directorio = await getApplicationDocumentsDirectory();
        final archivoLocal = File('${directorio.path}/$_nombreArchivoLocal');
        await archivoLocal.writeAsString(contenidoNube);
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

  // --- LÓGICA DE FILTRADO (TODAS / FAVORITAS) ---
  void alternarVistaFavoritos(bool verFavoritos) {
    _mostrarSoloFavoritos = verFavoritos;
    if (_mostrarSoloFavoritos) {
      _predicasFiltradas = _predicasOriginales
          .where((p) => _idsFavoritos.contains(p.id.toString()))
          .toList();
    } else {
      _predicasFiltradas = List.from(_predicasOriginales);
    }
    notifyListeners();
  }

  // --- BUSCADOR ---
  void buscar(String query) {
    List<Predica> baseDeBusqueda = _mostrarSoloFavoritos 
        ? _predicasOriginales.where((p) => _idsFavoritos.contains(p.id.toString())).toList()
        : _predicasOriginales;

    if (query.isEmpty) {
      _predicasFiltradas = baseDeBusqueda;
      notifyListeners();
      return;
    }

    final consulta = query.toLowerCase();
    
    // Ahora el buscador filtra por el título de la prédica y por el predicador
    _predicasFiltradas = baseDeBusqueda.where((predica) {
      final coincideTitulo = predica.titulo.toLowerCase().contains(consulta);
      return coincideTitulo;
    }).toList();

    notifyListeners();
  }

  // --- LÓGICA DE FAVORITOS ---
  // Nota: El ID llega como entero, lo convertimos a String para compararlo
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
    
    // Si estamos viendo solo favoritos y quitamos uno, lo removemos visualmente
    if (_mostrarSoloFavoritos) {
      alternarVistaFavoritos(true);
    }
    notifyListeners();
  }

  Future<void> _cargarFavoritosGuardados() async {
    final prefs = await SharedPreferences.getInstance();
    _idsFavoritos = prefs.getStringList('predicas_favoritas') ?? [];
    notifyListeners();
  }
}