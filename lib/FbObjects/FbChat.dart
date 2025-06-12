import 'package:cloud_firestore/cloud_firestore.dart';

class FbChat {
  String uid; // ID del chat
  String sTitulo;
  String sAutorUid; // UID del autor del post
  String sImagenURL;
  Timestamp tmCreacion;
  String uidPost;
  String sPostAutorUid;
  String uidComprador; // NUEVO CAMPO

  FbChat({
    required this.uid,
    required this.sTitulo,
    required this.sAutorUid,
    required this.sImagenURL,
    required this.tmCreacion,
    required this.uidPost,
    required this.sPostAutorUid,
    required this.uidComprador, // NUEVO
  });

  factory FbChat.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return FbChat(
      uid: snapshot.id,
      sTitulo: data['sTitulo'] ?? '',
      sAutorUid: data['sAutorUid'] ?? '',
      sImagenURL: data['sImagenURL'] ?? '',
      tmCreacion: data['tmCreacion'] ?? Timestamp.now(),
      uidPost: data['uidPost'] ?? '',
      sPostAutorUid: data['sPostAutorUid'] ?? '',
      uidComprador: data['uidComprador'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sTitulo': sTitulo,
      'sAutorUid': sAutorUid,
      'sImagenURL': sImagenURL,
      'tmCreacion': tmCreacion,
      'uidPost': uidPost,
      'sPostAutorUid': sPostAutorUid,
      'uidComprador': uidComprador, // NUEVO
    };
  }
}
