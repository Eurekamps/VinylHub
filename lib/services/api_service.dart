import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vinyl_model.dart';

class ApiService {
  static Future<List<VinylPrice>> fetchVinylPrices(String vinylName) async {
    final url = Uri.parse('http://127.0.0.1:5000/compare-prices?vinylName=$vinylName');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<VinylPrice> prices = (data['stores'] as List)
          .map((store) => VinylPrice.fromJson(store))
          .toList();
      return prices;
    } else {
      throw Exception('Failed to load vinyl prices');
    }
  }
}
