import 'package:cloud_firestore/cloud_firestore.dart';

class FbPerfil {
  String apodo;
  int edad;
  String imagenURL;
  String nombre;
  String uid;
  double? latitud;
  double? longitud;

  FbPerfil({
    required this.nombre,
    required this.edad,
    required this.apodo,
    required this.imagenURL,
    required this.uid,
    this.latitud,
    this.longitud,
  });

  factory FbPerfil.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();

    if (data == null) {
      throw Exception('No se pudo obtener el perfil: datos nulos');
    }

    return FbPerfil(
      nombre: data['nombre'] ?? '',
      edad: data['edad'] ?? 0,
      apodo: data['apodo'] ?? '',
      imagenURL: data['imagenURL'] ?? '',
      uid: data['uid'] ?? '',
      latitud: (data['latitud'] as num?)?.toDouble(),
      longitud: (data['longitud'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'edad': edad,
      'imagenURL': imagenURL,
      'apodo': apodo,
      'uid': uid,
      'latitud': latitud,
      'longitud': longitud,
    };
  }
}
