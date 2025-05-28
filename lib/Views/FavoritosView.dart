import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../FbObjects/FbPost.dart';
import '../Singletone/AppNavegacionUtiles.dart';
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favoritos", textAlign: TextAlign.center,),

        automaticallyImplyLeading: false,
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

          return SingleChildScrollView(
            child: Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,  // Esto asegura que el GridView no ocupe más espacio que el necesario
                  physics: NeverScrollableScrollPhysics(),  // Deshabilita el desplazamiento del GridView
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
                          AppNavigationUtils.onPostClicked(context, postSeleccionado);
                        },

                        child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (post['imagenURLpost'] != null && post['imagenURLpost'].isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: AspectRatio(
                                    aspectRatio: 1.5,
                                    child: CachedNetworkImage(
                                      imageUrl: post['imagenURLpost'][0],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.red),
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
                              SizedBox(height: 8),
                              Text(
                                post['titulo'] ?? "Sin título",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Categorías: ${post['categoria']?.join(', ') ?? 'Sin categorías'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Precio: ${post['precio']?.toString() ?? 'No disponible'} €',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )

              ],
            ),
          );
        },
      ),
    );
  }
}
