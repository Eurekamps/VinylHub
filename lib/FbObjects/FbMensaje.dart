import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hijos_de_fluttarkia/AdminClasses/FirebaseAdmin.dart';

class FbMensaje{

  String sCuerpo;
  String sAutorUid;
  String sImgUrl;
  Timestamp tmCreacion;

  FbMensaje({
    required this.sCuerpo,
    required this.sAutorUid,
    required this.sImgUrl,
    required this.tmCreacion
  });

  factory FbMensaje.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,) {
    final data = snapshot.data();
    return FbMensaje(
      sCuerpo: data?['sCuerpo']!= null ? data!['sCuerpo']:"",
      sImgUrl: data?['sImgUrl']!= null ? data!['sImgUrl']:"",
      sAutorUid: data?['sAutorUid'] ?? "",
      tmCreacion:data?['tmCreacion']!= null ? data!['tmCreacion']:Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "sCuerpo": sCuerpo,
      "sImgUrl": sImgUrl,
      "sAutorUid":sAutorUid,
      "tmCreacion":tmCreacion,

    };
  }
}