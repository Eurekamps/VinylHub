import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../FbObjects/FbPerfil.dart';
import '../Singletone/DataHolder.dart';
// Asegúrate de importar tu modelo de perfil

class FirebaseAdmin {

  TextEditingController tecEmail = TextEditingController();
  TextEditingController tecPass = TextEditingController();
  TextEditingController tecPassRepeat = TextEditingController();


  Future<void> clickLogin({
    required BuildContext context,
    required String password,
    required String email,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = FirebaseAuth.instance.currentUser!.uid;
      print("UID del perfil: $uid");

      // Referencia al documento del perfil
      final ref = FirebaseFirestore.instance.collection("perfiles")
          .doc(uid)
          .withConverter(
        fromFirestore: FbPerfil.fromFirestore,
        toFirestore: (FbPerfil perfil, _) => perfil.toFirestore(),
      );

      // Obtener el documento del perfil
      final docSnap = await ref.get();

      if (!docSnap.exists) {
        print("El documento no existe, redirigiendo a ProfileView...");
        Navigator.of(context).pushNamed('/profileview');
        return; // Detener ejecución aquí
      }

      DataHolder().miPerfil = docSnap.data();
      print("Datos del perfil: ${DataHolder().miPerfil}");

      // Verificar si el perfil está completo
      final perfil = DataHolder().miPerfil;
      if (perfil != null &&
          perfil.nombre.isNotEmpty &&
          perfil.edad > 0 &&
          perfil.apodo.isNotEmpty &&
          perfil.imagenURL.isNotEmpty) {
        print("Perfil completo, redirigiendo a HomeView...");
        Navigator.of(context).pushNamed('/homeview');
      } else {
        print("Perfil incompleto, redirigiendo a ProfileView...");
        Navigator.of(context).pushNamed('/profileview');
      }
    } on FirebaseAuthException catch (e) {
      // Manejo de errores de autenticación
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
  }


  Future<void> registrarperfilCompleto({
    required String nombre,
    required int edad,
    required String apodo,
    File? avatar, // Cambiado a File? en lugar de dynamic
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No hay perfil autenticado.");
    }

    // Subir avatar si está disponible
    String imagenURL = "https://www.example.com/default-profile-image.png";
    if (avatar != null) {
      try {
        imagenURL = await subirImagen(avatar); // Pasamos el archivo en lugar del UID
        print("Imagen subida correctamente: $imagenURL");
      } catch (e) {
        print("Error al subir la imagen: $e");
        rethrow; // Relanzar para que el flujo principal lo maneje
      }
    } else {
      print("No se seleccionó avatar. Usando imagen predeterminada.");
    }

    // Crear perfil
    FbPerfil perfil = FbPerfil(
      uid: user.uid,
      nombre: nombre,
      apodo: apodo,
      edad: edad,
      imagenURL: imagenURL,
    );

    try {
      await crearPerfil(perfil);
      print("Perfil creado correctamente.");
    } catch (e) {
      print("Error al crear perfil: $e");
      rethrow;
    }
  }



  // Registrar un nuevo perfil
  Future<void> clickRegistrar(BuildContext context, {required String email, required String password, required String passwordRepeat}) async {
    if (password == passwordRepeat) {
      try {
        // Intentamos registrar el perfil con el email y la contraseña
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Verificamos si el perfil fue creado
        if (credential.user != null) {
          Fluttertoast.showToast(
            msg: "perfil creado correctamente",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          // Navegar a la vista de login
          Navigator.of(context).pushNamed("/loginview");
        } else {
          throw Exception("El perfil no pudo ser creado.");
        }
      } on FirebaseAuthException catch (e) {
        String errorMsg = _getFirebaseErrorMessage(e);
        Fluttertoast.showToast(
          msg: errorMsg,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        print("Error de FirebaseAuth: ${e.code} - ${e.message}");
      } catch (e) {
        print("Error inesperado: $e");
        Fluttertoast.showToast(
          msg: "Error inesperado: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } else {
      // Las contraseñas no coinciden
      Fluttertoast.showToast(
        msg: "Las contraseñas no coinciden",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<String> subirImagen(File avatar) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No hay usuario autenticado");
      }

      final storageRef = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
      await storageRef.putFile(avatar);
      String imageUrl = await storageRef.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print("Error al subir la imagen: $e");
      throw e;
    }
  }

  Future<String?> subirImagenAFirebase(XFile imagen) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageReference = FirebaseStorage.instance.ref().child('imagenes/$fileName');

      // Subir archivo XFile a Firebase Storage
      final uploadTask = storageReference.putFile(File(imagen.path));
      final snapshot = await uploadTask.whenComplete(() => null);

      // Obtener la URL de la imagen subida
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      print("Error al subir la imagen a Firebase: $e");
      return null;
    }
  }



  // Obtener el mensaje de error de Firebase
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "Este correo ya está en uso.";
      case 'weak-password':
        return "La contraseña es demasiado débil.";
      case 'invalid-email':
        return "El formato del correo no es válido.";
      default:
        return "Error inesperado: ${e.message}";
    }
  }

  // Crear un perfil de perfil
  Future<void> crearPerfil(FbPerfil perfil) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No hay perfil autenticado.");
        return;
      }

      // Guardar datos del perfil en Firestore
      await FirebaseFirestore.instance.collection('perfiles').doc(user.uid).set(perfil.toFirestore());

      print("Perfil guardado correctamente en Firestore.");
    } catch (e) {
      print("Error al guardar el perfil en Firestore: $e");
      rethrow;
    }
  }


  // Descargar perfil de perfil desde Firestore
  Future<FbPerfil?> descargarPerfil(String uid) async {
    try {
      final ref = FirebaseFirestore.instance.collection("perfiles").doc(uid).withConverter(
        fromFirestore: FbPerfil.fromFirestore,
        toFirestore: (FbPerfil perfil, _) => perfil.toFirestore(),
      );

      final docSnap = await ref.get();
      if (docSnap.exists) {
        return docSnap.data();
      } else {
        print("No se encontró el perfil del perfil.");
        return null;
      }
    } catch (e) {
      print("Error al descargar perfil: $e");
      return null;
    }
  }


  // Actualizar el perfil del perfil
  Future<void> actualizarPerfil(FbPerfil perfil) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No hay perfil autenticado.");
        return;
      }

      // Actualizar datos del perfil en Firestore
      await FirebaseFirestore.instance.collection('perfiles').doc(user.uid).update({
        'nombre': perfil.nombre,
        'edad': perfil.edad,
        'imagenURL': perfil.imagenURL,
        'apodo': perfil.apodo,
        'uid': perfil.uid
      });

      print("Perfil actualizado correctamente.");
    } catch (e) {
      print("Error al actualizar perfil: $e");
    }
  }

  // Descargar una colección de datos (por ejemplo, una lista de perfiles)
  Future<List<FbPerfil>> descargarColeccionperfiles() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection("perfiles").get();
      return querySnapshot.docs.map((doc) => FbPerfil.fromFirestore(doc, null)).toList();
    } catch (e) {
      print("Error al descargar la colección de perfiles: $e");
      return [];
    }
  }

  // Insertar un nuevo elemento en una colección (por ejemplo, un nuevo perfil)
  Future<void> insertarperfil(FbPerfil perfil) async {
    try {
      await FirebaseFirestore.instance.collection("perfiles").doc(perfil.uid).set(perfil.toFirestore());

      print("perfil insertado correctamente.");
    } catch (e) {
      print("Error al insertar perfil: $e");
    }
  }

  Future<FbPerfil> getUserProfile() async { //funcion para cargar el perfil del usuario
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot<Map<String, dynamic>> docSnap = await firestore.collection(
        'perfiles').doc(uid).get(); // Realizamos el cast
    if (docSnap.exists) {
      return FbPerfil.fromFirestore(docSnap,
          null); // Asumiendo que tienes el método fromFirestore en FbPerfil.
    } else {
      throw Exception("perfil no encontrado");
    }
  }


}
