import 'package:http/http.dart' as http;
import 'dart:convert';

import '../FbObjects/FbPost.dart';

class FbPostService {
  //Método para obtener los posts desde una API externa
  Future<List<FbPost>> fetchPostsFromApi() async {
    final response = await http.get(Uri.parse('https://api.example.com/posts'));

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((jsonPost) => FbPost.fromJson(jsonPost)).toList();
    } else {
      throw Exception('Error al cargar los posts desde la API');
    }
  }
}
