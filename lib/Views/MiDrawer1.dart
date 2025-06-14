import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vinylhub/AdminClasses/FirebaseAdmin.dart';
import '../FbObjects/FbPerfil.dart';
import '../Singletone/DataHolder.dart';

class MiDrawer1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FbPerfil>(
      future: FirebaseAdmin().getUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        FbPerfil perfil = snapshot.data!;

        return Drawer(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            margin: EdgeInsets.only(top: 50),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed('/editprofileview');
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: perfil.imagenURL.isNotEmpty
                            ? NetworkImage(perfil.imagenURL)
                            : AssetImage('assets/default-avatar.png') as ImageProvider,
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perfil.nombre,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            FirebaseAuth.instance.currentUser!.email.toString(),
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Divider(color: Colors.grey[300]),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.brown[700]),
                  title: const Text("Ajustes", style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.of(context).pushNamed('/ajustesview');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.local_shipping_outlined, color: Colors.teal),
                  title: const Text("Mis envíos", style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.of(context).pushNamed('/enviosview');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text("Cerrar sesión", style: TextStyle(fontSize: 16)),
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushNamed('/loginview');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
