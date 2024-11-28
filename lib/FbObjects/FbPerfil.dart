import 'package:cloud_firestore/cloud_firestore.dart';

class FbPerfil{

  String apodo;
  int edad;
  String imagenURL;
  String nombre;

  FbPerfil({
    required this.nombre,
    required this.edad,
    required this.apodo,
    required this.imagenURL,
  });

  factory FbPerfil.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return FbPerfil(
      nombre: data?['nombre'] ,
      edad: data?['edad'],
      apodo: data?['apodo'],
      imagenURL:data?['imagenURL'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "nombre": nombre,
      "edad": edad,
      "imagenURL": imagenURL,
      "apodo": apodo,
    };
  }

}