import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../FbObjects/FbPost.dart';
import '../Singletone/DataHolder.dart';

// Clase Perfil para cargar datos desde Firestore
class Perfil {
  final String? uid;
  final String? nombre;
  final String? imagenURL;

  Perfil({this.uid, this.nombre, this.imagenURL});

  factory Perfil.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Perfil(
      uid: doc.id,
      nombre: data['nombre'] ?? '',
      imagenURL: data['imagenURL'] ?? '',
    );
  }
}

class TuPerfil extends StatefulWidget {
  @override
  State<TuPerfil> createState() => _TuPerfilState();
}

class _TuPerfilState extends State<TuPerfil> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Perfil?> perfilesSeguidos = [];

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
    _cargarPerfilesSeguidos();
  }

  Future<void> _cargarPerfil() async {
    await DataHolder().obtenerPerfilDeFirestore(FirebaseAuth.instance.currentUser!.uid);
    setState(() {});
  }

  Future<void> _cargarPerfilesSeguidos() async {
    final uidActual = FirebaseAuth.instance.currentUser!.uid;

    // Cambia 'siguiendo' y 'uidsSeguidos' según tu estructura real en Firestore
    final docRef = _firestore.collection('siguiendo').doc(uidActual);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      final List<dynamic>? listaUids = docSnap.data()?['uidsSeguidos'];
      if (listaUids != null && listaUids.isNotEmpty) {
        List<Perfil?> perfiles = [];
        for (String uidSeguido in listaUids) {
          final perfilDoc = await _firestore.collection('perfiles').doc(uidSeguido).get();
          if (perfilDoc.exists) {
            perfiles.add(Perfil.fromFirestore(perfilDoc));
          }
        }
        setState(() {
          perfilesSeguidos = perfiles;
        });
      }
    }
  }

  Widget _buildMapaUbicacionPerfil() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed('/ubicacion');
        },
        child: Text(
          "Ver ubicación",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blueAccent,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  void onMasDatosPostPropio(BuildContext context, FbPost postSeleccionado) {
    DataHolder().fbPostSelected = postSeleccionado;
    Navigator.of(context).pushNamed('/postdetailspropio');
  }

  Widget _buildPostPropiosScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Posts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

        var posts = snapshot.data!.docs
            .map((doc) => FbPost.fromFirestore(doc))
            .where((post) => post.sAutorUid == currentUserUid)
            .toList();

        if (posts.isEmpty) {
          return Center(
            child: Text(
              "No has publicado ningún artículo todavía.",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.8,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            FbPost post = posts[index];

            return GestureDetector(
              onTap: () => onMasDatosPostPropio(context, post),
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
                      if (post.imagenURLpost.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AspectRatio(
                            aspectRatio: 1.5,
                            child: CachedNetworkImage(
                              imageUrl: post.imagenURLpost.first,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Icon(Icons.error),
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
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Categorías: ${post.categoria.join(', ')}',
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
                        'Precio: ${post.precio.toString()} €',
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
    );
  }

  Widget _buildPerfilDatos() {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 15),
        CircleAvatar(
          radius: 50,
          backgroundImage: DataHolder().miPerfil != null &&
              DataHolder().miPerfil!.imagenURL != null &&
              DataHolder().miPerfil!.imagenURL!.isNotEmpty
              ? CachedNetworkImageProvider(DataHolder().miPerfil!.imagenURL!)
              : AssetImage('assets/default-profile.png') as ImageProvider,
        ),
        SizedBox(height: 10),
        Text(
          DataHolder().miPerfil?.nombre ?? "Usuario",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          currentUser?.email ?? "Email no disponible",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  "Puntuación",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "4.5/5",
                  style: TextStyle(fontSize: 16, color: Colors.orange),
                ),
              ],
            ),
            SizedBox(width: 30),
            Column(
              children: [
                Text(
                  "Seguidores",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "125",
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerfilesSeguidos() {
    if (perfilesSeguidos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No sigues a ningún usuario aún.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: perfilesSeguidos.length,
        itemBuilder: (context, index) {
          final perfil = perfilesSeguidos[index];
          if (perfil == null) return SizedBox();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: perfil.imagenURL != null && perfil.imagenURL!.isNotEmpty
                      ? CachedNetworkImageProvider(perfil.imagenURL!)
                      : AssetImage('assets/default-profile.png') as ImageProvider,
                ),
                SizedBox(height: 6),
                Text(
                  perfil.nombre ?? 'Usuario',
                  style: TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildPerfilDatos(),
          _buildPerfilesSeguidos(),
          _buildMapaUbicacionPerfil(),
          Expanded(
            child: _buildPostPropiosScreen(),
          ),
        ],
      ),
    );
  }
}
