import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../AdminClasses/FirebaseAdmin.dart';
import '../FbObjects/FbPost.dart';


class EditPost extends StatefulWidget {
  final FbPost post;

  const EditPost({super.key, required this.post});

  @override
  State<EditPost> createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _artistaController;
  late TextEditingController _anioController;
  late TextEditingController _precioController;
  List<String> _categoriasSeleccionadas = [];
  List<String> _imagenURLs = [];

  final List<String> _todasCategorias = [
    'Rock', 'Pop', 'R&B', 'Hip-Hop', 'Soul', 'Clásica',
    'Heavy Metal', 'Jazz', 'Neo Soul', 'Blues', 'Folk',
    'Reggae', 'Country', 'Electrónica', 'Punk', 'Funk',
    'Disco', 'Indie', 'Latino', 'Gospel', 'Experimental',
    'House', 'Techno', 'Ambient', 'Trance', 'Ska'
  ];

  @override
  void initState() {
    super.initState();
    final post = widget.post;

    _tituloController = TextEditingController(text: post.titulo);
    _descripcionController = TextEditingController(text: post.descripcion);
    _artistaController = TextEditingController(text: post.artista);
    _anioController = TextEditingController(text: post.anio.toString());
    _precioController = TextEditingController(text: post.precio.toString());
    _categoriasSeleccionadas = List.from(post.categoria);
    _imagenURLs = List.from(post.imagenURLpost);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _artistaController.dispose();
    _anioController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _actualizarPost() async {
    if (_formKey.currentState!.validate()) {
      FbPost postActualizado = FbPost(
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        artista: _artistaController.text.trim(),
        anio: int.tryParse(_anioController.text.trim()) ?? 0,
        precio: int.tryParse(_precioController.text.trim()) ?? 0,
        imagenURLpost: _imagenURLs,
        categoria: _categoriasSeleccionadas,
        uid: widget.post.uid,
        sAutorUid: widget.post.sAutorUid,
      );

      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(widget.post.uid)
          .update(postActualizado.toMap());

      Navigator.pop(context, postActualizado);
    }
  }

  Future<void> _seleccionarYSubirImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagenSeleccionada = await picker.pickImage(source: ImageSource.gallery);

    if (imagenSeleccionada != null) {
      String? url = await FirebaseAdmin().subirImagenAFirebase(imagenSeleccionada);
      if (url != null) {
        setState(() {
          _imagenURLs.add(url);
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Post"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCampoTexto("Título", _tituloController),
              _buildCampoTexto("Artista", _artistaController),
              _buildCampoTexto("Año de edición", _anioController,
                  tipo: TextInputType.number),
              _buildCampoTexto("Descripción", _descripcionController,
                  maxLines: 4),
              _buildCampoTexto("Precio (€)", _precioController,
                  tipo: TextInputType.number),
              const SizedBox(height: 16),
              _buildSelectorCategorias(),
              const SizedBox(height: 16),
              _buildVistaImagenes(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Guardar cambios"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: _actualizarPost,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampoTexto(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType tipo = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: tipo,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? 'Este campo es obligatorio' : null,
      ),
    );
  }

  Widget _buildSelectorCategorias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Categorías", style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: _todasCategorias.map((categoria) {
            final seleccionada = _categoriasSeleccionadas.contains(categoria);
            return FilterChip(
              label: Text(categoria),
              selected: seleccionada,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _categoriasSeleccionadas.add(categoria);
                  } else {
                    _categoriasSeleccionadas.remove(categoria);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVistaImagenes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Imágenes actuales:",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _imagenURLs.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == _imagenURLs.length) {
                // Botón de agregar imagen
                return GestureDetector(
                  onTap: _seleccionarYSubirImagen,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_a_photo, size: 40, color: Colors.black54),
                  ),
                );
              } else {
                final url = _imagenURLs[index];
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(url, height: 120, width: 120, fit: BoxFit.cover),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _imagenURLs.removeAt(index);
                        });
                      },
                    ),
                  ],
                );
              }
            },
          ),
        )
      ],
    );
  }


}
