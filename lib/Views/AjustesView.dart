import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import '../Singletone/ThemeProvider.dart';


class AjustesView extends StatefulWidget {
  const AjustesView({Key? key}) : super(key: key);

  @override
  State<AjustesView> createState() => _AjustesViewState();
}

class _AjustesViewState extends State<AjustesView> {
  bool notificacionesActivadas = false;
  bool localizacionActivada = false;

  // Aquí guardaremos la referencia al usuario
  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    verificarPermisos();
    cargarAjustesGuardados(); // Carga los ajustes guardados en Firestore
  }

  Future<void> cargarAjustesGuardados() async {
    if (user == null) return;

    final doc = await firestore.collection('ajustesUsuario').doc(user!.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        notificacionesActivadas = data['notificacionesActivadas'] ?? false;
        localizacionActivada = data['localizacionActivada'] ?? false;
      });
    }
  }

  Future<void> guardarAjustes() async {
    if (user == null) return;

    try {
      await firestore.collection('ajustesUsuario').doc(user!.uid).set({
        'notificacionesActivadas': notificacionesActivadas,
        'localizacionActivada': localizacionActivada,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajustes guardados correctamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar ajustes: $e')),
      );
    }
  }
  Future<void> verificarPermisos() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final locStatus = await Geolocator.checkPermission();

    setState(() {
      notificacionesActivadas = settings.authorizationStatus == AuthorizationStatus.authorized;
      localizacionActivada = locStatus == LocationPermission.always || locStatus == LocationPermission.whileInUse;
    });
  }

  Future<void> cambiarContrasenia() async {
    final oldController = TextEditingController();
    final newController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cambiar contraseña"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Contraseña actual"),
            ),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Nueva contraseña"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Guardar")),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser!;
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: oldController.text,
        );

        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newController.text);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contraseña actualizada.")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> eliminarCuenta() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar cuenta"),
        content: const Text("¿Estás seguro? Se eliminarán tu perfil, posts y cuenta."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmacion != true) return;

    try {
      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;

      // Eliminar perfil
      await firestore.collection("perfiles").doc(uid).delete();

      // Eliminar posts del usuario
      final posts = await firestore.collection("Posts").where("sAutorUid", isEqualTo: uid).get();
      for (final doc in posts.docs) {
        await doc.reference.delete();
      }

      // Eliminar usuario
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cuenta eliminada.")));
      Navigator.of(context).pushReplacementNamed("/loginview");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> alternarNotificaciones(bool valor) async {
    if (valor) {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        setState(() => notificacionesActivadas = true);
      } else {
        setState(() => notificacionesActivadas = false);
      }
    } else {
      setState(() => notificacionesActivadas = false);
    }
  }

  Future<void> alternarLocalizacion(bool valor) async {
    if (valor) {
      final permiso = await Geolocator.requestPermission();
      setState(() {
        localizacionActivada = permiso == LocationPermission.always || permiso == LocationPermission.whileInUse;
      });
    } else {
      setState(() => localizacionActivada = false);
    }
  }

  void mostrarInfoApp() {
    showAboutDialog(
      context: context,
      applicationName: 'VinylHub',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 TuNombre',
      children: [const Text('Aplicación para comprar y vender vinilos.')],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Ajustes")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Notificaciones"),
            subtitle: const Text("Activar o desactivar notificaciones"),
            value: notificacionesActivadas,
            onChanged: (valor) async {
              await alternarNotificaciones(valor);
            },
          ),
          SwitchListTile(
            title: const Text("Localización"),
            subtitle: const Text("Proporcionar acceso a la ubicación"),
            value: localizacionActivada,
            onChanged: (valor) async {
              await alternarLocalizacion(valor);
            },
          ),
          SwitchListTile(
            title: const Text("Modo oscuro"),
            subtitle: const Text("Cambiar entre modo claro y oscuro"),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (valor) => themeProvider.toggleTheme(valor),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Cambiar contraseña"),
            onTap: cambiarContrasenia,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Información de la app"),
            onTap: mostrarInfoApp,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Cerrar sesión"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/loginview');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Eliminar cuenta", style: TextStyle(color: Colors.red)),
            onTap: eliminarCuenta,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: guardarAjustes,
              child: const Text('Guardar ajustes'),
            ),
          ),
        ],
      ),
    );
  }
}
