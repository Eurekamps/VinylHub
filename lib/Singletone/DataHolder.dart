import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hijos_de_fluttarkia/FbObjects/FbChat.dart';
import 'package:hijos_de_fluttarkia/Singletone/PlatformAdmin.dart';

import '../FbObjects/FbPerfil.dart';
import '../FbObjects/FbPost.dart';

class DataHolder {

  static final DataHolder _instance = DataHolder._internal();


  FbPerfil? miPerfil;
  FbChat? fbChatSelected;
  PlatformAdmin? platformAdmin;
  FbPost? fbPostSelected;
  List<FbPost> arPosts=[];



  DataHolder._internal();

  factory DataHolder(){
    return _instance;
  }

  void initPlatformAdmin(BuildContext context){
    platformAdmin = PlatformAdmin(context: context);
  }


  Future<List<FbChat>> descargarTodosChats() async{
    List<FbChat> arTemp=[];
    var db = FirebaseFirestore.instance;

    final ref = db.collection('Chats').withConverter(
      fromFirestore: FbChat.fromFirestore,
      toFirestore: (FbChat post, _) => post.toFirestore(),
    );
    final querySnap = await ref.get();

    for(QueryDocumentSnapshot<FbChat> doc in querySnap.docs){
      arTemp.add(doc.data());
    }

    return arTemp;
  }

}