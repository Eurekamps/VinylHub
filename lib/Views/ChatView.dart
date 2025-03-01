import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vinylhub/FbObjects/FbChat.dart';

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
    // Asegúrate de que el perfil esté disponible
    FbPerfil? perfil = DataHolder().miPerfil;

    if (perfil == null) {
      // Si el perfil no está cargado o es null, muestra un error
      print("Error: El perfil no está disponible.");
      return;  // Salimos de la función para evitar que se intente enviar el mensaje sin perfil
    }

    // Si el perfil está disponible, puedes continuar con el envío del mensaje
    FbMensaje nuevoMensaje = FbMensaje(
      sCuerpo: controller.text,
      tmCreacion: Timestamp.now(),
      sImgUrl: imgcontroller.text,
      sAutorUid: FirebaseAuth.instance.currentUser!.uid,
      sAutorNombre: perfil.nombre, // Usamos el nombre del perfil
    );

    var nuevoDoc = await db.collection(sRutaChatMensajes).add(nuevoMensaje.toFirestore());
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () async {
            // Actualizar fbPostSelected antes de navegar
            await actualizarFbPostSelected();

            // Verificamos que fbPostSelected está asignado antes de navegar
            if (DataHolder().fbPostSelected != null) {
              String usuarioActualUid = DataHolder().miPerfil?.uid ?? ''; // Asegúrate de que el uid del usuario esté disponible

              // Comprobar si el autor del post es el mismo que el usuario actual
              if (DataHolder().fbPostSelected!.sAutorUid == usuarioActualUid) {
                // Si el post fue creado por el usuario actual, navegar a PostDetailsPropio
                Navigator.pushNamed(
                  context,
                  '/postdetailspropio',  // Ruta al detalle del post propio
                  arguments: DataHolder().fbPostSelected,  // Pasamos el objeto FbPost completo
                );
              } else {
                // Si el post no fue creado por el usuario actual, navegar a PostDetails
                Navigator.pushNamed(
                  context,
                  '/postdetails',  // Ruta al detalle del post
                  arguments: DataHolder().fbPostSelected,  // Pasamos el objeto FbPost completo
                );
              }
            } else {
              print("fbPostSelected no está asignado.");
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No se encontró el post relacionado.")));
            }
          },
          child: Text(DataHolder().fbChatSelected?.sTitulo ?? 'Chat sin título'),
        ),
        backgroundColor: Colors.grey,
        actions: [
          PopupMenuButton<int>(
            onSelected: (int value) async {
              if (value == 1) {
                // Navegar al perfil (si lo necesitas)
              } else if (value == 2) {
                // Eliminar el chat
                String chatId = DataHolder().fbChatSelected?.uid ?? '';  // Asegúrate de tener el ID del chat seleccionado

                if (chatId.isNotEmpty) {
                  try {
                    // Eliminar el chat de Firestore
                    await FirebaseFirestore.instance
                        .collection('Chats')  // Asegúrate de usar la colección correcta
                        .doc(chatId)
                        .delete();

                    // Eliminar los mensajes asociados si es necesario
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
                child: Text('Ver Perfil'),
              ),
              const PopupMenuItem<int>(
                value: 2,
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

  const MessageBubble({
    Key? key,
    required this.content,
    required this.isSender,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alignment =
    isSender ? Alignment.centerRight : Alignment.centerLeft;
    final color = isSender ? Colors.teal[100] : Colors.grey[300];
    final textColor = isSender ? Colors.black : Colors.black87;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: isSender ? Radius.circular(15) : Radius.zero,
            bottomRight: isSender ? Radius.zero : Radius.circular(15),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Image.network(imageUrl!, width: 200, height: 150),
              ),
            Text(
              content,
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
    );
  }

}