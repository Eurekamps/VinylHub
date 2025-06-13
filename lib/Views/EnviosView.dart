import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EnviosView extends StatefulWidget {
  const EnviosView({super.key});

  @override
  State<EnviosView> createState() => _EnviosViewState();
}

class _EnviosViewState extends State<EnviosView> {
  late final String uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<List<Map<String, dynamic>>> getEnviosPendientes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('perfiles')
        .doc(uid)
        .collection('enviosPendientes')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['pedidoId'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> marcarComoEnviado(String pedidoId) async {
    // Marcar como enviado en la subcolección de perfil
    await FirebaseFirestore.instance
        .collection('perfiles')
        .doc(uid)
        .collection('enviosPendientes')
        .doc(pedidoId)
        .update({
      'enviado': true,
      'fechaEnvio': Timestamp.now(),
    });

    // Marcar también en colección general de pedidos
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedidoId)
        .update({
      'enviado': true,
      'fechaEnvio': Timestamp.now(),
    });

    setState(() {}); // Recargar lista
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Envíos pendientes")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getEnviosPendientes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final envios = snapshot.data ?? [];

          if (envios.isEmpty) {
            return const Center(child: Text("No tienes envíos pendientes."));
          }

          return ListView.builder(
            itemCount: envios.length,
            itemBuilder: (context, index) {
              final envio = envios[index];
              final enviado = envio['enviado'] == true;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Row(
                    children: [
                      const Text("📦 Pedido: "),
                      Expanded(child: Text(envio['pedidoId'])),
                      if (enviado)
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Dirección: ${envio['direccion']}, ${envio['ciudad']}, ${envio['provincia']}, CP: ${envio['codigoPostal']}"),
                      const SizedBox(height: 4),
                      Text("Precio: ${envio['precio']}€"),
                    ],
                  ),
                  trailing: !enviado
                      ? ElevatedButton(
                    child: const Text("Marcar enviado"),
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('¿Confirmar envío?'),
                          content: const Text('¿Seguro que ya has enviado este pedido?'),
                          actions: [
                            TextButton(
                              child: const Text("Cancelar"),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            ElevatedButton(
                              child: const Text("Sí, enviado"),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ],
                        ),
                      );

                      if (confirmar == true) {
                        await marcarComoEnviado(envio['pedidoId']);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✅ Pedido marcado como enviado")),
                          );
                        }
                      }
                    },
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
