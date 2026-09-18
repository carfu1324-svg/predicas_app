import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'modo_oscuro';

  bool _modoOscuro = false;
  bool _cargado = false;

  bool get modoOscuro => _modoOscuro;
  ThemeMode get themeMode => _modoOscuro ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _cargarPreferencia();
  }

  Future<void> _cargarPreferencia() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getBool(_prefKey);

    if (guardado != null) {
      // El usuario ya eligió antes, respetamos su elección
      _modoOscuro = guardado;
    } else {
      // Primera vez: usamos el tema del sistema como punto de partida
      final brillo = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _modoOscuro = brillo == Brightness.dark;
    }

    _cargado = true;
    notifyListeners();
  }

  Future<void> alternarTema() async {
    _modoOscuro = !_modoOscuro;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _modoOscuro);
  }

  bool get cargado => _cargado;
}