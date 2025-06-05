import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../FbObjects/FbPerfil.dart';
import '../Singletone/DataHolder.dart';

class SeguidoresView extends StatelessWidget {
  final String uidUsuario;

  const SeguidoresView({super.key, required this.uidUsuario});

  Future<List<FbPerfil>> _obtenerSeguidores() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('perfiles')
        .doc(uidUsuario)
        .collection('seguidores')
        .get();

    List<FbPerfil> seguidores = [];
    for (var doc in snapshot.docs) {
      var perfilSnapshot = await firestore.collection('perfiles').doc(doc.id).get();
      if (perfilSnapshot.exists) {
        seguidores.add(FbPerfil.fromFirestore(perfilSnapshot, null));

      }
    }
    return seguidores;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seguidores')),
      body: FutureBuilder<List<FbPerfil>>(
        future: _obtenerSeguidores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          final seguidores = snapshot.data ?? [];
          if (seguidores.isEmpty) return Center(child: Text("Sin seguidores."));

          return ListView.builder(
            itemCount: seguidores.length,
            itemBuilder: (context, index) {
              final perfil = seguidores[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: perfil.imagenURL != null && perfil.imagenURL!.isNotEmpty
                      ? NetworkImage(perfil.imagenURL!)
                      : AssetImage('assets/default-profile.png') as ImageProvider,
                ),
                title: Text(perfil.nombre ?? "Usuario"),
                subtitle: Text(perfil.apodo ?? ""),
              );
            },
          );
        },
      ),
    );
  }
}
