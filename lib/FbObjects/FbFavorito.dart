import 'package:cloud_firestore/cloud_firestore.dart';

class FbFavorito{
  String uidPost;

  FbFavorito({

    required this.uidPost,

  });

  factory FbFavorito.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,) {
    final data = snapshot.data();
    return FbFavorito(
      uidPost: data?['uidPost'] != null ? data!['uidPost'] : "",
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "uidPost": uidPost
    };
  }
}