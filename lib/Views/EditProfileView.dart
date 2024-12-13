import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../AdminClasses/FirebaseAdmin.dart';
import '../Singletone/DataHolder.dart';

class EditProfileView extends StatefulWidget {
  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final ImagePicker _picker = ImagePicker();
  dynamic _avatar;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _apodoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _pickAvatar() async {
    if (kIsWeb) {
      final completer = Completer<Uint8List>();
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files!.isNotEmpty) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(files[0]);
          reader.onLoadEnd.listen((e) {
            completer.complete(reader.result as Uint8List);
          });
        } else {
          completer.complete(null);
        }
      });

      final image = await completer.future;
      if (image != null) {
        setState(() {
          _avatar = image;
        });
      }
    } else {
      final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _avatar = File(pickedImage.path);
        });
      }
    }
  }

  Future<void> _cargarPerfil() async {
    await DataHolder().obtenerPerfilDeFirestore(FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      if (DataHolder().miPerfil != null) {
        _nombreController.text = DataHolder().miPerfil!.nombre ?? '';
        _edadController.text = DataHolder().miPerfil!.edad.toString() ?? '';
        _apodoController.text = DataHolder().miPerfil!.apodo ?? '';

        // Solo usar _avatar si es Base64, de lo contrario mostrar URL o predeterminado
        _avatar = null;
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Editar Perfil"),
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _avatar != null
                    ? (kIsWeb
                    ? MemoryImage(_avatar as Uint8List) // Uint8List para web
                    : FileImage(_avatar as File) as ImageProvider) // File para móviles
                    : (DataHolder().miPerfil != null &&
                    DataHolder().miPerfil!.imagenURL.isNotEmpty
                    ? (DataHolder().miPerfil!.imagenURL.startsWith("data:image")
                    ? MemoryImage(base64Decode(DataHolder()
                    .miPerfil!
                    .imagenURL
                    .split(',')[1])) as ImageProvider
                    : NetworkImage(
                    DataHolder().miPerfil!.imagenURL) as ImageProvider)
                    : AssetImage('assets/default-profile.png')
                as ImageProvider),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _edadController,
              decoration: InputDecoration(labelText: 'Edad'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _apodoController,
              decoration: InputDecoration(labelText: 'Apodo'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Actualizar Perfil'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    String nombre = _nombreController.text;
    String edad = _edadController.text;
    String apodo = _apodoController.text;
    String imagenURL = DataHolder().miPerfil!.imagenURL;

    // Si se seleccionó una nueva imagen
    if (_avatar != null && _avatar is Uint8List) {
      try {
        print("Subiendo nueva imagen desde Web...");
        imagenURL = await FirebaseAdmin().subirImagen(_avatar); // Codificar imagen en Base64
        print("Imagen subida con éxito: ${imagenURL.length} caracteres");
      } catch (e) {
        print("Error al subir la imagen: $e");
        return; // Si falla la subida, no continuar con la actualización
      }
    }

    // Actualizar el perfil en Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No hay usuario logueado.");
        return;
      }

      // Actualizamos la base de datos con la nueva imagen URL (si fue modificada)
      await FirebaseFirestore.instance.collection('perfiles').doc(user.uid).update({
        'nombre': nombre,
        'edad': int.tryParse(edad) ?? 0,
        'apodo': apodo,
        'imagenURL': imagenURL, // Mantener la imagenURL (ya sea Base64 o predeterminada)
      });

      print("Perfil actualizado correctamente en Firestore.");

      // Actualizar localmente en DataHolder
      setState(() {
        DataHolder().miPerfil!.nombre = nombre;
        DataHolder().miPerfil!.edad = int.tryParse(edad) ?? 0;
        DataHolder().miPerfil!.apodo = apodo;
        DataHolder().miPerfil!.imagenURL = imagenURL;
      });

      Navigator.of(context).pushNamed('/homeview'); // Regresar a la pantalla anterior
    } catch (e) {
      print("Error al actualizar el perfil en Firestore: $e");
    }
  }

}
