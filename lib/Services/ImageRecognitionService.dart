import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageRecognitionService {
  final String apiKey = 'AIzaSyCLjYHcvaVRCZblFQJeBYs30yHYGlTZdVA';

  Future<String> extractTextFromImage(String base64Image) async {
    final url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

    final body = jsonEncode({
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'TEXT_DETECTION'}
          ]
        }
      ]
    });

    final response = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'}, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final annotations =
      data['responses'][0]['textAnnotations'] as List<dynamic>?;
      if (annotations != null && annotations.isNotEmpty) {
        return annotations[0]['description'];
      }
    }
    throw Exception('Error en OCR');
  }
}
