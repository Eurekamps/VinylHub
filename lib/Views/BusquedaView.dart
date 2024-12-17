import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../FbObjects/FbPost.dart';
import '../Singletone/DataHolder.dart';

class BusquedaView extends StatefulWidget {
  @override
  _BusquedaViewState createState() => _BusquedaViewState();
}

class _BusquedaViewState extends State<BusquedaView> {
  final TextEditingController _controller = TextEditingController();
  List<FbPost> _allPosts = [];  //almacena todos los post
  List<FbPost> _filteredPosts = [];  //almacena los post filtrados
  bool blListaPostsVisible = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  // Método para obtener los posts de Firestore.
  void _loadPosts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('Posts').get();
      final posts = snapshot.docs.map((doc) => FbPost.fromFirestore(doc)).toList();
      setState(() {
        _allPosts = posts;
        _filteredPosts = posts; //se muestran todos los post al principio
      });
    } catch (e) {
      print('Error al cargar los posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los posts: $e')),
      );
    }
  }


  void _filterPosts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPosts = _allPosts;  //Si no hay texto de busqueda, se muestran todos los post
      });
    } else {
      setState(() {
        _filteredPosts = _allPosts.where((post) {
          final lowerQuery = query.toLowerCase();
          return post.titulo.toLowerCase().contains(lowerQuery) ||
              post.descripcion.toLowerCase().contains(lowerQuery) ||
              post.categoria.any((cat) => cat.toLowerCase().contains(lowerQuery));
        }).toList();
      });
    }
  }

  void onPostItem_MasDatosClicked(BuildContext context, FbPost postSeleccionado) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    DataHolder().fbPostSelected = postSeleccionado;

    if (postSeleccionado.sAutorUid == currentUserUid) {
      // Si el post es del usuario logueado, navegar a la pantalla de edición
      Navigator.of(context).pushNamed('/postdetailspropio');
    } else {
      // Si el post no es del usuario logueado, navegar a la pantalla de detalles
      Navigator.of(context).pushNamed('/postdetails');
    }

    setState(() {
      blListaPostsVisible = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar Posts'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _filterPosts(_controller.text);  // Llamamos a la función de búsqueda al presionar el botón.
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Buscar por título, descripción o categoría...',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: _filterPosts,  // Llamamos a _filterPosts cuando el texto cambia.
            ),
          ),
          Expanded(
            child: _filteredPosts.isEmpty
                ? Center(child: Text('No se encontraron posts.'))
                : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.8, // Ajusta la proporción para tarjetas verticales
              ),
              itemCount: _filteredPosts.length,
              itemBuilder: (context, index) {
                FbPost post = _filteredPosts[index];

                return GestureDetector(
                  onTap: () => onPostItem_MasDatosClicked(context, post),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Bordes redondeados
                    ),
                    elevation: 4, // Sombra para diseño más llamativo
                    child: Padding(
                      padding: const EdgeInsets.all(8.0), // Espaciado interno
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // Centrar contenido horizontalmente
                        children: [
                          if (post.imagenURLpost.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10), // Redondea la imagen
                              child: AspectRatio(
                                aspectRatio: 1.5, // Relación de aspecto fija (ancho/alto)
                                child: Image.memory(
                                  base64Decode(_limpiarBase64(post.imagenURLpost.first)),
                                  fit: BoxFit.contain, // Muestra toda la imagen dentro del área sin recortarla
                                ),
                              ),
                            )
                          else
                            AspectRatio(
                              aspectRatio: 1.5, // Relación de aspecto para imágenes no disponibles
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          SizedBox(height: 8), // Espaciado entre la imagen y el título
                          Text(
                            post.titulo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4), // Espaciado entre el título y la categoría
                          Text(
                            'Categorías: ${post.categoria.join(', ')}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Precio: ${post.precio.toString()} €',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  String _limpiarBase64(String base64String) {
    return base64String.replaceAll("data:image/png;base64,", "").replaceAll("data:image/jpeg;base64,", "");
  }
}
