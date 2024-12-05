import 'package:cloud_firestore/cloud_firestore.dart';

class FbChat{
  String uid;
  String sTitulo;
  String sAutorUid;
  String sImagenURL;
  Timestamp tmCreacion;

  FbChat({
    required this.uid,
    required this.sTitulo,
    required this.sAutorUid,
    required this.sImagenURL,
    required this.tmCreacion

  });

  factory FbChat.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,) {
    final data = snapshot.data();
    return FbChat(
        sTitulo: data?['sTitulo'] != null ? data!['sTitulo']:"",
        sAutorUid: data?['sAutorUid']!= null ? data!['sAutorUid']:"",
        sImagenURL: data?['sImagenURL']!= null ? data!['sImagenURL']:"",
        tmCreacion:data?['tmCreacion']!= null ? data!['tmCreacion']:Timestamp.now(),
        uid: snapshot.id
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "sTitulo": sTitulo,
      "sImgUrl": sImagenURL,
      "sUidAutor":sAutorUid,
      "tmCreacion":tmCreacion,
    };
  }
}