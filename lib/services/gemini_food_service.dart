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

  static const _jsonShape = '''
Return ONLY a JSON object with the exact following structure and types. Do NOT include markdown blocks or any other text.
{
  "items": [
    {
      "name": "Name of the dish (string)",
      "portion": "Estimated portion size (e.g. 1 bowl, 2 pieces)",
      "calories": 0,
      "protein_g": 0.0,
      "carbs_g": 0.0,
      "fat_g": 0.0
    }
  ],
  "total": {
    "calories": 0,
    "protein_g": 0.0,
    "carbs_g": 0.0,
    "fat_g": 0.0
  },
  "confidence": "high|medium|low"
}
If you cannot identify the food, provide a generic "Unknown Food" response with 0 values and low confidence.
''';

  static const _cuisineHint =
      'Note that the cuisine is often South Indian / Indian home cooking '
      '(e.g. rice, sambar, rasam, curries, dosa, idli, curd, dal, roti, chapati, '
      'vegetable fry, chicken, fish, eggs). Estimate realistic home-cooked portions.';

  Future<Map<String, dynamic>?> analyzeFoodImage(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    _ensureApiKey();
    final prompt = '''
Analyze this food image and estimate its nutritional content. $_cuisineHint
$_jsonShape
''';
    return _generateWithFallback(
      (model) => _callGeminiMulti(
        model,
        [TextPart(prompt), DataPart(mimeType, imageBytes)],
      ),
    );
  }

  /// Estimate macros from a free-text description of what was eaten at home.
  Future<Map<String, dynamic>?> analyzeFoodText(String description) async {
    _ensureApiKey();
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      throw Exception('Please describe what you ate.');
    }

    final prompt = '''
Estimate nutritional content for this home-cooked meal description.
$_cuisineHint
Meal description:
"""
$trimmed
"""
$_jsonShape
''';
    return _generateWithFallback(
      (model) => _callGeminiMulti(model, [TextPart(prompt)]),
    );
  }

  void _ensureApiKey() {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception(
        'Gemini API key is not configured. Please add it in Profile -> AI Settings.',
      );
    }
  }

  Future<Map<String, dynamic>?> _generateWithFallback(
    Future<Map<String, dynamic>?> Function(String model) call,
  ) async {
    const modelsToTry = [
      'gemini-flash-latest',
      'gemini-2.5-flash',
      'gemini-2.0-flash',
    ];

    String lastError = '';
    for (final model in modelsToTry) {
      try {
        debugPrint('Trying Gemini model: $model...');
        return await call(model);
      } catch (e) {
        debugPrint('Failed with $model: $e');
        lastError = e.toString();
      }
    }

    throw Exception(
      'Failed to analyze food with all available models. Ensure your API key is valid from Google AI Studio. Last error: $lastError',
    );
  }

  Future<Map<String, dynamic>?> _callGeminiMulti(
    String modelName,
    List<Part> parts,
  ) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey!,
      generationConfig: GenerationConfig(temperature: 0.1),
    );

    final response = await model.generateContent([Content.multi(parts)]);

    if (response.text != null) {
      final jsonString = response.text!
          .trim()
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      debugPrint('Gemini Response: $jsonString');
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }
}
