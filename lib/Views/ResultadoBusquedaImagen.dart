// En el widget ResultadoBusquedaImagen (supongo que tienes un ListView.builder que muestra los resultados)

import 'package:flutter/material.dart';

class ResultadoBusquedaImagen extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final void Function(String textoBusqueda) onItemTap;

  ResultadoBusquedaImagen({required this.results, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(child: Text('No se encontraron resultados.'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];

        final title = item['title'] ?? 'Título desconocido';
        final year = item['year'] != null ? item['year'].toString() : 'Año desconocido';
        final formatList = item['format'] ?? []; // Puede ser una lista de strings
        final format = formatList.isNotEmpty ? formatList.join(', ') : 'Formato desconocido';

        return ListTile(
          title: Text(title),
          subtitle: Text('Año: $year - Formato: $format'),
          onTap: () {
            // Envía el texto para búsqueda en BusquedaView
            onItemTap(title);
          },
        );
      },
    );
  }
}
