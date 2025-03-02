import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../AdminClasses/FirebaseAdmin.dart';
import '../FbObjects/FbPerfil.dart';
import 'package:vinylhub/Singletone/DataHolder.dart';

import '../CustomViews/VinylBoton.dart';
import '../Services/AuthService.dart';

class LoginView extends StatefulWidget{
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {

  TextEditingController tecUser = TextEditingController();
  TextEditingController tecPass = TextEditingController();
  bool obscureText = true; // Variable para ocultar/mostrar la contraseña

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200], // Fondo gris claro
        ),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(20), // Ajuste en el padding
            decoration: BoxDecoration(
              color: Colors.white, // Fondo blanco para el contenedor
              borderRadius: BorderRadius.circular(24), // Bordes más redondeados
              boxShadow: [
                BoxShadow(
                  color: Colors.black26, // Sombra suave
                  offset: Offset(0, 4),
                  blurRadius: 6,
                ),
              ],
            ),
            width: 320, // Ancho del contenedor ajustado
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Inicia Sesión En Tu Cuenta",
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 26, // Título más grande
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: tecUser,
                  decoration: InputDecoration(
                    labelText: 'E-Mail',
                    labelStyle: TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: tecPass,
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureText = !obscureText;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 24),
                VinylBoton(
                  sTitulo: "Login",
                  color: Colors.black54, // Color marrón más oscuro
                  borderRadius: BorderRadius.circular(12), // Bordes redondeados para el botón
                  onBotonVinylPressed: () async {
                    await FirebaseAdmin().clickLogin(
                      email: tecUser.text,
                      password: tecPass.text,
                      context: context,
                    );
                  },
                ),
                SizedBox(height: 16),
                VinylBoton(
                  sTitulo: "Registro",
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12), // Bordes redondeados para el botón
                  onBotonVinylPressed: () {
                    Navigator.of(context).pushNamed('/registerview');
                  },
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Bordes redondeados para el botón
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    User? user = await AuthService().signInWithGoogle();
                    if (user != null) {
                      await AuthService().checkUserProfile(context);
                      print("Usuario autenticado: ${user.displayName}");
                    } else {
                      print("Error al iniciar sesión con Google");
                    }
                  },
                  icon: Image.asset(
                    'assets/google_logo.png',
                    height: 24,
                  ),
                  label: Text(
                    "Iniciar sesión con Google",
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
