import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vinylhub/FbObjects/FbChat.dart';
import 'package:vinylhub/FbObjects/FbFavorito.dart';

import '../Singletone/DataHolder.dart';
import 'BusquedaView.dart';
import 'ChatView.dart';
import 'EditPost.dart';

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
    var images = post.imagenURLpost;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: post.estado.toLowerCase() == "vendido" ? Colors.grey : Colors.black87),
            onPressed: post.estado.toLowerCase() == "vendido" ? null : () async {
              final updatedPost = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPost(post: post),
                ),
              );

              if (updatedPost != null) {
                setState(() {
                  DataHolder().fbPostSelected = updatedPost;
                });
              }
            },
          ),

          IconButton(
            icon: Icon(Icons.share, color: Colors.black),
            onPressed: () {
              Share.share(
                "📀 ${post.titulo}\n💰 ${post.precio} €\n📖 ${post.descripcion ?? "Sin descripción"}",
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 260,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => currentIndex = index),
                        itemCount: images.length,
                        itemBuilder: (context, index) => CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                        ),
                      ),
                    ),
                    if (post.estado == 'vendido') Positioned.fill(
                      child: Container(
                        alignment: Alignment.center,
                        color: Colors.black.withOpacity(0.4),
                        child: Transform.rotate(
                          angle: -0.2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "VENDIDO",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 110,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, size: 30, color: Colors.white),
                        onPressed: currentIndex > 0 ? _previousImage : null,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 110,
                      child: IconButton(
                        icon: Icon(Icons.arrow_forward, size: 30, color: Colors.white),
                        onPressed: currentIndex < images.length - 1 ? _nextImage : null,
                      ),
                    ),
                  ],
                ),

              ),
            SizedBox(height: 16),

            // Información principal
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.titulo, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("Artista: ${post.artista}", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text("${post.precio} €", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Categorías
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Categorías:", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: post.categoria.map((cat) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BusquedaView(generoInicial: cat)),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(cat, style: TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Descripción
            if (post.descripcion != null && post.descripcion!.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(post.descripcion!, style: TextStyle(fontSize: 15)),
              ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }


}