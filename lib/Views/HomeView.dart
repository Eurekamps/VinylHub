import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vinylhub/AdminClasses/FirebaseAdmin.dart';
import 'package:vinylhub/FbObjects/FbChat.dart';
import 'package:vinylhub/Views/FavoritosView.dart';
import 'package:vinylhub/Views/TuPerfil.dart';
import 'package:image_picker/image_picker.dart';
import '../FbObjects/FbPost.dart';
import '../Services/DiscogsService.dart';
import '../Singletone/DataHolder.dart';
import 'MiDrawer1.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _artistaController= TextEditingController();
  final TextEditingController _anioEdicionController= TextEditingController();
  List<String> _imagenURLs = [];
  List<String> _categoriasSeleccionadas = [];
  final ImagePicker _picker = ImagePicker();

  final DiscogsService _discogsService = DiscogsService();
  List<dynamic> _results = []; // Lista de resultados de vinilos
  bool _isSearching = false;

  int _selectedIndex = 0;
  bool _isGridView = true;
  List<FbChat> arChats = [];
  bool blListaPostsVisible = true;
  String? _categoriaSeleccionada;
  String? _ordenSeleccionado;
  RangeValues _rangoPrecio = RangeValues(0, 1000);

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _loadData(); // Carga los datos cuando se inicializa el estado
    _setupFCM(); // Configura FCM
  }

  void _setupFCM() async {
    // Pedir permisos (importante en iOS y Android 13+)
    await _firebaseMessaging.requestPermission();

    // Obtener y guardar el token en Firestore
    String? token = await _firebaseMessaging.getToken();
    print("🔑 Token FCM: $token");

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && token != null) {
      await FirebaseFirestore.instance.collection('perfiles').doc(uid).update({
        'fcmToken': token,
      });
    }

    // Escuchar notificaciones cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        print('🔔 Notificación en foreground: ${notification.title} - ${notification.body}');
        // Aquí puedes mostrar un diálogo, snackbar o actualizar UI si quieres
      }
    });

    // Cuando el usuario abre la app tocando una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔔 Notificación abierta: ${message.data}");
      // Aquí puedes navegar a la pantalla que quieras, por ejemplo:
      // Navigator.pushNamed(context, '/chat', arguments: message.data['chatId']);
    });
  }




  void _loadData() async {
    List<FbChat> arTemp = await DataHolder().descargarTodosChats();
    setState(() {
      arChats.clear();
      arChats.addAll(arTemp);
    });
  }



  Widget? _chatItemBuilder(BuildContext contexto, int indice) {
    return GestureDetector(
      onTap: () {
        DataHolder().fbChatSelected = arChats[indice];
        Navigator.of(contexto).pushNamed('/chatview');
      },
      child: Container(
        width: 250,
        child: Row(
          children: [
            Text(
              "${arChats[indice].sTitulo}",
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _seleccionarImagenDesdeGaleria() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      final url = await FirebaseAdmin().subirImagenAFirebase(imagen);  // Esto sigue funcionando
      if (url != null) {
        setState(() {
          _imagenURLs.add(url); // Guarda la URL obtenida, no el XFile
        });
      }
    }
  }

  Future<void> _capturarImagenDesdeCamara() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.camera);
    if (imagen != null) {
      final url = await FirebaseAdmin().subirImagenAFirebase(imagen);;  // Esto sigue funcionando
      if (url != null) {
        setState(() {
          _imagenURLs.add(url); // Guarda la URL obtenida, no el XFile
        });
      }
    }
  }



  Future<void> _agregarPost() async {
    String titulo = _tituloController.text.trim();
    String descripcion = _descripcionController.text.trim();
    String artista = _artistaController.text.trim();
    int anio = int.tryParse(_anioEdicionController.text.trim()) ?? 0;
    int precio = int.tryParse(_precioController.text.trim()) ?? 0;
    String uid = FirebaseFirestore.instance.collection('Posts').doc().id;

    // Validaciones
    if (titulo.isEmpty || descripcion.isEmpty) {
      print("Error: Título o descripción vacíos");
      return;
    }

    if (_imagenURLs.isEmpty) {
      print("Error: No se seleccionaron imágenes");
      return;
    }

    if (_categoriasSeleccionadas.isEmpty) {
      print("Error: No se seleccionaron categorías");
      return;
    }

    FbPost nuevaPost = FbPost(
      titulo: titulo,
      descripcion: descripcion,
      artista: artista,
      anio: anio,
      precio: precio,
      imagenURLpost: _imagenURLs,
      categoria: _categoriasSeleccionadas,
      uid: uid,
      sAutorUid: FirebaseAuth.instance.currentUser!.uid,
      estado: 'disponible', // <- aquí lo fijas como disponible
    );


    // Agregar el post a Firestore
    await _firestore.collection('Posts').add(nuevaPost.toMap());
    print("Post creado: ${nuevaPost.toMap()}");

    // Limpiar el formulario
    setState(() {
      _tituloController.clear();
      _descripcionController.clear();
      _precioController.clear();
      _imagenURLs.clear();
      _categoriasSeleccionadas.clear();
    });
  }


  void _eliminarImagen(int index) {
    setState(() {
      _imagenURLs.removeAt(index);
    });
  }

  //función en la que se le pasa el contexto y unobjeto fbpost para usarlo para navegar a postdetails
  void onPostItem_MasDatosClicked(BuildContext context, FbPost postSeleccionado){
    DataHolder().fbPostSelected=postSeleccionado;
    Navigator.of(context).pushNamed('/postdetails');
    setState(() {
      blListaPostsVisible=false;
    });
  }
  void _searchVinyls(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final data = await _discogsService.searchVinyl(query);
      setState(() {
        _results = data;
      });
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar vinilos: $e')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Función para manejar la selección de un vinilo y autocompletar el título
  void _onSuggestionTap(Map<String, dynamic> item) {
    setState(() {
      //autocompleta el titulo
      _tituloController.text = item['title'] ?? 'Sin título';

      //autocompleta cateogira musical
      final categorias = item['genre'] ?? [];
      for (var categoria in categorias) {
        if (!_categoriasSeleccionadas.contains(categoria)) {
          _categoriasSeleccionadas.add(categoria);
        }
      }

      //autocompleta el año de la edicion
      _anioEdicionController.text = item['year']?.toString() ?? '';
    });
  }

  Widget _buildFiltros() {
    final categorias = ['Rock', 'Pop', 'R&B', 'Hip-Hop', 'Soul', 'Clásica',
      'Heavy Metal', 'Jazz', 'Neo Soul', 'Blues', 'Folk',
      'Reggae', 'Country', 'Electrónica', 'Punk', 'Funk',
      'Disco', 'Indie', 'Latino', 'Gospel', 'Experimental',
      'House', 'Techno', 'Ambient', 'Trance', 'Ska'];
    final ordenes = ['Título A-Z', 'Título Z-A', 'Precio ascendente', 'Precio descendente'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
                textStyle: TextStyle(fontSize: 13),
              ),
              icon: Icon(Icons.refresh, size: 16),
              label: Text("Resetear filtros"),
              onPressed: () {
                setState(() {
                  _categoriaSeleccionada = null;
                  _ordenSeleccionado = null;
                  _rangoPrecio = RangeValues(0, 1000);
                });
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text("Categoría"),
                  value: _categoriaSeleccionada,
                  items: categorias.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoriaSeleccionada = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text("Ordenar por"),
                  value: _ordenSeleccionado,
                  items: ordenes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _ordenSeleccionado = value;
                    });
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text("Precio: ${_rangoPrecio.start.round()}€ - ${_rangoPrecio.end.round()}€"),
              Expanded(
                child: RangeSlider(
                  values: _rangoPrecio,
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  labels: RangeLabels(
                    _rangoPrecio.start.round().toString(),
                    _rangoPrecio.end.round().toString(),
                  ),
                  onChanged: (values) {
                    setState(() {
                      _rangoPrecio = values;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }




  Widget _buildListScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Posts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

        // Consulta para asignar los posts creados por otros usuarios
        var posts = snapshot.data!.docs
            .map((doc) => FbPost.fromFirestore(doc))
            .where((post) => post.sAutorUid != currentUserUid)
            .where((post) {
          final dentroCategoria = _categoriaSeleccionada == null || post.categoria.contains(_categoriaSeleccionada!);
          final dentroPrecio = post.precio >= _rangoPrecio.start && post.precio <= _rangoPrecio.end;
          return dentroCategoria && dentroPrecio;
        })
            .toList();

// Ordenar
        if (_ordenSeleccionado == 'Título A-Z') {
          posts.sort((a, b) => a.titulo.compareTo(b.titulo));
        } else if (_ordenSeleccionado == 'Título Z-A') {
          posts.sort((a, b) => b.titulo.compareTo(a.titulo));
        } else if (_ordenSeleccionado == 'Precio ascendente') {
          posts.sort((a, b) => a.precio.compareTo(b.precio));
        } else if (_ordenSeleccionado == 'Precio descendente') {
          posts.sort((a, b) => b.precio.compareTo(a.precio));
        }




        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            FbPost post = posts[index];

            return GestureDetector(
              onTap: () => onPostItem_MasDatosClicked(context, post),
              child: Card(
                margin: EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Espaciado interno
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Alineación del contenido a la izquierda
                    children: [
                      if (post.imagenURLpost.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10), // Redondea la imagen
                          child: AspectRatio(
                            aspectRatio: 1.5, // Relación de aspecto fija (ancho/alto)
                            child: Image.network(
                              post.imagenURLpost.first, // Usamos la URL directamente
                              fit: BoxFit.contain, // Muestra toda la imagen dentro del área sin recortarla
                            ),
                          ),
                        )
                      else
                        AspectRatio(
                          aspectRatio: 1.5, // Relación de aspecto para imágenes no disponibles
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      SizedBox(height: 8), // Espaciado entre la imagen y el título
                      Text(
                        post.titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4), // Espaciado entre el título y la categoría
                      Text(
                        'Categorías: ${post.categoria.join(', ')}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Precio: ${post.precio.toString()} €',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8), // Espaciado entre el precio y el final del Card
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



  Widget _buildGridScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Posts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

        // Consulta para asignar los posts creados por otros usuarios
        var posts = snapshot.data!.docs
            .map((doc) => FbPost.fromFirestore(doc))
            .where((post) => post.sAutorUid != currentUserUid)
            .where((post) {
          final dentroCategoria = _categoriaSeleccionada == null || post.categoria.contains(_categoriaSeleccionada!);
          final dentroPrecio = post.precio >= _rangoPrecio.start && post.precio <= _rangoPrecio.end;
          return dentroCategoria && dentroPrecio;
        })
            .toList();

// Ordenar
        if (_ordenSeleccionado == 'Título A-Z') {
          posts.sort((a, b) => a.titulo.compareTo(b.titulo));
        } else if (_ordenSeleccionado == 'Título Z-A') {
          posts.sort((a, b) => b.titulo.compareTo(a.titulo));
        } else if (_ordenSeleccionado == 'Precio ascendente') {
          posts.sort((a, b) => a.precio.compareTo(b.precio));
        } else if (_ordenSeleccionado == 'Precio descendente') {
          posts.sort((a, b) => b.precio.compareTo(a.precio));
        }


        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.8, // Ajusta la proporción para tarjetas verticales
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            FbPost post = posts[index];

            return GestureDetector(
              onTap: () => onPostItem_MasDatosClicked(context, post),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Bordes redondeados
                ),
                elevation: 4, // Sombra para diseño más llamativo
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Espaciado interno
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Centrar contenido horizontalmente
                    children: [
                      if (post.imagenURLpost.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10), // Redondea la imagen
                          child: AspectRatio(
                            aspectRatio: 1.5, // Relación de aspecto fija (ancho/alto)
                            child: CachedNetworkImage(
                              imageUrl: post.imagenURLpost.first,
                              fit: BoxFit.contain,
                              placeholder: (context, url) =>
                                  Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error, color: Colors.red),
                            ),
                          ),
                        )
                      else
                        AspectRatio(
                          aspectRatio: 1.5, // Relación de aspecto para imágenes no disponibles
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      SizedBox(height: 8), // Espaciado entre la imagen y el título
                      Expanded(
                        // Usa Expanded para permitir que el texto se ajuste al espacio disponible
                        child: Text(
                          post.titulo,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(height: 4), // Espaciado entre el título y la categoría
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



  Widget _buildCreatePostScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de título
            TextField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: 'Título del disco',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.album),
              ),
              onChanged: (text) {
                _searchVinyls(text);
                setState(() {
                  _categoriasSeleccionadas.clear();
                });
              },
            ),
            const SizedBox(height: 10),

            // Campo artista
            TextField(
              controller: _artistaController,
              decoration: InputDecoration(
                labelText: 'Artista',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),

            // Sugerencias Discogs
            if (_results.isNotEmpty)
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return ListTile(
                      title: Text(item['title'] ?? 'Sin título'),
                      subtitle: Text('Año: ${item['year'] ?? 'Año desconocido'}'),
                      onTap: () {
                        setState(() {
                          _tituloController.text = item['title'] ?? '';
                          _artistaController.text = _separarArtista(item['title'] ?? '');
                          _anioEdicionController.text = item['year'] ?? '';

                          final genre = item['genre']?.isNotEmpty == true ? item['genre'][0] : null;
                          if (genre != null && !_categoriasSeleccionadas.contains(genre)) {
                            _categoriasSeleccionadas.add(genre);
                          }

                          _results.clear();
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),

            // Año de edición
            TextField(
              controller: _anioEdicionController,
              decoration: InputDecoration(
                labelText: 'Año de edición',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.date_range),
              ),
            ),
            const SizedBox(height: 10),

            // Descripción
            TextField(
              controller: _descripcionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 10),

            // Precio
            TextField(
              controller: _precioController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Precio',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.euro),
              ),
            ),
            const SizedBox(height: 10),

            // Categoría
            DropdownButtonFormField<String>(
              items: [
                'Rock', 'Pop', 'R&B', 'Hip-Hop', 'Soul', 'Clásica',
                'Heavy Metal', 'Jazz', 'Neo Soul', 'Blues', 'Folk',
                'Reggae', 'Country', 'Electrónica', 'Punk', 'Funk',
                'Disco', 'Indie', 'Latino', 'Gospel', 'Experimental',
                'House', 'Techno', 'Ambient', 'Trance', 'Ska'
              ].map((categoria) => DropdownMenuItem(
                value: categoria,
                child: Text(categoria),
              )).toList(),
              onChanged: (value) {
                if (value != null && !_categoriasSeleccionadas.contains(value)) {
                  setState(() {
                    _categoriasSeleccionadas.add(value);
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 10),

            // Chips de categorías
            Wrap(
              spacing: 8.0,
              children: _categoriasSeleccionadas.map((categoria) {
                return Chip(
                  label: Text(categoria),
                  onDeleted: () {
                    setState(() {
                      _categoriasSeleccionadas.remove(categoria);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Botones galería y cámara
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _seleccionarImagenDesdeGaleria,
                  icon: Icon(Icons.photo_library),
                  label: Text("Galería"),
                ),
                ElevatedButton.icon(
                  onPressed: _capturarImagenDesdeCamara,
                  icon: Icon(Icons.camera_alt),
                  label: Text("Cámara"),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Imágenes seleccionadas como cards horizontales
            if (_imagenURLs.isNotEmpty)
              SizedBox(
                height: 120,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._imagenURLs.map((image) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 3,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    image,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: Icon(Icons.cancel, color: Colors.red),
                                    onPressed: () {
                                      _eliminarImagen(_imagenURLs.indexOf(image));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      // Botón "+"
                      GestureDetector(
                        onTap: _seleccionarImagenDesdeGaleria,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Icon(Icons.add, size: 40, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Botón crear post
            Center(
              child: ElevatedButton(
                onPressed: _agregarPost,
                child: Text('Crear Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }



//funcion para extraer el nombre del artista del titulo del disco
  String _separarArtista(String title) {
    final parts = title.split(' - ');
    return parts.isNotEmpty ? parts[0] : ''; //extrae todo lo que esta antes del guion
  }


  Widget _buildPantallaChats() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Chats').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // Convierte los documentos en una lista de objetos FbChat
          List<FbChat> chats = snapshot.data!.docs.map((doc) {
            return FbChat.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
              null,
            );
          }).toList();

          if (chats.isEmpty) {
            return Center(child: Text("No hay chats disponibles."));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              FbChat chat = chats[index];
              final String uidUsuarioActual = FirebaseAuth.instance.currentUser!.uid;

              // Validaciones para los permisos del usuario
              final bool esCreadorChat = chat.sAutorUid == uidUsuarioActual;
              final bool esCreadorPost = chat.sPostAutorUid == uidUsuarioActual;

              if (esCreadorChat || esCreadorPost) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Chats')
                      .doc(chat.uid)
                      .collection('mensajes')
                      .orderBy('tmCreacion', descending: true)  // Ordenamos para obtener el último mensaje primero
                      .snapshots(),
                  builder: (context, messageSnapshot) {
                    String lastMessage = "No hay mensajes aún.";
                    String lastMessageSender = "";

                    if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
                      var messages = messageSnapshot.data!.docs;
                      var lastMessageDoc = messages.first;  // Al estar ordenado, el primer mensaje es el más reciente
                      lastMessage = lastMessageDoc['sCuerpo'] ?? "Mensaje vacío";
                      lastMessageSender = lastMessageDoc['sAutorNombre'] ?? "Desconocido";
                    }

                    return GestureDetector(
                      onTap: () {
                        DataHolder().fbChatSelected = chat;
                        Navigator.of(context).pushNamed('/chatview');
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Imagen del chat en formato circular
                            ClipOval(
                              child: chat.sImagenURL.isNotEmpty
                                  ? CachedNetworkImage(
                                imageUrl: chat.sImagenURL,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.white,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.shade300,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              )
                                  : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade300,
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),

                            SizedBox(width: 12),
                            // Información del chat
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chat.sTitulo,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    lastMessageSender.isNotEmpty
                                        ? "$lastMessageSender: $lastMessage"
                                        : lastMessage,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else {
                // Si no es accesible para el usuario actual
                return SizedBox.shrink();
              }
            },
          );
        },
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).pushNamed('/busquedaview');
            },
          ),
          PopupMenuButton<int>(
            onSelected: (int value) {
              if (value == 1) {
                setState(() {
                  _isGridView = !_isGridView; // Alterna entre lista y grid
                });
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(
                value: 1,
                child: Text('Cambiar Vista'),
              ),
            ],
          ),
          SizedBox(width: 20,)
        ],
      ),
      drawer: MiDrawer1(),
      body: _selectedIndex == 0
          ? Column(
        children: [
          _buildFiltros(),
          Expanded(child: _isGridView ? _buildGridScreen() : _buildListScreen()),
        ],
      )
          : _selectedIndex == 1
          ? FavoritosView()
          : _selectedIndex == 2
          ? _buildCreatePostScreen()
          : _selectedIndex == 3
          ? _buildPantallaChats()
          : TuPerfil(),

      bottomNavigationBar:  BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black, // Color para el texto e icono del elemento seleccionado
        unselectedItemColor: Colors.grey, // Color para el texto e icono de los elementos no seleccionados
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold), // Estilo del texto seleccionado
        unselectedLabelStyle: const TextStyle(color: Colors.grey),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Crear Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box),
            label: 'Perfil',
          ),

        ],
      ),
    );
  }
}
