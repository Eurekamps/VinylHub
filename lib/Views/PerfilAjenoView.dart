import 'package:cloud_firestore/cloud_firestore.dart';
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
  String miUid = DataHolder().miPerfil!.uid;


  @override
  void initState() {
    super.initState();
    _cargarPerfilAjeno();
    _obtenerUbicacion();
    _comprobarSiEsSeguidor();
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

  Future<void> _toggleSeguir() async {
    try {
      final seguidorRef = _firestore
          .collection('perfiles')
          .doc(widget.uidAjeno)
          .collection('seguidores')
          .doc(miUid);

      final siguiendoRef = _firestore
          .collection('perfiles')
          .doc(miUid)
          .collection('siguiendo')
          .doc(widget.uidAjeno);

      if (_esSeguidor) {
        // Dejar de seguir: borramos las referencias
        await Future.wait([
          seguidorRef.delete(),
          siguiendoRef.delete(),
        ]);
      } else {
        // Seguir: agregamos las referencias con timestamps para mejor seguimiento
        final data = {
          'fechaSeguido': FieldValue.serverTimestamp(),
        };
        await Future.wait([
          seguidorRef.set(data),
          siguiendoRef.set(data),
        ]);
      }

      setState(() {
        _esSeguidor = !_esSeguidor;
      });
    } catch (e) {
      print('Error al cambiar estado de seguir: $e');
      // Opcional: mostrar un SnackBar o mensaje de error para el usuario
    }
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
    final miUid = DataHolder().miPerfil!.uid;

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
            SizedBox(height: 15),
            CircleAvatar(
              radius: 50,
              backgroundImage: (perfilAjeno != null &&
                  perfilAjeno!.imagenURL != null &&
                  perfilAjeno!.imagenURL!.isNotEmpty)
                  ? CachedNetworkImageProvider(perfilAjeno!.imagenURL!)
                  : AssetImage('assets/default-profile.png') as ImageProvider,
            ),
            SizedBox(height: 10),
            Text(
              perfilAjeno?.nombre ?? "Usuario",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              perfilAjeno?.apodo ?? "",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/ubicacion');
              },
              child: Text(
                "Ver ubicación",
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    decoration: TextDecoration.underline),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final docRef = _firestore
                    .collection('perfiles')
                    .doc(widget.uidAjeno)
                    .collection('seguidores')
                    .doc(miUid);

                if (yaSigue) {
                  await docRef.delete();
                } else {
                  await docRef.set({
                    'uidSeguidor': miUid,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                }

                setState(() {}); // Para que el FutureBuilder se vuelva a ejecutar
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yaSigue ? Colors.grey[400] : Colors.blue,
              ),
              child: Text(yaSigue ? 'Dejar de seguir' : 'Seguir'),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text("Puntuación",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("4.2/5",
                        style: TextStyle(fontSize: 16, color: Colors.orange)),
                  ],
                ),
                SizedBox(width: 30),
                Column(
                  children: [
                    Text("Seguidores",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () async {
                        final snap = await _firestore
                            .collection('perfiles')
                            .doc(widget.uidAjeno)
                            .collection('seguidores')
                            .get();

                        showModalBottomSheet(
                          context: context,
                          builder: (_) => ListView.builder(
                            itemCount: snap.docs.length,
                            itemBuilder: (context, index) {
                              final uidSeguidor =
                              snap.docs[index]['uidSeguidor'];
                              return FutureBuilder<DocumentSnapshot>(
                                future: _firestore
                                    .collection('perfiles')
                                    .doc(uidSeguidor)
                                    .get(),
                                builder: (context, perfilSnap) {
                                  if (!perfilSnap.hasData) {
                                    return ListTile(
                                        title: Text('Cargando...'));
                                  }
                                  final data = perfilSnap.data!.data()
                                  as Map<String, dynamic>;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: data['imagenURL'] != null
                                          ? NetworkImage(data['imagenURL'])
                                          : null,
                                    ),
                                    title: Text(data['nombre'] ?? 'Usuario'),
                                    subtitle:
                                    Text(data['apodo'] ?? 'Sin apodo'),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                      child: Text(
                        "Ver",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                            decoration: TextDecoration.underline),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ],
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
