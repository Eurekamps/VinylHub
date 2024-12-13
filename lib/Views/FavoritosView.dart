import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import '../FbObjects/FbPost.dart';
import '../Singletone/DataHolder.dart'; // Para decodificar base64

class FavoritosView extends StatefulWidget {
  @override
  _FavoritosViewState createState() => _FavoritosViewState();
}

class _FavoritosViewState extends State<FavoritosView> {
  late Future<List<DocumentSnapshot>> _favoritosPostsFuture;
  bool blListaPostsVisible = true;

  @override
  void initState() {
    super.initState();
    _favoritosPostsFuture = _cargarPostsFavoritos();
  }

  Future<List<DocumentSnapshot>> _cargarPostsFavoritos() async {
    // Paso 1: Obtener UID de favoritos
    List<String> uidFavoritos = await obtenerFavoritos();

    // Paso 2: Obtener los posts correspondientes
    return await obtenerPostsFavoritos(uidFavoritos);
  }

  Future<List<String>> obtenerFavoritos() async {
    String uidUsuario = FirebaseAuth.instance.currentUser!.uid;
    final favoritosRef = FirebaseFirestore.instance
        .collection('perfiles')
        .doc(uidUsuario)
        .collection('Favoritos');

    final favoritosSnapshot = await favoritosRef.get();
    return favoritosSnapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<DocumentSnapshot>> obtenerPostsFavoritos(List<String> uidPosts) async {
    if (uidPosts.isEmpty) return [];

    final postsRef = FirebaseFirestore.instance.collection('Posts');
    final query = await postsRef.where(FieldPath.documentId, whereIn: uidPosts).get();

    return query.docs;
  }

  String _limpiarBase64(String base64String) {
    if (base64String.startsWith('data:image')) {
      final index = base64String.indexOf('base64,');
      if (index != -1) {
        return base64String.substring(index + 7);
      }
    }
    return base64String;
  }

  void onPostItem_MasDatosClicked(BuildContext context, FbPost postSeleccionado){
    DataHolder().fbPostSelected=postSeleccionado;
    Navigator.of(context).pushNamed('/postdetails');
    setState(() {
      blListaPostsVisible=false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favoritos"),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _favoritosPostsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error al cargar favoritos."));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No tienes favoritos aún."));
          }

          final posts = snapshot.data!;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Número de columnas
              crossAxisSpacing: 8.0, // Espacio entre columnas
              mainAxisSpacing: 8.0, // Espacio entre filas
              childAspectRatio: 0.8, // Proporción de cada elemento en el grid
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  FbPost postSeleccionado = FbPost.fromFirestore(posts[index]);

                  // Llama a la función onPostItem_MasDatosClicked con el post convertido
                  onPostItem_MasDatosClicked(context, postSeleccionado);
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Bordes redondeados
                  ),
                  elevation: 4, // Sombra para diseño más llamativo
                  child: Padding(
                    padding: const EdgeInsets.all(8.0), // Espaciado interno
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, // Centrar contenido
                      children: [
                        // Imagen del post usando base64
                        if (post['imagenURLpost'] != null && post['imagenURLpost'].isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10), // Redondea la imagen
                            child: AspectRatio(
                              aspectRatio: 1.5, // Relación de aspecto
                              child: Image.memory(
                                base64Decode(_limpiarBase64(post['imagenURLpost'][0])), // Decodificando la imagen base64
                                fit: BoxFit.cover, // Muestra la imagen sin recortarla
                              ),
                            ),
                          )
                        else
                          AspectRatio(
                            aspectRatio: 1.5,
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
                          post['titulo'] ?? "Sin título",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4), // Espaciado entre el título y la categoría
                        Text(
                          'Categorías: ${post['categoria']?.join(', ') ?? 'Sin categorías'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Precio: ${post['precio']?.toString() ?? 'No disponible'} €',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
