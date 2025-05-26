import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vinylhub/AdminClasses/FirebaseAdmin.dart';

import '../CustomViews/VinylBoton.dart';

class RegisterView extends StatefulWidget{
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {

  TextEditingController tecEmail = TextEditingController();
  TextEditingController tecPass = TextEditingController();
  TextEditingController tecPassRepeat = TextEditingController();
  bool obscureText = true; // Variable para ocultar/mostrar contraseña

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
      backgroundColor: Colors.grey[200], // Fondo gris claro similar
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo VinylHub arriba
              Image.asset(
                'assets/app_icon.png', // Asegúrate que sea el logo VinylHub
                height: 80,
              ),
              SizedBox(height: 12),
              Text(
                "Regístrate",
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: tecEmail,
                decoration: InputDecoration(
                  labelText: 'E-Mail',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: tecPass,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,

                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: tecPassRepeat,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,

                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  elevation: 4,
                ),
                onPressed: () async {
                  await FirebaseAdmin().clickRegistrar(
                    context,
                    email: tecEmail.text.trim(),
                    password: tecPass.text,
                    passwordRepeat: tecPassRepeat.text,
                  );
                  // No necesitas Navigator aquí porque dentro de clickRegistrar ya haces pushNamed("/loginview")
                },
                child: Text(
                  "Registrar",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

}
