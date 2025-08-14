import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fyp_proj/features/4_plan/model/quiz_generation_model.dart';

class QuizGenerationRepository {
  final String _apiKey = dotenv.env['GEMINI_API'] ?? 'API_KEY_NOT_FOUND';
  final String _model = 'gemini-2.5-flash';
  late final Box<GeneratedQuiz> _quizBox;

  QuizGenerationRepository() {
    _quizBox = Hive.box<GeneratedQuiz>('quizCache');
  }

  Future<List<GeneratedQuiz>> getQuiz(String destination) async {
    final cacheKey = destination.toLowerCase().replaceAll(' ', '_');
    final cachedQuiz = _quizBox.get(cacheKey);

    if (cachedQuiz != null) {
      print('Quiz for "$destination" found in cache. Returning cached version.');
      // For simplicity, we are returning a list with the single cached quiz.
      // You might want to adjust this logic if you always need 3 questions.
      return [cachedQuiz]; 
    }

    // 2. If not in cache, fetch from the API
    print('Quiz for "$destination" not in cache. Fetching from API...');
    final newQuizList = await _generateQuizFromAPI(destination);

    // 3. Save the newly fetched quiz to the cache
    if (newQuizList.isNotEmpty) {
      // We cache the first question of the list.
      await _quizBox.put(cacheKey, newQuizList.first);
      print('Quiz for "$destination" saved to cache.');
    }

    return newQuizList;
  }


  Future<List<GeneratedQuiz>> _generateQuizFromAPI(String destination) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey');
    
    // --- UPDATED AND STRICT PROMPT ---
    final prompt = """
    Generate 1 unique multiple-choice quiz question about the travel destination "$destination".
    Provide 3 options and identify the correct one.
    Also, provide a brief explanation for the correct answer.

    IMPORTANT: The response MUST be a valid JSON array of objects, conforming exactly to this schema. Do NOT return a markdown code block.

    EXAMPLE:
    [
      {
        "question": "What is the primary material used to build the Eiffel Tower?",
        "options": ["Steel", "Wrought Iron", "Aluminum"],
        "correct_option_index": 1,
        "explanation": "The Eiffel Tower is made of wrought iron, a material chosen for its strength and durability at the time of its construction."
      }
    ]
    """;

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          // Ensure the API knows we expect JSON back.
          'generationConfig': {'response_mime_type': 'application/json'}
        }),
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        print('1 api response : $decodedResponse');
        
        // This part of the code can now be simpler and more robust because we are forcing a consistent output.
        final content = decodedResponse['candidates'][0]['content']['parts'][0]['text'];
        
        // The API should now consistently return a string that needs to be decoded.
        final jsonResponse = jsonDecode(content) as List<dynamic>;

        return jsonResponse
            .map((quizJson) => GeneratedQuiz.fromJson(quizJson as Map<String, dynamic>))
            .toList();
      } else {
        print('1, Error generating quiz: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to generate quiz. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('2, Error generating quiz: $e');
      print('--- Raw Response causing error ---');
      // This will help debug if the API still misbehaves
      try {
        final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'contents': [{'parts': [{'text': prompt}]}], 'generationConfig': {'response_mime_type': 'application/json'}}));
        print(res.body);
      } catch (e2) {
        print("Could not retrieve raw response for debugging.");
      }
      // --- End Debug ---
      throw Exception('Failed to generate quiz. The API response was not in the expected format.');
    }
  }

  generateQuiz(String destination) {}
}