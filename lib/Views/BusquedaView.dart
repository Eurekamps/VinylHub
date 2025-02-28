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
  List<FbPost> _allPosts = [];
  List<FbPost> _filteredPosts = [];
  bool blListaPostsVisible = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('Posts').get();
      final posts = snapshot.docs.map((doc) => FbPost.fromFirestore(doc)).toList();
      setState(() {
        _allPosts = posts;
        _filteredPosts = posts;
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
        _filteredPosts = _allPosts;
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
      Navigator.of(context).pushNamed('/postdetailspropio');
    } else {
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
              _filterPosts(_controller.text);
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
              onChanged: _filterPosts,
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
                childAspectRatio: 0.8,
              ),
              itemCount: _filteredPosts.length,
              itemBuilder: (context, index) {
                FbPost post = _filteredPosts[index];

                return GestureDetector(
                  onTap: () => onPostItem_MasDatosClicked(context, post),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Imagen del post usando URL
                          if (post.imagenURLpost.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AspectRatio(
                                aspectRatio: 1.5,
                                child: Image.network(
                                  post.imagenURLpost[0], // Muestra la primera URL de imagen
                                  fit: BoxFit.cover,
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
                            post.titulo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
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
}
