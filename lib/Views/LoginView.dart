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
      backgroundColor: Colors.grey[200], // Fondo negro
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
              // LOGO arriba
              Image.asset(
                'assets/app_icon.png',
                height: 80,
              ),
              SizedBox(height: 12),
              Text(
                "VinylHub",
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 26,
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
                  fillColor: Colors.white,
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
                  fillColor: Colors.white,
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
                  await FirebaseAdmin().clickLogin(
                    email: tecUser.text,
                    password: tecPass.text,
                    context: context,
                  );
                },
                child: Text(
                  "Login",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/registerview');
                },
                child: Text(
                  "Registro",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
    );
  }


}
