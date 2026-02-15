import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  /// Translates text using the free Google Translate web API.
  /// For production, consider using the official Google Cloud Translation API.
  Future<String?> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
        '?client=gtx&sl=$sourceLang&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // The response format is [[["translated text","original text",...],...],...]
        final translations = decoded[0] as List;
        final buffer = StringBuffer();
        for (final part in translations) {
          buffer.write(part[0] as String);
        }
        return buffer.toString();
      }
      return null;
    } catch (e) {
      print('Translation error: $e');
      return null;
    }
  }
}
