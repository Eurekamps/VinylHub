import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../FbObjects/FbPerfil.dart';
import 'package:hijos_de_fluttarkia/Singletone/DataHolder.dart';

class LoginView extends StatefulWidget{
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {

  TextEditingController tecUser= TextEditingController();
  TextEditingController tecPass= TextEditingController();
  final db = FirebaseFirestore.instance;

  void clickLogin() async{
    try{
      final credential = await
      FirebaseAuth.instance.signInWithEmailAndPassword(email: tecUser.text, password: tecPass.text);
      final ref = db.collection("Perfiles").doc(FirebaseAuth.instance.currentUser!.uid).withConverter
        (fromFirestore: FbPerfil.fromFirestore, toFirestore: (FbPerfil perfil, _)=> perfil.toFirestore());

      final docSnap = await ref.get();
      DataHolder().miPerfil=docSnap.data();

      if(DataHolder().miPerfil!=null){
        Navigator.of(context).pushNamed('/homeview');
      }else{
        Navigator.of(context).pushNamed('/profileview');
      }
    }on FirebaseAuthException catch (e){
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
  }

  void clickRegistrar(){
    Navigator.of(context).pushNamed('/registerview');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/coleccion.jpeg'),
            fit: BoxFit.cover, // Asegura que la imagen cubra toda la pantalla
          ),
        ),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(16), // Margen interno para evitar que el texto toque los bordes
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5), // Fondo blanco semitransparente
              borderRadius: BorderRadius.circular(16), // Bordes redondeados para la caja
            ),
            width: 300, // Ancho del contenedor
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ajusta la altura al contenido
              children: [
                Text(
                  "Inicia Sesión En Tu Cuenta",
                  style: GoogleFonts.robotoMono(
                    color: Colors.black,
                    fontSize: 24, // Tamaño ajustado para que sea más legible
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: tecUser,
                  decoration: InputDecoration(
                    labelText: 'E-Mail',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.black, width: 2.0),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: tecPass,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    VinylBoton(
                      sTitulo: "Login",
                      color: Colors.brown,
                      onBotonVinylPressed: clickLogin,
                    ),
                    VinylBoton(
                      sTitulo: "Registro",
                      color: Colors.brown,
                      onBotonVinylPressed: clickRegistrar,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

  }
}