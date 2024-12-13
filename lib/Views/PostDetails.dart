import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hijos_de_fluttarkia/FbObjects/FbChat.dart';

import '../FbObjects/FbFavorito.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    _checkIfFavorito(); // Verificar si el post ya es favorito al cargar
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
        title: Text(post.titulo),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context); // Cerrar la pantalla de detalles
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Carrusel de imágenes
              if (images.isNotEmpty)
                Container(
                  height: 300, // Altura fija para las imágenes
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            currentIndex = index;
                          });
                        },
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            images[index],
                            fit: BoxFit.contain,
                            width: double.infinity,
                          );
                        },
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
              Text(
                post.titulo,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                post.descripcion ?? "Sin descripción",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: crearNuevoChat,
                    icon: const Icon(Icons.chat),
                    label: Text("Chat"),
                  ),
                  ElevatedButton.icon(
                    onPressed: addPostFavoritos,
                    icon: Icon(
                      _isFavorito ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorito ? Colors.red : null,
                    ),
                    label: Text(_isFavorito ? "Favorito" : "Añadir Favoritos"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
