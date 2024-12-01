import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../FbObjects/FbPost.dart';
import 'MiDrawer1.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;
  bool _isGridView = false; //controla si la vista es en grid o lista

  //funcion de tocar un item
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Actualiza el índice seleccionado
    });
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _imagenController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();

  // Inserta nueva Post en la db
  Future<void> _agregarPost() async {
    String titulo = _tituloController.text;
    String descripcion = _descripcionController.text;
    int precio = _precioController.text as int;
    String imagen = _imagenController.text;
    String categoria = _categoriaController.text;

    if (titulo.isNotEmpty && descripcion.isNotEmpty) {
      FbPost nuevaPost = FbPost(
        titulo: titulo,
        descripcion: descripcion,
        precio: precio,
        imagenURLpost: imagen,
        categoria: categoria,
      );

      await _firestore.collection('Posts').add(nuevaPost.toMap());
      // Limpiar los campos después de agregar la Post
      _tituloController.clear();
      _descripcionController.clear();
      _precioController.clear();
      _imagenController.clear();
      _categoriaController.clear();
    }
  }

  // Pantalla 1: Lista de Posts
  Widget _buildListScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Posts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var Posts = snapshot.data!.docs.map((doc) {
          return FbPost.fromFirestore(doc);
        }).toList();

        return ListView.builder(
          itemCount: Posts.length,
          itemBuilder: (context, index) {
            FbPost Post = Posts[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(Post.titulo),
                subtitle: Text(Post.categoria),
                onTap: () {
                  // Acción al seleccionar una Post
                },
              ),
            );
          },
        );
      },
    );
  }

  // Pantalla 2: GridView de Posts
  Widget _buildGridScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Posts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var Posts = snapshot.data!.docs.map((doc) {
          return FbPost.fromFirestore(doc);
        }).toList();

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: Posts.length,
          itemBuilder: (context, index) {
            FbPost Post = Posts[index];
            return Card(
              color: Colors.brown[200],
              child: Center(
                child: Text(Post.titulo, style: TextStyle(color: Colors.white)),
              ),
            );
          },
        );
      },
    );
  }

  // Pantalla 3: Crear Post
  Widget _buildCreateStoreScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _tituloController,
            decoration: InputDecoration(labelText: 'titulo de la Post'),
          ),
          TextField(
            controller: _descripcionController,
            decoration: InputDecoration(labelText: 'Descripción'),
          ),
          TextField(
            controller: _precioController,
            decoration: InputDecoration(labelText: 'Ubicación'),
          ),
          TextField(
            controller: _imagenController,
            decoration: InputDecoration(labelText: 'imageno'),
          ),
          TextField(
            controller: _categoriaController,
            decoration: InputDecoration(labelText: 'Categoría'),
          ),
          ElevatedButton(
            onPressed: _agregarPost,
            child: Text('Crear Post'),
          ),
        ],
      ),
    );
  }

  void _cerrarSesion() async {
    try {
      await FirebaseAuth.instance.signOut(); // Cierra la sesión del usuario
      // Redirige al usuario a la pantalla de login
      Navigator.of(context).pushNamed('/loginview'); // Ejemplo de redirección
    } catch (e) {
      print("Error al cerrar sesión: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi App"),
        backgroundColor: Colors.brown,
        actions: [
          // Botón de cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion, // Llama a la función _cerrarSesion
          ),
          // Botón de notificaciones
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {}, // Acción del botón de notificaciones
          ),
          // Botón de cambiar vista
          PopupMenuButton<int>(
            onSelected: (int value) {
              if (value == 1) {
                setState(() {
                  _isGridView = !_isGridView; // Alterna entre lista y grid
                });
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(
                value: 1,
                child: Text('Cambiar Vista'),
              ),
            ],
          ),
          SizedBox(width: 20), // Espaciado entre los botones
        ],
      ),
      drawer: MiDrawer1(), // El drawer ya no necesita la función onCerrarSesion
      body: _selectedIndex == 0
          ? (_isGridView ? _buildGridScreen() : _buildListScreen()) // Cambia entre lista y grid
          : _selectedIndex == 1
          ? _buildCreateStoreScreen() // Pantalla para crear una nueva Post
          : Container(), // Placeholder para otras vistas
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Llamada a la función _onItemTapped
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_business),
            label: 'Crear Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
        ],
      ),
    );
  }
}
