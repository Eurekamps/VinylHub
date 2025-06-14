import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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

  double? _latitud;
  double? _longitud;



  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }


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

  Future<void> _obtenerUbicacion() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print("Permiso de ubicación denegado.");
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _latitud = position.latitude;
      _longitud = position.longitude;
    });
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
        latitud: _latitud,
        longitud: _longitud,
      );


      await FirebaseAdmin().crearPerfil(perfil);
      setState(() => blUploading = false);
      Navigator.of(context).pushNamed('/homeview');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text("Seleccionar de la Galería"),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Tomar Foto"),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.camera);
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
      backgroundColor: Colors.grey[200], // Fondo gris claro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Quita la flecha atrás
      ),
      body: blUploading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, // Fondo blanco para el contenedor
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 4),
                blurRadius: 6,
              ),
            ],
          ),
          width: 320,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Completa Tu Perfil",
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                    _avatar != null ? FileImage(_avatar!) : null,
                    child: _avatar == null
                        ? const Icon(
                      Icons.add_a_photo,
                      size: 50,
                      color: Colors.grey,
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  hintText: 'Nombre',
                  controller: _nombre,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  hintText: 'Edad',
                  controller: _edad,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  hintText: 'Apodo',
                  controller: _apodo,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _clickRegistro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100], // Gris claro botón
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    elevation: 4,
                  ),
                  child: const Text(
                    "Registrar",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
