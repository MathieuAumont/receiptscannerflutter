import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  static final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o';

  static Future<String> analyzeSpending(String question, Map<String, dynamic> spendingData) async {
    print('API KEY: [32m${dotenv.env['OPENAI_API_KEY']}[0m');
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a financial analysis assistant. Analyze the spending data and provide insights based on the user\'s question.'
            },
            {
              'role': 'user',
              'content': 'Here is my spending data: ${jsonEncode(spendingData)}\n\nMy question: $question'
            }
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get AI analysis: ${response.body}');
      }
    } catch (e, stack) {
      print('Error analyzing spending: $e');
      print(stack);
      throw Exception('Error analyzing spending: $e');
    }
  }

  static Future<Map<String, dynamic>> analyzeReceipt(String imageBase64) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': '''You are a receipt analysis assistant. Analyze the receipt image and extract the following information in JSON format:
{
  "merchant": "store name",
  "date": "YYYY-MM-DD",
  "items": [
    {
      "name": "item name",
      "price": price as number,
      "quantity": quantity as number
    }
  ],
  "subtotal": subtotal as number,
  "tps": TPS amount as number,
  "tvq": TVQ amount as number,
  "total": total amount as number,
  "category": "category name",
  "confidence": confidence score between 0 and 1
}

If any information is not found, use null or 0 as appropriate.'''
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Please analyze this receipt and extract the information in the specified JSON format.'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$imageBase64'
                  }
                }
              ]
            }
          ],
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        throw Exception('Failed to analyze receipt: ${response.body}');
      }
    } catch (e, stack) {
      print('Error analyzing receipt: $e');
      print(stack);
      throw Exception('Error analyzing receipt: $e');
    }
  }
} 