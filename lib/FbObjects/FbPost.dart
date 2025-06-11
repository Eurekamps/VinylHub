import 'package:cloud_firestore/cloud_firestore.dart';

class FbPost {
  final String titulo;
  final String descripcion;
  final String artista;
  final int anio;
  final int precio;
  final List<String> imagenURLpost; // Lista de URLs de imágenes
  final List<String> categoria;    // Lista de categorías
  final String uid;
  final String sAutorUid;
  String estado;
  String? compradorUid;

  FbPost({
    required this.titulo,
    required this.descripcion,
    required this.artista,
    required this.anio,
    required this.precio,
    required this.imagenURLpost,
    required this.categoria,
    required this.uid,
    required this.sAutorUid,
    required this.estado,
    this.compradorUid
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'artista': artista,
      'anio': anio,
      'precio': precio,
      'imagenURLpost': imagenURLpost, // Guardar como lista
      'categoria': categoria,         // Guardar como lista
      'id': uid,
      'sAutorUid':sAutorUid,
    };
  }

  // Método para convertir un documento Firestore en un objeto FbPost
  static FbPost fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FbPost(
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      artista: data['artista'] ?? '',
      anio: data['anio'] ?? 0,
      precio: data['precio'] ?? 0,
      imagenURLpost: List<String>.from(data['imagenURLpost'] ?? []),
      categoria: List<String>.from(data['categoria'] ?? []),
      uid: doc.id,
      sAutorUid: data['sAutorUid'] ?? '',
      estado: data['estado'] ?? 'disponible',
      compradorUid: data['compradorUid'],

    );
  }

  // Convertir un objeto JSON en un FbPost
  factory FbPost.fromJson(Map<String, dynamic> json) {
    return FbPost(
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      artista: json['artista'],
      anio: json['anio'],
      precio: json['precio'],
      imagenURLpost: List<String>.from(json['imagenURLpost']),
      categoria: List<String>.from(json['categoria']),
      uid: json['id'],
      sAutorUid: json['sAutorUid'],
      estado: json['estado'] ?? 'disponible',

    );
  }

}
