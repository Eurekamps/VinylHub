import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  File? _avatar;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _apodoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    await DataHolder().obtenerPerfilDeFirestore(FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      if (DataHolder().miPerfil != null) {
        _nombreController.text = DataHolder().miPerfil!.nombre ?? '';
        _edadController.text = DataHolder().miPerfil!.edad.toString() ?? '';
        _apodoController.text = DataHolder().miPerfil!.apodo ?? '';
        _avatar = null;
      }
    });
  }

  Future<void> _pickAvatar() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Tomar foto'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _avatar = File(pickedFile.path);
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Seleccionar de la galería'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _avatar = File(pickedFile.path);
                  });
                }
              },
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
        title: Text("Editar Perfil"),
        backgroundColor: Colors.grey,
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
                    ? FileImage(_avatar!) as ImageProvider
                    : (DataHolder().miPerfil != null && DataHolder().miPerfil!.imagenURL.isNotEmpty
                    ? NetworkImage(DataHolder().miPerfil!.imagenURL) as ImageProvider
                    : AssetImage('assets/default-profile.png') as ImageProvider),
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

    if (_avatar != null) {
      try {
        print("Subiendo nueva imagen...");
        imagenURL = await FirebaseAdmin().subirImagen(_avatar!);
        print("Imagen subida con éxito: ${imagenURL.length} caracteres");
      } catch (e) {
        print("Error al subir la imagen: $e");
        return;
      }
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No hay usuario logueado.");
        return;
      }

      await FirebaseFirestore.instance.collection('perfiles').doc(user.uid).update({
        'nombre': nombre,
        'edad': int.tryParse(edad) ?? 0,
        'apodo': apodo,
        'imagenURL': imagenURL,
      });

      print("Perfil actualizado correctamente en Firestore.");

      setState(() {
        DataHolder().miPerfil!.nombre = nombre;
        DataHolder().miPerfil!.edad = int.tryParse(edad) ?? 0;
        DataHolder().miPerfil!.apodo = apodo;
        DataHolder().miPerfil!.imagenURL = imagenURL;
      });

      Navigator.of(context).pushNamed('/homeview');
    } catch (e) {
      print("Error al actualizar el perfil en Firestore: $e");
    }
  }
}
