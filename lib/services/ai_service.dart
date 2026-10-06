import 'dart:convert';

import 'package:http/http.dart' as http;

// Requests go through our Cloudflare Worker, which holds the Gemini API
// key as a secret and adds the CORS headers browsers need.
const _endpoint = 'https://wandering-unit-b25a.abioduntolu84.workers.dev';

// Gemini free-tier models, tried in order (flash-lite is fastest/cheapest,
// so it goes first; fall through to flash if it's ever unavailable).
const _models = [
  'gemini-3.5-flash-lite',
  'gemini-3.8-flash',
];

Future<String> askAi({required String system, required String prompt}) async {
  final errors = <String>[];
  for (final model in _models) {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'temperature': 0.4,
              'messages': [
                {'role': 'system', 'content': system},
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final body = response.body;
        final snippet = body.length > 200 ? body.substring(0, 200) : body;
        throw Exception('${response.statusCode}: $snippet');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = data['choices'][0]['message']['content'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw Exception('$model returned an empty reply');
      }
      return text.trim();
    } catch (e) {
      errors.add('$model -> ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
  throw Exception('The AI is unavailable right now.\n${errors.join('\n')}');
}