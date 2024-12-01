import 'package:cloud_firestore/cloud_firestore.dart';

class FbPost {
  String titulo;
  String descripcion;
  int precio;
  String imagenURLpost;
  String categoria;

  FbPost({
    required this.titulo,
    required this.descripcion,
    required this.precio,
    required this.imagenURLpost,
    required this.categoria
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio,
      'imagenURLpost': imagenURLpost,
      'categoria': categoria,
    };
  }

  factory FbPost.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return FbPost(
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      precio: data['precio'] ?? '',
      imagenURLpost: data['imagenURLpost'] ?? '',
      categoria: data['categoria'] ?? ''
    );
  }
}
