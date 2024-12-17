import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hijos_de_fluttarkia/Apps/MyApp.dart';

import 'firebase_options.dart';
import 'search_vinyl_page.dart'; // Importa la pantalla de búsqueda de vinilos

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(AppWithNavigation());
}

class AppWithNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hijos de Fluttarkia', // Cambia el título si lo deseas
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(), // Pantalla principal con navegación
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hijos de Fluttarkia'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navega a la funcionalidad de MyApp
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp()),
                );
              },
              child: Text('Ir a MyApp'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navega a la pantalla de búsqueda de vinilos
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchVinylPage()),
                );
              },
              child: Text('Buscar Vinilos'),
            ),
          ],
        ),
      ),
    );
  }
}

