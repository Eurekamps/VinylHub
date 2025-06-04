import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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

  @override
  void initState() {
    super.initState();
    _cargarPerfilAjeno();
    _obtenerUbicacion();
  }

  Future<void> _cargarPerfilAjeno() async {
    await DataHolder().obtenerPerfilDeFirestore(widget.uidAjeno);
    perfilAjeno = DataHolder().miPerfil; // mantienes igual
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 15),
        CircleAvatar(
          radius: 50,
          backgroundImage: (perfilAjeno != null && perfilAjeno!.imagenURL != null && perfilAjeno!.imagenURL!.isNotEmpty)
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
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text("Puntuación", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("4.2/5", style: TextStyle(fontSize: 16, color: Colors.orange)),
              ],
            ),
            SizedBox(width: 30),
            Column(
              children: [
                Text("Seguidores", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("98", style: TextStyle(fontSize: 16, color: Colors.blue)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapa() {
    if (_locationLoading) return Center(child: CircularProgressIndicator());

    if (_userLocation == null) {
      return Center(child: Text("No se pudo obtener la ubicación"));
    }

    return Container(
      height: 120,  // Altura más pequeña para que ocupe menos pantalla
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: _userLocation!, zoom: 13),
          markers: {
            Marker(markerId: MarkerId('user'), position: _userLocation!),
          },
          circles: {
            Circle(
              circleId: CircleId('privacy_circle'),
              center: _userLocation!,
              radius: 2000, // 2 km
              fillColor: Colors.blue.withOpacity(0.2),
              strokeColor: Colors.blueAccent.withOpacity(0.7),
              strokeWidth: 2,
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (controller) {},
        ),
      ),
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
          _buildMapa(),          // Mapa pequeño arriba
          _buildPerfilAjenoDatos(),
          Expanded(child: _buildPostAjenoScreen()),
        ],
      ),

    );
  }
}
