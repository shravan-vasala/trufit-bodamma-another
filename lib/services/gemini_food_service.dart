import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

final geminiFoodServiceProvider = Provider<GeminiFoodService>((ref) {
  final profile = ref.watch(profileProvider);
  return GeminiFoodService(apiKey: profile.geminiApiKey);
});

class GeminiFoodService {
  final String? apiKey;

  GeminiFoodService({this.apiKey});

  Future<Map<String, dynamic>?> analyzeFoodImage(Uint8List imageBytes, String mimeType) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('Gemini API key is not configured. Please add it in Profile -> AI Settings.');
    }

    final prompt = '''
Analyze this food image and estimate its nutritional content. Note that the cuisine is often South Indian home cooking (e.g., rice, curries, dosa, idli, curd, dal).
Return ONLY a JSON object with the exact following structure and types. Do NOT include markdown blocks or any other text.
{
  "items": [
    {
      "name": "Name of the dish (string)",
      "portion": "Estimated portion size (e.g. 1 bowl, 2 pieces)",
      "calories": 0, // integer
      "protein_g": 0.0, // double
      "carbs_g": 0.0, // double
      "fat_g": 0.0 // double
    }
  ],
  "total": {
    "calories": 0, // integer
    "protein_g": 0.0, // double
    "carbs_g": 0.0, // double
    "fat_g": 0.0 // double
  },
  "confidence": "high|medium|low"
}
If you cannot identify the food, provide a generic "Unknown Food" response with 0 values and low confidence.
''';

    final modelsToTry = [
      'gemini-flash-latest',
      'gemini-2.5-flash',
      'gemini-2.0-flash',
    ];

    String lastError = '';
    for (final model in modelsToTry) {
      try {
        debugPrint('Trying Gemini model: $model...');
        final result = await _callGemini(model, apiKey!, imageBytes, mimeType, prompt);
        return result;
      } catch (e) {
        debugPrint('Failed with $model: $e');
        lastError = e.toString();
      }
    }

    throw Exception('Failed to analyze food with all available models. Ensure your API key is valid from Google AI Studio. Last error: $lastError');
  }

  Future<Map<String, dynamic>?> _callGemini(String modelName, String apiKey, Uint8List imageBytes, String mimeType, String prompt) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
      ),
    );

    final imagePart = DataPart(mimeType, imageBytes);
    final content = [Content.multi([TextPart(prompt), imagePart])];

    final response = await model.generateContent(content);
    
    if (response.text != null) {
      final jsonString = response.text!.trim().replaceAll('```json', '').replaceAll('```', '').trim();
      debugPrint('Gemini Response: $jsonString');
      
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return data;
    }
    return null;
  }
}
