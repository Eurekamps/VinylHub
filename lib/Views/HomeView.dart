import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hijos_de_fluttarkia/FbObjects/FbChat.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert'; // Para convertir la imagen a base64
import 'dart:typed_data'; // Para trabajar con bytes de la imagen
import '../FbObjects/FbPost.dart';
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

  List<String> _imagenURLs = [];
  List<String> _categoriasSeleccionadas = [];
  final ImagePicker _picker = ImagePicker();

  int _selectedIndex = 0;
  bool _isGridView = true;
  List<FbChat> arChats = [];
  bool blListaPostsVisible = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // Carga los datos cuando se inicializa el estado
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

  Future<String?> _convertirImagenABase64(XFile imagen) async {
    try {
      final bytes = await imagen.readAsBytes();
      return "data:image/jpeg;base64,${base64Encode(bytes)}";
    } catch (e) {
      print("Error al convertir imagen a base64: $e");
      return null;
    }
  }

  Future<void> _seleccionarImagenDesdeGaleria() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      final base64String = await _convertirImagenABase64(imagen);
      if (base64String != null) {
        setState(() {
          _imagenURLs.add(base64String);
        });
      }
    }
  }

  Future<void> _capturarImagenDesdeCamara() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.camera);
    if (imagen != null) {
      final base64String = await _convertirImagenABase64(imagen);
      if (base64String != null) {
        setState(() {
          _imagenURLs.add(base64String);
        });
      }
    }
  }

  void _eliminarImagen(int index) {
    setState(() {
      _imagenURLs.removeAt(index);
    });
  }

  Future<void> _agregarPost() async {
    String titulo = _tituloController.text.trim();
    String descripcion = _descripcionController.text.trim();
    int precio = int.tryParse(_precioController.text.trim()) ?? 0;
    String uid = FirebaseFirestore.instance.collection('Posts').doc().id;

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
      precio: precio,
      imagenURLpost: _imagenURLs,
      categoria: _categoriasSeleccionadas,
      uid: uid
    );

    await _firestore.collection('Posts').add(nuevaPost.toMap());
    print("Post creado: ${nuevaPost.toMap()}");

    setState(() {
      _tituloController.clear();
      _descripcionController.clear();
      _precioController.clear();
      _imagenURLs.clear();
      _categoriasSeleccionadas.clear();
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

  Widget _buildListScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Posts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var posts = snapshot.data!.docs.map((doc) {
          return FbPost.fromFirestore(doc);
        }).toList();

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            FbPost post = posts[index];

            return
              GestureDetector(
                onTap: (){onPostItem_MasDatosClicked(context, post);},
                child:
                  Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(post.titulo),
                      subtitle: Text('Categorías: ${post.categoria.join(', ')}'),
                      trailing: post.imagenURLpost.isNotEmpty
                          ? Image.memory(
                        base64Decode(_limpiarBase64(post.imagenURLpost.first)),
                        width: 150,
                        height: 150,
                      )
                          : null,
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

        var posts = snapshot.data!.docs.map((doc) {
          return FbPost.fromFirestore(doc);
        }).toList();

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
            return
            GestureDetector(
              onTap: (){onPostItem_MasDatosClicked(context, post);},
              child:
                Card(
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
                              child: Image.memory(
                                base64Decode(_limpiarBase64(post.imagenURLpost.first)),
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
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4), // Espaciado entre el título y la categoría
                        Text(
                          'Categorías: ${post.categoria.join(', ')}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4,),
                        Text(
                          'Precio: ${post.precio.toString()} €',
                          style: TextStyle(fontSize: 14),
                        )

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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _tituloController,
            decoration: InputDecoration(labelText: 'Título del Post'),
          ),
          TextField(
            controller: _descripcionController,
            decoration: InputDecoration(labelText: 'Descripción'),
          ),
          TextField(
            controller: _precioController,
            decoration: InputDecoration(labelText: 'Precio'),
          ),

          DropdownButtonFormField<String>(
            items: ['Rock', 'Pop', 'R&B','Hip-Hop', 'Soul', 'Clásica','Heavy Metal', 'Jazz', 'Neo Soul']
                .map((categoria) => DropdownMenuItem(
              value: categoria,
              child: Text(categoria),
            ))
                .toList(),
            onChanged: (value) {
              if (value != null && !_categoriasSeleccionadas.contains(value)) {
                setState(() {
                  _categoriasSeleccionadas.add(value);
                });
              }
            },
            decoration: InputDecoration(labelText: 'Selecciona una categoría'),
          ),
          Wrap(
            children: _categoriasSeleccionadas
                .map((categoria) => Chip(
              label: Text(categoria),
              onDeleted: () {
                setState(() {
                  _categoriasSeleccionadas.remove(categoria);
                });
              },
            ))
                .toList(),
          ),
          SizedBox(height: 10),
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
          SizedBox(height: 10),
          if (_imagenURLs.isNotEmpty)
            Wrap(
              spacing: 8.0,
              children: _imagenURLs.map((image) {
                return Chip(
                  label: Text('Imagen cargada'),
                  onDeleted: () {
                    _eliminarImagen(_imagenURLs.indexOf(image));
                  },
                );
              }).toList(),
            ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _agregarPost,
            child: Text('Crear Post'),
          ),
        ],
      ),
    );
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
            return FbChat.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null);
          }).toList();

          if (chats.isEmpty) {
            return Center(child: Text("No hay chats disponibles."));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              FbChat chat = chats[index];
              return GestureDetector(
                onTap: () {
                  DataHolder().fbChatSelected = chat;
                  Navigator.of(context).pushNamed('/chatview');
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.sTitulo,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }


  String _limpiarBase64(String base64String) {
    if (base64String.startsWith('data:image')) {
      final index = base64String.indexOf('base64,');
      if (index != -1) {
        return base64String.substring(index + 7);
      }
    }
    return base64String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VinylHub"),
        backgroundColor: Colors.black54,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamed('/loginview');
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
      body: _selectedIndex == 0 ? (_isGridView ? _buildGridScreen() : _buildListScreen())  :
          _selectedIndex==1 ?
          _buildCreatePostScreen() :
          _buildPantallaChats(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Crear Post',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chats',
          ),

        ],
      ),
    );
  }
}
