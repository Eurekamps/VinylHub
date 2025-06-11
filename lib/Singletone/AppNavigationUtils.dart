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
    String uidPost = DataHolder().fbPostSelected!.uid;
    String sPostAutorUid = DataHolder().fbPostSelected!.sAutorUid;
    String sAutorUid = FirebaseAuth.instance.currentUser!.uid;

    // Verificar si ya existe un chat
    var chatQuery = await firestore
        .collection('Chats')
        .where('uidPost', isEqualTo: uidPost)
        .where('sPostAutorUid', isEqualTo: sPostAutorUid)
        .where('sAutorUid', isEqualTo: sAutorUid)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      var chatDoc = chatQuery.docs.first;
      FbChat chatExistente = FbChat.fromFirestore(chatDoc, null);
      DataHolder().fbChatSelected = chatExistente;
      return chatExistente;
    } else {
      String uid = firestore.collection('Chats').doc().id;
      String titulo = DataHolder().fbPostSelected!.titulo;
      String imagenChat = DataHolder().fbPostSelected!.imagenURLpost[0];

      FbChat nuevoChat = FbChat(
        uid: uid,
        sTitulo: titulo,
        sImagenURL: imagenChat,
        sAutorUid: sAutorUid,
        tmCreacion: Timestamp.now(),
        uidPost: uidPost,
        sPostAutorUid: sPostAutorUid,
      );

      // Solo lo guardamos en Firestore cuando se mande el primer mensaje (puedes comentarlo por ahora)
      // await firestore.collection('Chats').doc(uid).set(nuevoChat.toFirestore());

      // Guardamos el chat en memoria
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
