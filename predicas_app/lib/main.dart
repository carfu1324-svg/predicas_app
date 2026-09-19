import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Asegúrate de que las rutas coincidan con los nombres de tus carpetas y archivos
import 'providers/predicas_provider.dart'; 
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart'; // Asumiendo que guardaste la pantalla aquí

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    // Envolvemos la app en un MultiProvider por si a futuro agregas más providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PredicasProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MiAppDePredicas(),
    ),
  );
}

class MiAppDePredicas extends StatelessWidget {
  const MiAppDePredicas({Key? key}) : super(key: key);

  // Color base de tu marca. Cámbialo aquí y se propaga a toda la app.
  static const Color _colorMarca = Color(0xFF1775CE);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Prédicas App',
      debugShowCheckedModeBanner: false, // Quita la cinta roja de "DEBUG" en la esquina

      // --- TEMA CLARO ---
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _colorMarca,
          brightness: Brightness.light,
        ),
        // Nunito como fuente base para toda la app (listas, botones, menús)
        textTheme: GoogleFonts.nunitoTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: _colorMarca,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      // --- TEMA OSCURO ---
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _colorMarca,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF102A43), // azul muy oscuro, coherente con la marca
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),

      // Ahora el modo lo controla el botón en la app (con persistencia)
      themeMode: themeProvider.themeMode,

      // Le decimos que arranque directamente en tu pantalla principal
      home: const PantallaPrincipal(), 
    );
  }
}