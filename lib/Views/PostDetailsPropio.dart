import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hijos_de_fluttarkia/FbObjects/FbChat.dart';
import 'package:hijos_de_fluttarkia/FbObjects/FbFavorito.dart';

import '../Singletone/DataHolder.dart';
import 'ChatView.dart';

class PostDetailsPropio extends StatefulWidget{

  final Function() onClose;

  PostDetailsPropio({super.key,required this.onClose});

  @override
  State<PostDetailsPropio> createState() => _PostDetailsPropioState();
}

class _PostDetailsPropioState extends State<PostDetailsPropio> {
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
                  ElevatedButton.icon(onPressed: (){},icon: const Icon(Icons.edit), label: Text("Editar post"),)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}