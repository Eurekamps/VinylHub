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
import 'dart:html' as html; // Importado para soporte de Web
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
  dynamic _avatar; // Puede ser Uint8List (Web) o File (Móvil)
  bool blUploading = false;

  // Método para seleccionar imagen
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
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _avatar = File(pickedImage.path);
        });
      }
    }
  }

  // Método para manejar el registro
  void _clickRegistro() async {
    print("Iniciando registro...");

    if (_formKey.currentState?.validate() ?? false) {
      print("Formulario válido");

      String nombre = _nombre.text;
      int edad = int.tryParse(_edad.text) ?? 0;
      String imagenURL = "https://www.example.com/default-profile-image.png"; // Imagen predeterminada
      String apodo = _apodo.text;

      try {
        // Verificar autenticación
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          print("No hay perfil autenticado.");
          return;
        } else {
          print("perfil autenticado: ${user.uid}");
        }

        // Verificar si se seleccionó un avatar
        if (_avatar != null && _avatar is Uint8List) {
          print("Avatar seleccionado. Almacenando como base64...");
          // Opcional: Convertir `_avatar` en base64 para almacenarlo directamente en Firestore
          imagenURL = "data:image/jpeg;base64,${base64Encode(_avatar)}";
        } else {
          print("No hay avatar seleccionado. Usando imagen predeterminada.");
        }

        // Crear el perfil
        FbPerfil perfil = FbPerfil(
          uid: user.uid,
          nombre: nombre,
          apodo: apodo,
          edad: edad,
          imagenURL: imagenURL,
        );

        print("Creando perfil con los datos: $perfil");
        await FirebaseAdmin().crearPerfil(perfil);
        print("Perfil creado correctamente.");

        // Navegar a login
        print("Navegando a /loginview...");
        Navigator.of(context).pushNamed('/loginview');
      } catch (e) {
        print("Error al registrar al perfil: $e");
      }
    } else {
      print("Formulario no válido.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
      ),
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
                    Text(
                      "Registro",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _avatar != null
                            ? (kIsWeb
                            ? MemoryImage(_avatar)
                            : FileImage(_avatar) as ImageProvider)
                            : null,
                        child: _avatar == null
                            ? const Icon(Icons.add_a_photo,
                            size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: 'Nombre',
                      imageUrl:
                      "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
                      controller: _nombre,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: 'Edad',
                      imageUrl:
                      "https://cdn-icons-png.flaticon.com/512/1087/1087815.png",
                      controller: _edad,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: 'Apodo',
                      imageUrl:
                      "https://cdn-icons-png.flaticon.com/512/847/847969.png",
                      controller: _apodo,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _clickRegistro,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Registrar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
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
