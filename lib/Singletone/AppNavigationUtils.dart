import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../FbObjects/FbPost.dart';
import '../FbObjects/FbChat.dart';
import 'DataHolder.dart';

class AppNavigationUtils {
  static void onPostClicked(BuildContext context, FbPost post) {
    DataHolder().fbPostSelected = post;
    Navigator.of(context).pushNamed('/postdetails');
  }

  static Future<FbChat> crearNuevoChat() async {
    final firestore = FirebaseFirestore.instance;

    final post = DataHolder().fbPostSelected!;
    final String uidPost = post.uid;
    final String sPostAutorUid = post.sAutorUid;
    final String currentUid = FirebaseAuth.instance.currentUser!.uid;

    // Verificar si ya existe un chat entre este usuario y este post
    var chatQuery = await firestore
        .collection('Chats')
        .where('uidPost', isEqualTo: uidPost)
        .where('sPostAutorUid', isEqualTo: sPostAutorUid)
        .where('sAutorUid', isEqualTo: currentUid)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      var chatDoc = chatQuery.docs.first;
      FbChat chatExistente = FbChat.fromFirestore(chatDoc, null);
      DataHolder().fbChatSelected = chatExistente;
      return chatExistente;
    } else {
      // Crear nuevo chat
      String uid = firestore.collection('Chats').doc().id;
      String titulo = post.titulo;
      String imagenChat = post.imagenURLpost[0];

      FbChat nuevoChat = FbChat(
        uid: uid,
        sTitulo: titulo,
        sImagenURL: imagenChat,
        sAutorUid: currentUid,
        tmCreacion: Timestamp.now(),
        uidPost: uidPost,
        sPostAutorUid: sPostAutorUid,
        uidComprador: currentUid != sPostAutorUid ? currentUid : "desconocido",
      );

      // NO lo guardamos aún. Se guarda solo cuando se manda el primer mensaje.
      DataHolder().fbChatSelected = nuevoChat;
      return nuevoChat;
    }
  }


  /// Método que graba el chat en Firestore si no existe
  static Future<void> guardarChatSiNoExiste(FbChat chat) async {
    final docRef = FirebaseFirestore.instance.collection('Chats').doc(chat.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      await docRef.set(chat.toFirestore());
    }
  }
}
