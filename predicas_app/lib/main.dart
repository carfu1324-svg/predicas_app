import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Asegúrate de que las rutas coincidan con los nombres de tus carpetas y archivos
import 'providers/predicas_provider.dart'; 
import 'screens/home_screen.dart'; // Asumiendo que guardaste la pantalla aquí

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    // Envolvemos la app en un MultiProvider por si a futuro agregas más providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PredicasProvider()),
      ],
      child: const MiAppDePredicas(),
    ),
  );
}

class MiAppDePredicas extends StatelessWidget {
  const MiAppDePredicas({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prédicas App',
      debugShowCheckedModeBanner: false, // Quita la cinta roja de "DEBUG" en la esquina
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red, // Un color rojo estilo YouTube
          brightness: Brightness.light, // Puedes cambiar a Brightness.dark si prefieres modo oscuro
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white, // Color del texto y botones en la barra superior
          centerTitle: true,
        ),
      ),
      // Le decimos que arranque directamente en tu pantalla principal
      home: const PantallaPrincipal(), 
    );
  }
}