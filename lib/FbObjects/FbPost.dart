import 'package:cloud_firestore/cloud_firestore.dart';

class FbPost {
  final String titulo;
  final String descripcion;
  final int precio;
  final List<String> imagenURLpost; // Lista de URLs de imágenes
  final List<String> categoria;    // Lista de categorías
  final String uid;
  final String sAutorUid;

  FbPost({
    required this.titulo,
    required this.descripcion,
    required this.precio,
    required this.imagenURLpost,
    required this.categoria,
    required this.uid,
    required this.sAutorUid
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio,
      'imagenURLpost': imagenURLpost, // Guardar como lista
      'categoria': categoria,         // Guardar como lista
      'id': uid,
      'sAutorUid':sAutorUid
    };
  }

  // Método para convertir un documento Firestore en un objeto FbPost
  static FbPost fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FbPost(
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      precio: data['precio'] ?? 0,
      imagenURLpost: List<String>.from(data['imagenURLpost'] ?? []),
      categoria: List<String>.from(data['categoria'] ?? []),
      uid: doc.id,
      sAutorUid: data['sAutorUid'] ?? ''
    );
  }
}
