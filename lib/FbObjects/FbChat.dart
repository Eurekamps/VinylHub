import 'package:cloud_firestore/cloud_firestore.dart';

class FbChat{
  String uid;
  String sTitulo;
  String sAutorUid;
  String sImagenURL;
  Timestamp tmCreacion;
  String uidPost;
  String sPostAutorUid;  // Agregado

  FbChat({
    required this.uid,
    required this.sTitulo,
    required this.sAutorUid,
    required this.sImagenURL,
    required this.tmCreacion,
    required this.uidPost,
    required this.sPostAutorUid,  // Agregado
  });

  factory FbChat.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,) {
    final data = snapshot.data();
    return FbChat(
      sTitulo: data?['sTitulo'] != null ? data!['sTitulo'] : "",
      sAutorUid: data?['sAutorUid'] != null ? data!['sAutorUid'] : "",
      sImagenURL: data?['sImagenURL'] != null ? data!['sImagenURL'] : "",
      tmCreacion: data?['tmCreacion'] != null ? data!['tmCreacion'] : Timestamp.now(),
      uid: snapshot.id,
      uidPost: data?['uidPost'] ?? '',
      sPostAutorUid: data?['sPostAutorUid'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "sTitulo": sTitulo,
      "sImagenURL": sImagenURL,
      "sAutorUid": sAutorUid,
      "tmCreacion": tmCreacion,
      "uid": uid,
      "uidPost": uidPost,
      "sPostAutorUid": sPostAutorUid,  // Agregado
    };
  }
}
