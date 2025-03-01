import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//import 'dart:html' as html; // Importado para soporte de Web
import '../AdminClasses/FirebaseAdmin.dart';
import '../CustomViews/CustomTextField.dart';
import '../FbObjects/FbPerfil.dart';
import '../Singletone/DataHolder.dart';


class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _apodo = TextEditingController();
  final TextEditingController _edad = TextEditingController();
  File? _avatar;
  bool blUploading = false;

  Future<void> _pickAvatar(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _avatar = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final storageRef = FirebaseStorage.instance.ref().child("perfiles/${user.uid}.jpg");
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("Error al subir la imagen: $e");
      return null;
    }
  }

  void _clickRegistro() async {
    print("Iniciando registro...");
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => blUploading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No hay perfil autenticado.");
        setState(() => blUploading = false);
        return;
      }

      String imagenURL = "https://www.example.com/default-profile-image.png";
      if (_avatar != null) {
        final uploadedURL = await _uploadImage(_avatar!);
        if (uploadedURL != null) {
          imagenURL = uploadedURL;
        }
      }

      FbPerfil perfil = FbPerfil(
        uid: user.uid,
        nombre: _nombre.text,
        apodo: _apodo.text,
        edad: int.tryParse(_edad.text) ?? 0,
        imagenURL: imagenURL,
      );

      await FirebaseAdmin().crearPerfil(perfil);
      setState(() => blUploading = false);
      Navigator.of(context).pushNamed('/loginview');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.brown),
      body: blUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/coleccion.jpeg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              width: 300,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Registro", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => _pickAvatar(ImageSource.gallery),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _avatar != null ? FileImage(_avatar!) : null,
                        child: _avatar == null ? const Icon(Icons.add_a_photo, size: 50, color: Colors.grey) : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _pickAvatar(ImageSource.camera),
                      child: Text("Tomar foto"),
                    ),
                    CustomTextField(hintText: 'Nombre', controller: _nombre, keyboardType: TextInputType.text),
                    const SizedBox(height: 20),
                    CustomTextField(hintText: 'Edad', controller: _edad, keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    CustomTextField(hintText: 'Apodo', controller: _apodo, keyboardType: TextInputType.text),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _clickRegistro,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                      child: const Text("Registrar", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
