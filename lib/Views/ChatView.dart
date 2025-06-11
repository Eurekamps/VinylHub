import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vinylhub/FbObjects/FbChat.dart';
import 'package:vinylhub/Singletone/AppNavigationUtils.dart';

import '../FbObjects/FbMensaje.dart';
import '../FbObjects/FbPerfil.dart';
import '../FbObjects/FbPost.dart';
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
  bool isLoading = true; // Para saber si estamos esperando a que se cargue el perfil




  @override
  void initState() {
    // TODO: implement initState
    descargarTodosMensajes();
    DataHolder().initPlatformAdmin(context);
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    // Obtener el uid del usuario actual
    String uidUsuarioActual = FirebaseAuth.instance.currentUser!.uid;

    // Cargar el perfil desde Firestore
    await DataHolder().obtenerPerfilDeFirestore(uidUsuarioActual);

    // Después de obtener el perfil, cambiamos el estado de carga
    setState(() {
      isLoading = false;
    });
    print("Perfil cargado en initState con UID: ${DataHolder().miPerfil?.uid}");

  }



  int compararArray(FbMensaje a, FbMensaje b){

    return b.tmCreacion.compareTo(a.tmCreacion);
  }


  Future<void> descargarTodosMensajes() async {
    List<FbMensaje> arTemp = [];
    final ref = db.collection(sRutaChatMensajes)
        .orderBy("tmCreacion", descending: true)
        .withConverter(
      fromFirestore: FbMensaje.fromFirestore,
      toFirestore: (FbMensaje mensaje, _) => mensaje.toFirestore(),
    );

    // Guardamos la referencia del StreamSubscription para cancelarla después
    StreamSubscription? subscription;

    subscription = ref.snapshots().listen((event) {
      arTemp.clear();
      for (var doc in event.docs) {
        final mensaje = doc.data();
        if (mensaje != null) { // Verifica que el mensaje no sea null
          print("Mensaje cargado: ${mensaje.sCuerpo}, Autor: ${mensaje.sAutorUid}");
          arTemp.add(mensaje);
        } else {
          print("Mensaje nulo recibido");
        }
      }

      arTemp.sort(compararArray);

      // Verifica si el widget está montado antes de llamar a setState
      if (mounted) {
        setState(() {
          arFbMensajes.clear();
          arFbMensajes.addAll(arTemp);
        });
      }
    });

    // Asegúrate de cancelar el listener en dispose()
    @override
    void dispose() {
      subscription?.cancel(); // Cancela la suscripción al stream
      super.dispose();
    }
  }




  void presionarEnvio() async {
    FbPerfil? perfil = DataHolder().miPerfil;
    if (perfil == null) {
      print("Error: El perfil no está disponible.");
      return;
    }

    if (DataHolder().fbChatSelected == null) {
      await AppNavigationUtils.crearNuevoChat();
    }

    final firestore = FirebaseFirestore.instance;
    FbChat chat = DataHolder().fbChatSelected!;

    // Si el chat todavía no está en Firestore, lo insertamos ahora
    final docSnapshot = await firestore.collection("Chats").doc(chat.uid).get();
    if (!docSnapshot.exists) {
      await firestore.collection("Chats").doc(chat.uid).set(chat.toFirestore());
    }

    String sRutaChatMensajes = "/Chats/${chat.uid}/mensajes";

    FbMensaje nuevoMensaje = FbMensaje(
      sCuerpo: controller.text,
      tmCreacion: Timestamp.now(),
      sImgUrl: imgcontroller.text,
      sAutorUid: FirebaseAuth.instance.currentUser!.uid,
      sAutorNombre: perfil.nombre,
    );

    await firestore.collection(sRutaChatMensajes).add(nuevoMensaje.toFirestore());

    controller.clear();
  }





  bool esMensajePropio(FbMensaje mensaje) {
    final String? uidUsuarioActual = FirebaseAuth.instance.currentUser?.uid;
    if (uidUsuarioActual == null) {
      print("Error: Usuario no autenticado.");
      return false;
    }
    print("UID Usuario actual: $uidUsuarioActual");
    print("Autor mensaje: ${mensaje.sAutorUid}");
    return mensaje.sAutorUid == uidUsuarioActual;
  }

  Future<void> actualizarFbPostSelected() async {
    if (DataHolder().fbChatSelected != null) {
      String postId = DataHolder().fbChatSelected!.uidPost;  // El UID del post relacionado con el chat

      if (postId.isNotEmpty) {
        try {
          // Obtener el post desde Firestore usando el uidPost del chat
          DocumentSnapshot postSnapshot = await FirebaseFirestore.instance
              .collection('Posts')  // Asegúrate de usar la colección correcta
              .doc(postId)
              .get();

          if (postSnapshot.exists) {
            // Asignar el post a fbPostSelected
            FbPost post = FbPost.fromFirestore(postSnapshot);
            DataHolder().fbPostSelected = post;  // Asignamos el post seleccionado al DataHolder
          } else {
            print("Post no encontrado.");
          }
        } catch (e) {
          print("Error al obtener el post: $e");
        }
      }
    }
  }

  Future<void> actualizarMiPerfil() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      DocumentSnapshot<Map<String, dynamic>> perfilSnapshot = await FirebaseFirestore.instance
          .collection('perfiles')
          .doc(uid)
          .get();

      if (perfilSnapshot.exists) {
        DataHolder().miPerfil = FbPerfil.fromFirestore(perfilSnapshot, null);
        print('Perfil actualizado correctamente: ${DataHolder().miPerfil!.uid}');
      } else {
        print('No se encontró el perfil del usuario');
      }
    } catch (e) {
      print("Error al actualizar perfil: $e");
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: GestureDetector(
          onTap: () async {
            // actualizar fbPostSelected antes de navegar
            await actualizarFbPostSelected();
            await actualizarMiPerfil();
            print('Autor del post: ${DataHolder().fbPostSelected?.sAutorUid}');
            print('Usuario actual: ${DataHolder().miPerfil?.uid}');


            if (DataHolder().fbPostSelected != null) {
              String usuarioActualUid = DataHolder().miPerfil?.uid ?? '';
              if (DataHolder().fbPostSelected!.sAutorUid == usuarioActualUid) {
                Navigator.pushNamed(
                  context,
                  '/postdetailspropio',
                  arguments: DataHolder().fbPostSelected,
                );
              } else {
                Navigator.pushNamed(
                  context,
                  '/postdetails',
                  arguments: DataHolder().fbPostSelected,
                );
              }
            } else {
              print("fbPostSelected no está asignado.");
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No se encontró el post relacionado.")));
            }
          },
          child: Row(
            children: [
              if (DataHolder().fbChatSelected?.sImagenURL != null &&
                  DataHolder().fbChatSelected!.sImagenURL.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    DataHolder().fbChatSelected!.sImagenURL,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const SizedBox(width: 36, height: 36),

              const SizedBox(width: 8),

              // Título del post
              Expanded(
                child: Text(
                  DataHolder().fbChatSelected?.sTitulo ?? 'Chat sin título',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<int>(
            onSelected: (int value) async {
              if (value == 1) {
                String chatId = DataHolder().fbChatSelected?.uid ?? '';

                if (chatId.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('Chats')
                        .doc(chatId)
                        .delete();

                    await FirebaseFirestore.instance
                        .collection('Chats')
                        .doc(chatId)
                        .collection('mensajes')
                        .get()
                        .then((snapshot) {
                      for (var doc in snapshot.docs) {
                        doc.reference.delete();
                      }
                    });

                    Navigator.pushNamed(context, '/homeview');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Chat eliminado exitosamente")));
                  } catch (e) {
                    print("Error al eliminar el chat: $e");
                  }
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(
                value: 1,
                child: Text('Eliminar Chat'),
              ),
            ],
          )
        ],
      ),



      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: ListView.builder(
              reverse: true, // Los mensajes recientes al final
              itemCount: arFbMensajes.length,
                itemBuilder: (context, index) {
                  final mensaje = arFbMensajes[index];
                  final esPropio = esMensajePropio(mensaje);

                  print("Mensaje: ${mensaje.sCuerpo}");
                  print("Autor: ${mensaje.sAutorUid}");
                  print("¿Es propio?: $esPropio");

                  return MessageBubble(
                    content: mensaje.sCuerpo,
                    isSender: esPropio,
                    imageUrl: mensaje.sImgUrl.isNotEmpty ? mensaje.sImgUrl : null,
                    uidAutor: mensaje.sAutorUid,
                    onAvatarTap: () {
                      Navigator.pushNamed(
                        context,
                        '/perfilajeno',
                        arguments: mensaje.sAutorUid,
                      );
                    },
                  );

                }

            ),
          ),

          // Caja de texto para enviar mensajes
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: presionarEnvio,
                  icon: Icon(Icons.send, color: Colors.teal),
                ),
              ],
            ),
          ),
        ],
      ),
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

}

class MessageBubble extends StatelessWidget {
  final String content;
  final bool isSender;
  final String? imageUrl;
  final String? uidAutor; // UID del autor del mensaje
  final VoidCallback? onAvatarTap; // Acción al tocar el avatar

  const MessageBubble({
    super.key,
    required this.content,
    required this.isSender,
    this.imageUrl,
    this.uidAutor,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final message = Container(
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      decoration: BoxDecoration(
        color: isSender ? Colors.blue[200] : Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(content),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isSender) // Solo mostramos el avatar en mensajes del otro
            GestureDetector(
              onTap: onAvatarTap,
              child: FutureBuilder<FbPerfil?>(
                future: DataHolder().obtenerPerfilDeFirestore(uidAutor ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(radius: 18, backgroundColor: Colors.grey);
                  } else if (snapshot.hasData && snapshot.data != null) {
                    return CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(snapshot.data!.imagenURL),
                    );
                  } else {
                    return const CircleAvatar(radius: 18, child: Icon(Icons.person));
                  }
                },
              ),
            ),
          const SizedBox(width: 8),
          message,
        ],
      ),
    );
  }
}
