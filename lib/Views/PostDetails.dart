import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vinylhub/FbObjects/FbChat.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vinylhub/Singletone/AppNavegacionUtiles.dart';

import '../FbObjects/FbFavorito.dart';
import '../FbObjects/FbPerfil.dart';
import '../FbObjects/FbPost.dart';
import '../Services/RecomendationService.dart';
import '../Singletone/DataHolder.dart';
import 'BusquedaView.dart';
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
  final RecommendationService _recommendationService = RecommendationService();
  List<FbPost> postRecomendaciones = [];
  bool _loadingRecommendations = true;
  String? _ubicacionTexto;




  Future<void> _loadRecommendations() async {
    final post = DataHolder().fbPostSelected;
    if (post == null) return;

    final recommendations = await _recommendationService.getRecommendationsForPost(post);

    setState(() {
      postRecomendaciones = recommendations;
      _loadingRecommendations = false;
    });
  }



  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    _checkIfFavorito(); // Verificar si el post ya es favorito al cargar
    _cargarPerfilAutor();
    _loadRecommendations();
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

  Future<FbChat> crearNuevoChat() async {
    String uidPost = DataHolder().fbPostSelected!.uid;
    String sPostAutorUid = DataHolder().fbPostSelected!.sAutorUid;
    String sAutorUid = FirebaseAuth.instance.currentUser!.uid;

    var chatQuery = await _firestore
        .collection('Chats')
        .where('uidPost', isEqualTo: uidPost)
        .where('sPostAutorUid', isEqualTo: sPostAutorUid)
        .where('sAutorUid', isEqualTo: sAutorUid)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      var chatDoc = chatQuery.docs.first;
      FbChat chatExistente = FbChat.fromFirestore(chatDoc, null);
      DataHolder().fbChatSelected = chatExistente;
      return chatExistente;
    } else {
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

      await _firestore.collection('Chats').doc(uid).set(nuevoChat.toFirestore());

      DataHolder().fbChatSelected = nuevoChat;
      return nuevoChat;
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



  Future<void> obtenerUbicacion() async {
    final perfil = perfilAutor;
    if (perfil?.latitud != null && perfil?.longitud != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          perfil!.latitud!,
          perfil.longitud!,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            _ubicacionTexto = "${p.locality ?? ''}, ${p.postalCode ?? ''}".trim();
          });
        }
      } catch (e) {
        print("Error obteniendo dirección: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var post = DataHolder().fbPostSelected!;
    var images = post.imagenURLpost;

    double? lat = perfilAutor?.latitud;
    double? lng = perfilAutor?.longitud;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/perfilajeno',
              arguments: post.sAutorUid,
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(perfilAutor?.imagenURL ?? ''),
                backgroundColor: Colors.grey[300],
              ),
              SizedBox(width: 10),
              Text(
                perfilAutor?.nombre ?? 'Usuario',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
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
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
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
              ),
            SizedBox(height: 16),

            // Información del post
            Container(
              padding: EdgeInsets.all(12),
              color: Colors.white,
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
              color: Colors.white,
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
                color: Colors.white,
                child: Text(
                  post.descripcion!,
                  style: TextStyle(fontSize: 15),
                ),
              ),
            SizedBox(height: 20),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.chat),
                    label: Text("Chat"),
                    onPressed: () async {
                      await AppNavigationUtils.crearNuevoChat();
                      Navigator.of(context).pushNamed('/chatview');
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(_isFavorito ? Icons.favorite : Icons.favorite_border),
                    label: Text(_isFavorito ? "Eliminar" : "Añadir"),
                    onPressed: addPostFavoritos,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isFavorito ? Colors.red : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Mapa y dirección
            if (lat != null && lng != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(lat, lng),
                      zoom: 14,
                    ),
                    circles: {
                      Circle(
                        circleId: CircleId('radio_privacidad'),
                        center: LatLng(lat, lng),
                        radius: 500, // 500 metros de radio, ajusta según necesidad
                        fillColor: Colors.blue.withOpacity(0.2),
                        strokeColor: Colors.blue.withOpacity(0.5),
                        strokeWidth: 2,
                      ),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    liteModeEnabled: true,
                  ),
                ),
              ),
              if (_ubicacionTexto != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red),
                    SizedBox(width: 6),
                    Text(
                      _ubicacionTexto!,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 24),
            ],


            // Recomendaciones
            if (postRecomendaciones.isNotEmpty) ...[
              Text("También te puede interesar", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: postRecomendaciones.length,
                  itemBuilder: (context, index) {
                    final recPost = postRecomendaciones[index];

                    if (recPost.sAutorUid == DataHolder().miPerfil?.uid) {
                      return const SizedBox.shrink();
                    }

                    return GestureDetector(
                      onTap: () => AppNavigationUtils.onPostClicked(context, recPost),
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CachedNetworkImage(
                              imageUrl: recPost.imagenURLpost.first,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recPost.titulo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "${recPost.precio} €",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
