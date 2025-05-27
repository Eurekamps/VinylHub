import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vinylhub/FbObjects/FbChat.dart';
import 'package:vinylhub/FbObjects/FbFavorito.dart';

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
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context); // Cerrar la pantalla de detalles
          },
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
              // Carrusel de imágenes con diseño mejorado
              if (images.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        SizedBox(
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
                ),
              SizedBox(height: 16),
              // Contenedor para el título
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
              // Contenedor para la descripción
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
              // Contenedor del precio
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
              // Botón con más espacio y mejor diseño
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit),
                label: Text("Editar"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}