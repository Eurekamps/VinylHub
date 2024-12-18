import 'dart:convert';
import 'package:http/http.dart' as http;

class DiscogsService {
  final String baseUrl = "https://api.discogs.com/";
  final String consumerKey = "sqCYCVnHrbYVGRrLhvwJ";
  final String consumerSecret = "nuSqSRSQlKmMJAKfjbzpqEVBTFxTYyxA";

  // Método para buscar vinilos
  Future<List<Map<String, dynamic>>> searchVinyl(String query) async {
    final url = Uri.parse(
        "${baseUrl}database/search?q=$query&type=release&key=$consumerKey&secret=$consumerSecret");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Verificar si 'results' existe y es una lista
        if (data['results'] is List) {
          // Mapear los resultados a un formato más usable
          return (data['results'] as List).map((item) {
            return {
              'title': item['title'] ?? 'Sin título',
              'year': item['year'] ?? 'Año desconocido',
              'genre': item['genre'] ?? [],
              'style': item['style'] ?? []
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