import 'package:cloud_firestore/cloud_firestore.dart';

class FbMensaje {
  String sCuerpo;
  String sAutorUid;
  String sReceptorUid; // NUEVO
  String sImgUrl;
  Timestamp tmCreacion;
  String sAutorNombre;

  FbMensaje({
    required this.sCuerpo,
    required this.sAutorUid,
    required this.sReceptorUid, // NUEVO
    required this.sImgUrl,
    required this.tmCreacion,
    required this.sAutorNombre,
  });

  factory FbMensaje.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return FbMensaje(
      sCuerpo: data['sCuerpo'] ?? '',
      sImgUrl: data['sImgUrl'] ?? '',
      sAutorUid: data['sAutorUid'] ?? '',
      sReceptorUid: data['sReceptorUid'] ?? '', // NUEVO
      tmCreacion: data['tmCreacion'] ?? Timestamp.now(),
      sAutorNombre: data['sAutorNombre'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "sCuerpo": sCuerpo,
      "sImgUrl": sImgUrl,
      "sAutorUid": sAutorUid,
      "sReceptorUid": sReceptorUid, // NUEVO
      "tmCreacion": tmCreacion,
      "sAutorNombre": sAutorNombre,
    };
  }
}
