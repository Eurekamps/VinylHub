import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../FbObjects/FbPerfil.dart';
import '../Singletone/DataHolder.dart';
// Asegúrate de importar tu modelo de perfil

class FirebaseAdmin {

  TextEditingController tecEmail = TextEditingController();
  TextEditingController tecPass = TextEditingController();
  TextEditingController tecPassRepeat = TextEditingController();


  // Iniciar sesión con correo y contraseña
  Future<void> clickLogin(
      {required BuildContext context, required String password, required String email}) async {
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

      if (docSnap.exists) {
        DataHolder().miPerfil = docSnap.data();
        print("Datos del perfil: ${DataHolder().miPerfil}");
      } else {
        print("El documento no existe");
        Navigator.of(context).pushNamed('/profileview');
      }

      if (DataHolder().miPerfil != null &&
          DataHolder().miPerfil!.nombre.isNotEmpty &&
          DataHolder().miPerfil!.edad > 0 &&
          DataHolder().miPerfil!.apodo.isNotEmpty &&
          DataHolder().miPerfil!.imagenURL.isNotEmpty) {
        // Redirigir a home si los datos están completos
        Navigator.of(context).pushNamed('/homeview');
      } else {
        // Redirigir a perfil para completar los datos
        Navigator.of(context).pushNamed('/profileview');
      }
    } on FirebaseAuthException catch (e) {
      // Manejo de excepciones
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
    dynamic avatar,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No hay perfil autenticado.");
    }

    // Subir avatar si está disponible
    String imagenURL = "https://www.example.com/default-profile-image.png";
    if (avatar != null) {
      try {
        imagenURL = await subirImagen(user.uid);
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

  Future<String> subirImagen(dynamic avatar) async {
    try {
      if (avatar is Uint8List) {
        print("Codificando imagen como Base64...");
        String base64String = base64Encode(avatar);
        print("Imagen codificada en Base64: ${base64String.length} caracteres");
        return "data:image/jpeg;base64,$base64String";
      } else {
        throw Exception("Formato de avatar no soportado. Debe ser Uint8List.");
      }
    } catch (e) {
      print("Error al subir la imagen: $e");
      throw e;
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
