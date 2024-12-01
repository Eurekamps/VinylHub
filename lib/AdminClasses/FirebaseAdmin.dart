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
      final ref = FirebaseFirestore.instance.collection("Perfiles")
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

}