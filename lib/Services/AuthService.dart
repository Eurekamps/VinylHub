import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      // Iniciar sesión con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Crear credenciales para Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Error en Google Sign-In: $e");
      return null;
    }
  }

  Future<void> checkUserProfile(BuildContext context) async {
    try {
      // Obtén el usuario actual de Firebase
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Consulta en Firestore si el perfil del usuario existe
        final perfilDoc = await FirebaseFirestore.instance
            .collection('perfiles')
            .doc(user.uid)
            .get();

        // Verifica si el documento existe
        if (perfilDoc.exists) {
          // Obtiene los datos del perfil
          final perfilData = perfilDoc.data();

          // Verifica si el perfil tiene la información necesaria
          if (perfilData != null &&
              perfilData['nombre'] != null &&
              perfilData['nombre'].isNotEmpty &&
              perfilData['apodo'] != null &&
              perfilData['apodo'].isNotEmpty &&
              perfilData['edad'] != null &&
              perfilData['edad'] > 0 &&
              perfilData['imagenURL'] != null &&
              perfilData['imagenURL'].isNotEmpty) {
            print("Perfil completo, redirigiendo a HomeView...");
            Navigator.of(context).pushNamed('/homeview');
          } else {
            print("Perfil incompleto, redirigiendo a ProfileView...");
            Navigator.of(context).pushNamed('/profileview');
          }
        } else {
          // Si no existe el perfil en Firestore, redirige al ProfileView
          print("Perfil no encontrado, redirigiendo a ProfileView...");
          Navigator.of(context).pushNamed('/profileview');
        }
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

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
