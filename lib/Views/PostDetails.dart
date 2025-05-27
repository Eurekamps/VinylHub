import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vinylhub/FbObjects/FbChat.dart';
import 'package:share_plus/share_plus.dart';

import '../FbObjects/FbFavorito.dart';
import '../FbObjects/FbPerfil.dart';
import '../Singletone/DataHolder.dart';
import 'ChatView.dart';

class PostDetails extends StatefulWidget {
  final Function() onClose;

  PostDetails({super.key, required this.onClose});

  @override
  State<PostDetails> createState() => _PostDetailsState();
}

class _PostDetailsState extends State<PostDetails> {
  int currentIndex = 0; // Índice de la imagen actual
  late PageController _pageController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String sRutaPerfil =
      "perfiles/${FirebaseAuth.instance.currentUser!.uid}/Favoritos";
  bool _isFavorito = false;
  FbPerfil? perfilAutor;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    _checkIfFavorito(); // Verificar si el post ya es favorito al cargar
    _cargarPerfilAutor();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (currentIndex < DataHolder().fbPostSelected!.imagenURLpost.length - 1) {
      setState(() {
        currentIndex++;
      });
      _pageController.animateToPage(
        currentIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      _pageController.animateToPage(
        currentIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void crearNuevoChat() async {
    String uidPost = DataHolder().fbPostSelected!.uid;
    String sPostAutorUid = DataHolder().fbPostSelected!.sAutorUid;
    String sAutorUid = FirebaseAuth.instance.currentUser!.uid;

    // Busca si ya existe un chat entre el usuario actual y el creador del post
    var chatQuery = await _firestore
        .collection('Chats')
        .where('uidPost', isEqualTo: uidPost) // Filtra por el post actual
        .where('sPostAutorUid', isEqualTo: sPostAutorUid) // Filtra por el vendedor
        .where('sAutorUid', isEqualTo: sAutorUid) // Filtra por el comprador (usuario actual)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      // Si el chat ya existe, accede a él
      var chatDoc = chatQuery.docs.first;
      DataHolder().fbChatSelected = FbChat.fromFirestore(chatDoc, null);
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ChatView())
      );
    } else {
      // Si no existe un chat, crea uno nuevo
      String uid = FirebaseFirestore.instance.collection('Chats').doc().id;
      String titulo = DataHolder().fbPostSelected!.titulo;
      String imagenChat = DataHolder().fbPostSelected!.imagenURLpost[0];

      FbChat nuevoChat = FbChat(
        uid: uid,
        sTitulo: titulo,
        sImagenURL: imagenChat,
        sAutorUid: sAutorUid,
        tmCreacion: Timestamp.now(),
        uidPost: uidPost,
        sPostAutorUid: sPostAutorUid,
      );

      // Guarda el nuevo chat en Firestore
      await _firestore.collection('Chats').doc(uid).set(nuevoChat.toFirestore());

      // Navega al nuevo chat
      DataHolder().fbChatSelected = nuevoChat;
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ChatView())
      );
    }
  }

  Future<void> _checkIfFavorito() async {
    // Identificar el ID del post y el usuario
    String uidPostFavorito = DataHolder().fbPostSelected!.uid;
    String uidUsuario = FirebaseAuth.instance.currentUser!.uid;

    final favoritosRef = _firestore
        .collection("perfiles")
        .doc(uidUsuario)
        .collection("Favoritos");

    try {
      final favoritoSnapshot = await favoritosRef.doc(uidPostFavorito).get();
      if (favoritoSnapshot.exists) {
        setState(() {
          _isFavorito = true; // El post ya es favorito
        });
      }
    } catch (e) {
      print("Error al verificar favoritos: $e");
    }
  }

  void _cargarPerfilAutor() async {
    try {
      String uidAutor = DataHolder().fbPostSelected!.sAutorUid;
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore.instance
          .collection('perfiles')
          .doc(uidAutor)
          .get();

      if (doc.exists) {
        setState(() {
          perfilAutor = FbPerfil.fromFirestore(doc, null);
        });
      } else {
        print("Perfil del autor no encontrado.");
      }
    } catch (e) {
      print("Error al obtener el perfil del autor: $e");
    }
  }


  Future<void> addPostFavoritos() async {
    String uidPostFavorito = DataHolder().fbPostSelected!.uid;
    FbFavorito nuevoFavorito = FbFavorito(uidPost: uidPostFavorito);
    String uidUsuario = FirebaseAuth.instance.currentUser!.uid;

    final favoritosRef = _firestore //subcoleccion favs en perfiles
        .collection("perfiles")
        .doc(uidUsuario)
        .collection("Favoritos");

    //cambia el estado de favorito o no favorito para el visual
    setState(() {
      _isFavorito = !_isFavorito;
    });

    try {
      final favoritoSnapshot = await favoritosRef.doc(uidPostFavorito).get();

      if (!favoritoSnapshot.exists) {
        //comprueba si existe el id en favoritos
        await favoritosRef.doc(uidPostFavorito).set(nuevoFavorito.toFirestore());
        //añadir favs
        print("Post añadido a favoritos.");
      } else {
        await favoritosRef.doc(uidPostFavorito).delete(); //eliminar de favs
        print("Post eliminado de favoritos.");
      }
    } catch (e) {
      print("Error al gestionar favoritos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var post = DataHolder().fbPostSelected!;
    var images = post.imagenURLpost;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/perfilajeno',
              arguments: DataHolder().fbPostSelected!.sAutorUid,
            );
          },
          child: Row(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: perfilAutor?.imagenURL ?? '',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
              SizedBox(width: 10),
              Text(
                perfilAutor?.nombre ?? 'Usuario',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),

        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.share(
                "📀 ${post.titulo}\n💰 ${post.precio} €\n📖 ${post.descripcion ?? "Sin descripción"}",
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (images.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.all(8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 300,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                currentIndex = index;
                              });
                            },
                            itemCount: images.length,
                            itemBuilder: (context, index) {
                              return CachedNetworkImage(
                                imageUrl: images[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.red),
                              );
                            },
                          ),

                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 130,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, size: 30, color: Colors.black),
                          onPressed: currentIndex > 0 ? _previousImage : null,
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 130,
                        child: IconButton(
                          icon: Icon(Icons.arrow_forward, size: 30, color: Colors.black),
                          onPressed: currentIndex < images.length - 1 ? _nextImage : null,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 16),

              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Text(
                  post.titulo,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16),

              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Text(
                  post.descripcion ?? "Sin descripción",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16),

              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Text(
                  "${post.precio} €",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700]),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: crearNuevoChat,
                    icon: Icon(Icons.chat, color: Colors.white),
                    label: Text("Chat", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: addPostFavoritos,
                    icon: Icon(
                      _isFavorito ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isFavorito ? "Eliminar" : "Añadir",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFavorito ? Colors.red : Colors.grey,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SizedBox(width: 16),
                ],
              ),
            ],
          ),
        ),
      ),
      // Botón de comprar fijo abajo
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12, width: 1)), // Línea superior para separar
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            // Acción al presionar el botón de comprar
          },
          icon: Icon(Icons.shopping_cart),
          label: Text("Comprar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

}
