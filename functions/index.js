const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

exports.notificarNuevoMensaje = onDocumentCreated(
  "Chats/{chatId}/mensajes/{mensajeId}",
  async (event) => {
    const mensaje = event.data?.data();
    const chatId = event.params?.chatId;

    if (!mensaje) {
      console.error("Mensaje vacío o no definido");
      return;
    }

    const receptorUid = mensaje.sReceptorUid;
    const autorUid = mensaje.sAutorUid;

    if (!receptorUid || receptorUid === autorUid) {
      console.log("El receptor es el autor o no hay receptor definido");
      return;
    }

    try {
      const perfilSnap = await db.collection("perfiles").doc(receptorUid).get();

      if (!perfilSnap.exists) {
        console.error("No existe perfil del receptor con UID:", receptorUid);
        return;
      }

      const token = perfilSnap.data()?.fcmToken;

      if (!token || typeof token !== "string" || token.trim() === "") {
        console.error("Token FCM inválido para el receptor:", token);
        return;
      }

      const payload = {
        notification: {
          title: "Nuevo mensaje",
          body: mensaje.sCuerpo || "",
        },
        data: {
          tipo: "chat",
          chatId: chatId,
        },
      };

      const response = await messaging.sendToDevice(token, payload);
      console.log("Notificación enviada:", response);

    } catch (error) {
      console.error("Error al enviar la notificación:", error);
    }
  }
);
