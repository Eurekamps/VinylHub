import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hijos_de_fluttarkia/FbObjects/FbChat.dart';

import '../FbObjects/FbMensaje.dart';
import '../Singletone/DataHolder.dart';

class ChatView extends StatefulWidget{

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  List<FbMensaje> arFbMensajes=[];
  TextEditingController controller = TextEditingController();
  TextEditingController imgcontroller = TextEditingController();
  var db = FirebaseFirestore.instance;
  String sRutaChatMensajes="/Chats/"+DataHolder().fbChatSelected!.uid+"/mensajes";

  @override
  void initState() {
    // TODO: implement initState
    descargarTodosMensajes();
    DataHolder().initPlatformAdmin(context);
  }

  int compararArray(FbMensaje a, FbMensaje b){

    return b.tmCreacion.compareTo(a.tmCreacion);
  }


  Future<void> descargarTodosMensajes() async{
    List<FbMensaje> arTemp=[];
    arTemp.clear();


    final ref = db.collection(sRutaChatMensajes)
        .orderBy("tmCreacion",descending: true)
    //.limit(30)
        .withConverter(
      fromFirestore: FbMensaje.fromFirestore,
      toFirestore: (FbMensaje post, _) => post.toFirestore(),
    );
    //final querySnap = await ref.get();

    ref.snapshots().listen((event) {
      arTemp.clear();
      for (var doc in event.docs) {
        arTemp.add(doc.data());
      }

      arTemp.sort(compararArray);

      setState(() {
        arFbMensajes.clear();
        arFbMensajes.addAll(arTemp);
      });
    });



  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Chat ${DataHolder().fbChatSelected!.sTitulo}"),),

        body:
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DataHolder().platformAdmin!.getScreenWidth()*0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Container(
                color: Colors.amber,
                width: DataHolder().platformAdmin!.getScreenWidth()*0.8,
                height: DataHolder().platformAdmin!.getScreenHeight()*0.5,
                child: ListView.builder(itemBuilder: mensajeBuilder,itemCount: arFbMensajes.length,),
              ),
              Container(
                width: DataHolder().platformAdmin!.getScreenWidth()*0.8,
                color: Colors.cyanAccent,
                child: TextField(controller: imgcontroller,),
              ),
              Row(children: [
                Container(
                  width: DataHolder().platformAdmin!.getScreenWidth()*0.7,
                  color: Colors.tealAccent,
                  child: TextField(
                    controller: controller,
                    style: TextStyle(fontSize: DataHolder().platformAdmin!.getScreenWidth()*0.05),

                  ),
                ),
                SizedBox(
                  width: DataHolder().platformAdmin!.getScreenWidth()*0.1,
                  child: IconButton(onPressed: presionarEnvio, icon: Icon(Icons.send)),
                )

              ],),
            ],
          ),
        )


    );
  }

  Widget? mensajeBuilder(BuildContext contexto, int indice){
    return
      Container(
        width: 250,
        child: Row(
          children: [
            Text("${arFbMensajes[indice].sCuerpo}",
              maxLines: 3,
              style: TextStyle(fontSize: DataHolder().platformAdmin!.getScreenHeight()*0.07),
            ),
            if(arFbMensajes[indice].sImgUrl.isNotEmpty)Image.network(arFbMensajes[indice].sImgUrl)
          ],
        ),
      );
    //return Text("${arFbMensajes[indice].sCuerpo}");
  }

  void presionarEnvio() async{
    FbMensaje nuevoMensaje=FbMensaje(
        sCuerpo: controller.text,
        tmCreacion:Timestamp.now(),
        sImgUrl: imgcontroller.text,
        sAutorUid: FirebaseAuth.instance.currentUser!.uid
    );
    var nuevoDoc=await db.collection(sRutaChatMensajes).add(nuevoMensaje.toFirestore());

  }
}