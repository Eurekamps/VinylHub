import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../CustomViews/VinylBoton.dart';

class RegisterView extends StatefulWidget{
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {

  TextEditingController tecEmail= TextEditingController();
  TextEditingController tecPass= TextEditingController();
  TextEditingController tecPassRepeat= TextEditingController();

  void clickRegistrar(BuildContext context) async {
    if (tecPass.text == tecPassRepeat.text) {
      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: tecEmail.text,
          password: tecPass.text,
        );

        // Verificar si el usuario fue creado correctamente
        if (credential.user != null) {
          Fluttertoast.showToast(
            msg: "Usuario creado correctamente",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          // Navegar a la vista de login
          Navigator.of(context).pushNamed("/loginview");
        } else {
          throw Exception("El usuario no pudo ser creado.");
        }
      } on FirebaseAuthException catch (e) {
        // Manejar errores específicos de FirebaseAuth
        String errorMsg;
        switch (e.code) {
          case 'email-already-in-use':
            errorMsg = "Este correo ya está en uso.";
            break;
          case 'weak-password':
            errorMsg = "La contraseña es demasiado débil.";
            break;
          case 'invalid-email':
            errorMsg = "El formato del correo no es válido.";
            break;
          default:
            errorMsg = "Error inesperado: ${e.message}";
        }
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
        // Manejar cualquier otro tipo de error
        Fluttertoast.showToast(
          msg: "Error inesperado: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        print("Error no identificado: $e");
      }
    } else {
      // Contraseñas no coinciden
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
                  "Regístrate",
                  style: GoogleFonts.robotoMono(
                    color: Colors.black,
                    fontSize: 24, // Tamaño ajustado para que sea más legible
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: tecEmail,
                  decoration: InputDecoration(
                    labelText: 'E-Mail',
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
                TextFormField(
                  controller: tecPassRepeat,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VinylBoton(
                      sTitulo: "Registrar",
                      color: Colors.brown,
                      onBotonVinylPressed: (){clickRegistrar(context);},
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