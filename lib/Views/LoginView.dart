import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../AdminClasses/FirebaseAdmin.dart';
import '../FbObjects/FbPerfil.dart';
import 'package:vinylhub/Singletone/DataHolder.dart';

import '../CustomViews/VinylBoton.dart';

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
                  obscureText: obscureText, // Controla si la contraseña está oculta o visible
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
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureText = !obscureText; // Alterna entre ocultar y mostrar
                        });
                      },
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
                      onBotonVinylPressed: () async {
                        await FirebaseAdmin().clickLogin(
                            email: tecUser.text,
                            password: tecPass.text,
                            context: context
                        );
                      },
                    ),
                    VinylBoton(
                      sTitulo: "Registro",
                      color: Colors.brown,
                      onBotonVinylPressed: () { Navigator.of(context).pushNamed('/registerview'); },
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
