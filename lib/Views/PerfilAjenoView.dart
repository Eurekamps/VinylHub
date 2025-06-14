import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../FbObjects/FbPost.dart';
import '../FbObjects/FbPerfil.dart';
import '../Singletone/DataHolder.dart';

class PerfilAjenoView extends StatefulWidget {
  final String uidAjeno;

  const PerfilAjenoView({Key? key, required this.uidAjeno}) : super(key: key);

  @override
  State<PerfilAjenoView> createState() => _PerfilAjenoViewState();
}

class _PerfilAjenoViewState extends State<PerfilAjenoView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FbPerfil? perfilAjeno;

  LatLng? _userLocation;
  bool _locationLoading = true;

  bool _esSeguidor = false;
  bool _cargandoSeguidor = true;
  String? miUid;


  @override
  void initState() {
    super.initState();

    if (DataHolder().miPerfil != null) {
      miUid = DataHolder().miPerfil!.uid;
      _cargarPerfilAjeno();
      _obtenerUbicacion();
      _comprobarSiEsSeguidor();
    } else {
      debugPrint("❌ miPerfil es null");
    }
  }

  Future<void> _cargarPerfilAjeno() async {
    DocumentSnapshot<Map<String, dynamic>> doc =
    await _firestore.collection('perfiles').doc(widget.uidAjeno).get();

    perfilAjeno = FbPerfil.fromFirestore(doc, null);

    setState(() {});
  }




  Future<void> _obtenerUbicacion() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
        _locationLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationLoading = false;
      });
    }
  }

  Future<void> _comprobarSiEsSeguidor() async {
    DocumentSnapshot doc = await _firestore
        .collection('perfiles')
        .doc(widget.uidAjeno)
        .collection('seguidores')
        .doc(miUid)
        .get();

    setState(() {
      _esSeguidor = doc.exists;
      _cargandoSeguidor = false;
    });
  }




  void onMasDatosPostAjeno(BuildContext context, FbPost postSeleccionado) {
    DataHolder().fbPostSelected = postSeleccionado;
    Navigator.of(context).pushNamed('/postdetailsajeno');
  }

  Widget _buildPostAjenoScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Posts').where('sAutorUid', isEqualTo: widget.uidAjeno).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());


        var posts = snapshot.data!.docs.map((doc) => FbPost.fromFirestore(doc)).toList();

        if (posts.isEmpty) {
          return Center(
            child: Text(
              "Este usuario no ha publicado ningún artículo todavía.",
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
              onTap: () => onMasDatosPostAjeno(context, post),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                            child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                          ),
                        ),
                      SizedBox(height: 8),
                      Text(
                        post.titulo,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Categorías: ${post.categoria.join(', ')}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
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

  Widget _buildPerfilAjenoDatos() {
    // Validar que miUid no sea null antes de usarlo
    if (miUid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore
          .collection('perfiles')
          .doc(widget.uidAjeno)
          .collection('seguidores')
          .doc(miUid)
          .get(),
      builder: (context, snapshot) {
        bool yaSigue = snapshot.data?.exists ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 15),
            CircleAvatar(
              radius: 50,
              backgroundImage: (perfilAjeno != null &&
                  perfilAjeno!.imagenURL != null &&
                  perfilAjeno!.imagenURL!.isNotEmpty)
                  ? CachedNetworkImageProvider(perfilAjeno!.imagenURL!)
                  : const AssetImage('assets/default-profile.png')
              as ImageProvider,
            ),
            const SizedBox(height: 10),
            Text(
              perfilAjeno?.nombre ?? "Usuario",
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              perfilAjeno?.apodo ?? "",
              style: GoogleFonts.poppins(
                  fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/ubicacion');
              },
              child: const Text(
                "Ver ubicación",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: () async {
                final seguidoresRef = _firestore
                    .collection('perfiles')
                    .doc(widget.uidAjeno)
                    .collection('seguidores')
                    .doc(miUid);

                final seguidosRef = _firestore
                    .collection('perfiles')
                    .doc(miUid)
                    .collection('seguidos')
                    .doc(widget.uidAjeno);

                if (yaSigue) {
                  await seguidoresRef.delete();
                  await seguidosRef.delete();
                } else {
                  await seguidoresRef.set({
                    'uidSeguidor': miUid,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  await seguidosRef.set({
                    'uidSeguido': widget.uidAjeno,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                }

                setState(() {});
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: yaSigue ? Colors.grey : Colors.blue),
                foregroundColor: yaSigue ? Colors.grey[700] : Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                yaSigue ? 'Dejar de seguir' : 'Seguir',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSeguidoresButton("Seguidores", "seguidores"),
                _buildSeguidoresButton("Seguidos", "seguidos"),
              ],
            ),

            const SizedBox(height: 10),
          ],
        );
      },
    );
  }


  Widget _buildSeguidoresButton(String title, String subcollection) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('perfiles')
          .doc(widget.uidAjeno)
          .collection(subcollection)
          .get(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }

        return GestureDetector(
          onTap: () async {
            if (count == 0) return;

            final snap = await _firestore
                .collection('perfiles')
                .doc(widget.uidAjeno)
                .collection(subcollection)
                .get();

            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => ListView.builder(
                itemCount: snap.docs.length,
                itemBuilder: (context, index) {
                  final uid = snap.docs[index].data()[subcollection == 'seguidores'
                      ? 'uidSeguidor'
                      : 'uidSeguido'];

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('perfiles').doc(uid).get(),
                    builder: (context, perfilSnap) {
                      if (!perfilSnap.hasData) {
                        return const ListTile(title: Text('Cargando...'));
                      }

                      final data = perfilSnap.data!.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (data['imagenURL'] != null &&
                              data['imagenURL'].toString().isNotEmpty)
                              ? NetworkImage(data['imagenURL'])
                              : const AssetImage('assets/default-profile.png') as ImageProvider,
                        ),
                        title: Text(data['nombre'] ?? 'Usuario'),
                        subtitle: Text(data['apodo'] ?? 'Sin apodo'),
                        onTap: () {
                          Navigator.of(context).pop();

                          final currentUid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid == currentUid) {
                            Navigator.of(context).pushNamed('/tuperfil');
                          } else {
                            Navigator.of(context).pushNamed('/perfilajeno', arguments: uid);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            );
          },
          child: Column(
            children: [
              Text(
                '$count',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: Center(
          child: Text(
            "VinylHub",
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildPerfilAjenoDatos(),
          Expanded(child: _buildPostAjenoScreen()),
        ],
      ),
    );
  }
}
