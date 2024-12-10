import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hijos_de_fluttarkia/FbObjects/FbChat.dart';

import '../Singletone/DataHolder.dart';
import 'ChatView.dart';

class PostDetails extends StatefulWidget{

  final Function() onClose;

  PostDetails({super.key,required this.onClose});

  @override
  State<PostDetails> createState() => _PostDetailsState();
}

class _PostDetailsState extends State<PostDetails> {
  int currentIndex = 0; // Índice de la imagen actual
  late PageController _pageController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
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
    String? uidPost = DataHolder().fbPostSelected!.uid;
    var chatQuery = await _firestore
        .collection('Chats')
        .where('uidPost', isEqualTo: uidPost)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) { //si esxiste el chat, actualiza el fbchatselected
      var chatDoc = chatQuery.docs.first;
      DataHolder().fbChatSelected = FbChat.fromFirestore(chatDoc, null);

      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ChatView()));
    } else {
      //Si ese chat no existe, creara uno nuevo
      String uid = FirebaseFirestore.instance.collection('Chats').doc().id;
      String titulo = DataHolder().fbPostSelected!.titulo;
      String imagenChat = DataHolder().fbPostSelected!.imagenURLpost[0];
      String autorUid = FirebaseAuth.instance.currentUser!.uid;
      String sPostAutorUid = DataHolder().fbPostSelected!.sAutorUid;

      FbChat nuevoChat = FbChat(
        uid: uid,
        sTitulo: titulo,
        sImagenURL: imagenChat,
        sAutorUid: autorUid,
        tmCreacion: Timestamp.now(),
        uidPost: uidPost,
        sPostAutorUid: sPostAutorUid
      );

      //insert db
      await _firestore.collection('Chats').doc(uid).set(nuevoChat.toFirestore());
      print("Chat creado: ${nuevoChat.toFirestore()}");

      DataHolder().fbChatSelected = nuevoChat;
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ChatView()));

      print("Creando chat con los siguientes datos:");
      print("UID Chat: $uid");
      print("Título: $titulo");
      print("Imagen: $imagenChat");
      print("UID Autor Chat: $autorUid");
      print("UID Post Autor: $sPostAutorUid");
      print("UID Post: $uidPost");

    }
  }



  @override
  Widget build(BuildContext context) {
    var post = DataHolder().fbPostSelected!;
    var images = post.imagenURLpost; // Lista de URLs de imágenes

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
                      // Página de imágenes
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
                            fit: BoxFit.contain, // Ajuste correcto
                            width: double.infinity,
                          );
                        },
                      ),
                      // Flecha izquierda
                      Positioned(
                        left: 10,
                        top: 130,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, size: 30, color: Colors.black),
                          onPressed: currentIndex > 0 ? _previousImage : null,
                        ),
                      ),
                      // Flecha derecha
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
              SizedBox(height: 16,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                ElevatedButton.icon(onPressed: crearNuevoChat,icon: const Icon(Icons.chat), label: Text("Chat"),)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}