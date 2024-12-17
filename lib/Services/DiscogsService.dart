import 'dart:convert';
import 'package:http/http.dart' as http;

class DiscogsService {
  final String baseUrl = "https://api.discogs.com/";
  final String consumerKey = "sqCYCVnHrbYVGRrLhvwJ";
  final String consumerSecret = "nuSqSRSQlKmMJAKfjbzpqEVBTFxTYyxA";

  // Método para buscar vinilos
  Future<List<dynamic>> searchVinyl(String query) async {
    final url = Uri.parse(
        "${baseUrl}database/search?q=$query&key=$consumerKey&secret=$consumerSecret");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Asegúrate de que 'results' exista y sea una lista
        if (data['results'] is List) {
          return data['results'];
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