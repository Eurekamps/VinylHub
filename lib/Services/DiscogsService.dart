import 'dart:convert';
import 'package:http/http.dart' as http;

class DiscogsService {
  final String baseUrl = "https://api.discogs.com/";
  final String consumerKey = "sqCYCVnHrbYVGRrLhvwJ";
  final String consumerSecret = "nuSqSRSQlKmMJAKfjbzpqEVBTFxTYyxA";

  // Método para buscar vinilos
  Future<List<Map<String, dynamic>>> searchVinyl(String query) async {
    final url = Uri.parse(
        "${baseUrl}database/search?q=${Uri.encodeComponent(query)}&type=release&key=$consumerKey&secret=$consumerSecret"
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['results'] is List) {
          return (data['results'] as List).map((item) {
            return {
              'id': item['id'] ?? '',
              'title': item['title'] ?? 'Sin título',
              'year': item['year'] ?? 'Año desconocido',
              'genre': item['genre'] ?? [],
              'style': item['style'] ?? [],
              'cover_image': item['cover_image'] ?? '',
              'artist': item['artist'] ?? '',
              'format': item['format'] ?? '',  // Esto puede no venir, quizá pruebes con 'formats'
              'formats': item['formats'] ?? [], // Si viene una lista de formatos
            };
          }).toList();

        } else {
          throw Exception("La clave 'results' no contiene una lista válida.");
        }
      } else {
        throw Exception(
            "Error en la API: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      throw Exception("Error al conectar con la API: $e");
    }
  }



}