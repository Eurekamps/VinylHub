import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../FbObjects/FbPost.dart';
import '../Singletone/AppNavigationUtils.dart';
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
//lista para guardar los perfiles que sigue el usuario
  List<Perfil?> perfilesSeguidos = [];

  @override
  void initState() {
    super.initState();
//cargo el perfil del usuario actual
    _cargarPerfil();
//cargo los perfiles que sigue el usuario
    _cargarPerfilesSeguidos();
  }

//funcion para cargar el perfil del usuario desde firestore
  Future<void> _cargarPerfil() async {
    await DataHolder().obtenerPerfilDeFirestore(FirebaseAuth.instance.currentUser!.uid);
//seteo el estado para refrescar la pantalla
    setState(() {});
  }

//funcion para cargar la lista de perfiles que sigue el usuario actual
  Future<void> _cargarPerfilesSeguidos() async {
    final uidActual = FirebaseAuth.instance.currentUser!.uid;
//hago consulta a la subcoleccion 'seguidos' dentro del doc del usuario actual
    final snapshot = await _firestore
        .collection('perfiles')
        .doc(uidActual)
        .collection('seguidos')
        .get();

    if (snapshot.docs.isNotEmpty) {
      List<Perfil?> perfiles = [];
//por cada doc en seguidos saco el uid del seguido y obtengo su perfil completo
      for (final doc in snapshot.docs) {
        final uidSeguido = doc.id; // el id del doc es el uid del seguido
        final perfilDoc = await _firestore.collection('perfiles').doc(uidSeguido).get();
        if (perfilDoc.exists) {
          perfiles.add(Perfil.fromFirestore(perfilDoc));
        }
      }
//actualizo el estado con la lista de perfiles que sigue el usuario
      setState(() {
        perfilesSeguidos = perfiles;
      });
    } else {
//si no sigue a nadie, pongo la lista vacia y refresco la pantalla
      setState(() {
        perfilesSeguidos = [];
      });
    }
  }

//widget para mostrar texto clickable que navega a la pantalla de ubicacion
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
            color: Colors.black,
          ),
        ),
      ),
    );
  }

//funcion que guarda el post seleccionado y navega a detalles del post propio
  void onMasDatosPostPropio(BuildContext context, FbPost postSeleccionado) {
    DataHolder().fbPostSelected = postSeleccionado;
    Navigator.of(context).pushNamed('/postdetailspropio');
  }

//widget que muestra los posts propios del usuario en un grid
  Widget _buildPostPropiosScreen() {
    return StreamBuilder<QuerySnapshot>(
//stream de todos los posts, se actualiza en tiempo real
      stream: _firestore.collection('Posts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
//mientras no llegan datos muestro loading
          return Center(child: CircularProgressIndicator());
        }

//uid del usuario actual para filtrar solo sus posts
        final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

//mapeo docs a objetos FbPost y filtro por autor igual al usuario actual
        var posts = snapshot.data!.docs
            .map((doc) => FbPost.fromFirestore(doc))
            .where((post) => post.sAutorUid == currentUserUid)
            .toList();

        //si no tiene posts publicados, muestro mensaje
        if (posts.isEmpty) {
          return Center(
            child: Text(
              "No has publicado ningún artículo todavía.",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

//grid para mostrar los posts filtrados
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
//al tocar un post navego a detalles con post seleccionado
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
//imagen con placeholder y error widget
                              imageUrl: post.imagenURLpost.first,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            ),
                          ),
                        )
//si no hay imagen, muestro icono gris indicando sin imagen
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
//titulo del post centrado, negrita y con max 1 linea
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
//texto con las categorias separadas por coma, gris y centrado
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
//precio del post con simbolo de euro
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

//widget que muestra los posts que el usuario ha comprado
  Widget _buildPostCompradosScreen() {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

//si no esta logueado muestro mensaje de que no inicio sesion
    if (currentUserUid == null) {
      return Center(
        child: Text("No has iniciado sesión."),
      );
    }

    return StreamBuilder<QuerySnapshot>(
//stream filtrado de posts vendidos y donde comprador es el usuario actual
      stream: _firestore
          .collection('Posts')
          .where('estado', isEqualTo: 'vendido')
          .where('compradorUid', isEqualTo: currentUserUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
//mientras no llegan datos muestro loading
          return Center(child: CircularProgressIndicator());
        }

//mapeo docs a objetos FbPost
        var posts = snapshot.data!.docs
            .map((doc) => FbPost.fromFirestore(doc))
            .toList();

//si no compro nada muestro mensaje
        if (posts.isEmpty) {
          return Center(
            child: Text(
              "Aún no has comprado ningún artículo.",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

//grid para mostrar los posts comprados
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//2 columnas, espacios, y aspecto de las celdas
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.8,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];

            return GestureDetector(
            //al tocar post llamo a funcion externa para manejar click
              onTap: () {
                AppNavigationUtils.onPostClicked(context, post);
              },
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
                      //si el post tiene imagenes muestro la primera con clip redondeado y aspecto fijo
                      if (post.imagenURLpost.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AspectRatio(
                            aspectRatio: 1.5,
                            child: CachedNetworkImage(
                            //imagen con placeholder y error widget
                              imageUrl: post.imagenURLpost.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
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
                        'Precio: ${post.precio} €',
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
    final currentUser = FirebaseAuth.instance.currentUser; //guardo usuario logueado

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 15), //espacio arriba
        CircleAvatar(
          radius: 50,
          backgroundImage: DataHolder().miPerfil != null && //si hay perfil y tiene imagen
              DataHolder().miPerfil!.imagenURL != null &&
              DataHolder().miPerfil!.imagenURL!.isNotEmpty
              ? CachedNetworkImageProvider(DataHolder().miPerfil!.imagenURL!) //cargo imagen url
              : AssetImage('assets/default-profile.png') as ImageProvider, //si no, imagen default
        ),
        SizedBox(height: 10), //espacio
        Text(
          DataHolder().miPerfil?.nombre ?? "Usuario", //nombre o texto por defecto
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          currentUser?.email ?? "Email no disponible", //correo o texto fallback
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        SizedBox(height: 12), //espacio
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _mostrarModalSeguidos, //al tocar abre modal seguidos
              child: Column(
                children: [
                  Text(
                    '${perfilesSeguidos.length}', //cantidad de perfiles seguidos
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Seguidos', //etiqueta
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(width: 40), //separacion horizontal
            GestureDetector(
              onTap: _mostrarModalSeguidores, //al tocar abre modal seguidores
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('perfiles')
                    .doc(DataHolder().miPerfil!.uid)
                    .collection('seguidores')
                    .get(), //busca seguidores en firestore
                builder: (context, snapshot) {
                  int count = 0;
                  if (snapshot.hasData) {
                    count = snapshot.data!.docs.length; //cuento seguidores
                  }
                  return Column(
                    children: [
                      Text(
                        '$count', //muestro cantidad seguidores
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Seguidores', //etiqueta
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12), //espacio abajo
      ],
    );
  }

//muestra modal con lista de perfiles seguidos
  void _mostrarModalSeguidos() {
    if (perfilesSeguidos.isEmpty) return; //si no hay nada no abre nada

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: perfilesSeguidos.length,
        itemBuilder: (context, index) {
          final perfil = perfilesSeguidos[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: perfil!.imagenURL != null && perfil.imagenURL!.isNotEmpty
                  ? NetworkImage(perfil.imagenURL!) //cargo imagen url perfil
                  : AssetImage('assets/default-profile.png') as ImageProvider, //default si no hay
            ),
            title: Text(perfil.nombre ?? 'Usuario'), //nombre o fallback
            onTap: () {
              Navigator.of(context).pop(); //cierro modal al tocar
              Navigator.of(context).pushNamed(
                '/perfilajeno',
                arguments: perfil.uid, //envio uid perfil para pantalla ajena
              );
            },
          );
        },
      ),
    );
  }

//muestra modal con lista de seguidores
  void _mostrarModalSeguidores() async {
    final snap = await FirebaseFirestore.instance
        .collection('perfiles')
        .doc(DataHolder().miPerfil!.uid)
        .collection('seguidores')
        .get(); //traigo seguidores desde firestore

    if (snap.docs.isEmpty) return; //no abre modal si no hay seguidores

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: snap.docs.length,
        itemBuilder: (context, index) {
          final uidSeguidor = snap.docs[index]['uidSeguidor']; //uid del seguidor
          return FutureBuilder<DocumentSnapshot>(
            future:
            FirebaseFirestore.instance.collection('perfiles').doc(uidSeguidor).get(), //traigo perfil del seguidor
            builder: (context, perfilSnap) {
              if (!perfilSnap.hasData || !perfilSnap.data!.exists) {
                return ListTile(title: Text('Cargando...')); //cargando mientras llega data
              }
              final data = perfilSnap.data!.data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: data['imagenURL'] != null && data['imagenURL'].toString().isNotEmpty
                      ? NetworkImage(data['imagenURL']) //imagen url del seguidor
                      : AssetImage('assets/default-profile.png') as ImageProvider, //default si no hay
                ),
                title: Text(data['nombre'] ?? 'Usuario'), //nombre o fallback
                subtitle: Text(data['apodo'] ?? 'Sin apodo'), //apodo o texto fallback
                onTap: () {
                  Navigator.of(context).pop(); //cierro modal al tocar
                  Navigator.of(context).pushNamed(
                    '/perfilajeno',
                    arguments: uidSeguidor, //envio uid seguidor para pantalla ajena
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, //tengo 2 pestañas
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, //sin boton atras automatico
          bottom: TabBar(
            tabs: [
              Tab(text: 'Mis publicaciones'), //pestaña 1
              Tab(text: 'Mis compras'), //pestaña 2
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPerfilDatos(), //muestro datos del perfil

            _buildMapaUbicacionPerfil(), //muestro mapa ubicacion

            Expanded(
              child: TabBarView(
                children: [
                  _buildPostPropiosScreen(), //lista publicaciones propias
                  _buildPostCompradosScreen(), //lista compras hechas
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}
