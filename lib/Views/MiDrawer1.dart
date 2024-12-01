import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../FbObjects/FbPerfil.dart';  // Asegúrate de tener este archivo con tu modelo FbPerfil.

class MiDrawer1 extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;  // Obtiene el UID del perfil logueado.

  // Función para obtener los datos del perfil desde Firestore
  Future<FbPerfil> _getUserProfile() async {
    DocumentSnapshot<Map<String, dynamic>> docSnap = await _firestore.collection('perfiles').doc(uid).get() as DocumentSnapshot<Map<String, dynamic>>;  // Realizamos el cast
    if (docSnap.exists) {
      return FbPerfil.fromFirestore(docSnap, null);  // Asumiendo que tienes el método fromFirestore en FbPerfil.
    } else {
      throw Exception("perfil no encontrado");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FbPerfil>(
      future: _getUserProfile(),  // Cargar los datos del perfil
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        FbPerfil perfil = snapshot.data!;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ), // Bordes redondeados
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Perfil de perfil en la parte superior del Drawer
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/editprofileview');  // Navegar a la pantalla de edición de perfil
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: perfil.imagenURL.isNotEmpty
                          ? NetworkImage(perfil.imagenURL)
                          : AssetImage('assets/default-avatar.png') as ImageProvider,
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(perfil.nombre, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Edad: ${perfil.edad}', style: TextStyle(fontSize: 14)),
                        Text('Rol: ${perfil.apodo}', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Opciones de menú del Drawer
              ListTile(
                leading: Icon(Icons.settings, color: Colors.brown),
                title: const Text("Ajustes"),
                onTap: () {Navigator.of(context).pushNamed('/ajustesview');}, // Agrega la acción que necesites aquí
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.brown),
                title: const Text("Cerrar sesión"),
                onTap: () {
                  // Función de cierre de sesión (que ya tienes en HomeView o donde sea que la uses)
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushNamed('/loginview');  // Redirige al login
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
