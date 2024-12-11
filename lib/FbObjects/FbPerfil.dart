import 'package:cloud_firestore/cloud_firestore.dart';

class FbPerfil {
  String apodo;
  int edad;
  String imagenURL;
  String nombre;
  String uid;

  FbPerfil({
    required this.nombre,
    required this.edad,
    required this.apodo,
    required this.imagenURL,
    required this.uid,
  });

  // Ajuste para manejar datos nulos en Firestore
  factory FbPerfil.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();

    // Verificación de null en caso de que no existan los datos en el snapshot
    if (data == null) {
      throw Exception('No se pudo obtener el perfil: datos nulos');
    }

    return FbPerfil(
      nombre: data['nombre'] ?? '', // Valor por defecto si es nulo
      edad: data['edad'] ?? 0,      // Valor por defecto si es nulo
      apodo: data['apodo'] ?? '',    // Valor por defecto si es nulo
      imagenURL: data['imagenURL'] ?? '',  // Valor por defecto si es nulo
      uid: data['uid'] ?? '',        // Valor por defecto si es nulo
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'edad': edad,
      'imagenURL': imagenURL,
      'apodo': apodo,
      'uid': uid,
    };
  }
}
