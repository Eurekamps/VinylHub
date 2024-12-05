import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hijos_de_fluttarkia/FbObjects/FbChat.dart';

import '../FbObjects/FbPerfil.dart';

class DataHolder {

  static final DataHolder _instance = DataHolder._internal();


  FbPerfil? miPerfil;
  FbChat? fbChatSelected;


  DataHolder._internal();

  factory DataHolder(){
    return _instance;
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