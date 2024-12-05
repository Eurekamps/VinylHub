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
  bool _isGridView = false;
  List<FbChat> arChats = [];

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
        Navigator.of(contexto).pushNamed('/chatsview');
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

            return Card(
              margin: EdgeInsets.all(8),
              child: ListTile(
                title: Text(post.titulo),
                subtitle: Text('Categorías: ${post.categoria.join(', ')}'),
                trailing: post.imagenURLpost.isNotEmpty
                    ? Image.memory(
                  base64Decode(_limpiarBase64(post.imagenURLpost.first)),
                  width: 50,
                  height: 50,
                )
                    : null,
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 100),
        child: SizedBox(
          height: 450,
          child: arChats.isEmpty
              ? Center(child: CircularProgressIndicator()) // Muestra un indicador de carga mientras se obtienen los datos
              : ListView.builder(
            itemBuilder: _chatItemBuilder,
            itemCount: arChats.length,
          ),
        ),
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
        title: const Text("Mi App"),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamed('/loginview');
            },
          ),
        ],
      ),
      drawer: MiDrawer1(),
      body: _selectedIndex == 0 ? _buildListScreen() :
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
            icon: Icon(Icons.add_business),
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
