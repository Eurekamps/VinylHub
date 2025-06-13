import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Services/DiscogsService.dart';
import '../Services/ImageRecognitionService.dart';
import 'ResultadoBusquedaImagen.dart';


class BusquedaImagen extends StatefulWidget {
  @override
  _BusquedaImagenState createState() => _BusquedaImagenState();
}

class _BusquedaImagenState extends State<BusquedaImagen> {
  final picker = ImagePicker();
  final imageRecognitionService = ImageRecognitionService();
  final discogsService = DiscogsService();

  bool loading = false;
  List<Map<String, dynamic>> results = [];



  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() {
      loading = true;
      results = [];
    });

    final bytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    try {
      final text = await imageRecognitionService.extractTextFromImage(base64Image);
      final searchResults = await discogsService.searchVinyl(text);
      setState(() {
        results = searchResults;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buscar vinilo por portada')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: loading ? null : pickImage,
            child: Text('📷 Buscar con imagen'),
          ),
          if (loading) CircularProgressIndicator(),
          Expanded(
            child: results.isEmpty
                ? Center(child: Text('No hay resultados'))
                : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final item = results[index];
                return GestureDetector(
                  onTap: () {
                    final title = (item['title'] ?? '').trim();
                    final artist = (item['artist'] ?? '').trim();
                    final query = (title + ' ' + artist).trim();  // Evita espacios sobrantes
                    Navigator.pop(context, query);
                  },

                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: ListTile(
                      leading: item['cover_image'] != null
                          ? Image.network(item['cover_image'], width: 50, fit: BoxFit.cover)
                          : Icon(Icons.album),
                      title: Text(item['title'] ?? 'Sin título'),
                      subtitle: Text(item['artist'] ?? 'Sin artista'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
