import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  // We use localtunnel so real physical phones can reach your computer
  final String baseUrl = 'https://glowforge-ai-app-test.loca.lt/api';

  ApiService();

  Future<String> chat(String sessionId, String userId, String message, List<Map<String, String>> history) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/'),
      headers: {
        'Content-Type': 'application/json',
        'Bypass-Tunnel-Reminder': 'true',
      },
      body: jsonEncode({
        'session_id': sessionId,
        'user_id': userId,
        'message': message,
        'history': history
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['response'];
    }
    throw Exception('Failed to send chat message: ${response.body}');
  }

  Future<String> generateText(String targetOutput, String topic, String tone, String language, String length) async {
    final response = await http.post(
      Uri.parse('$baseUrl/writer/generate/'),
      headers: {
        'Content-Type': 'application/json',
        'Bypass-Tunnel-Reminder': 'true',
      },
      body: jsonEncode({
        'target_output': targetOutput,
        'topic': topic,
        'tone': tone,
        'language': language,
        'length': length
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['result'];
    }
    throw Exception('Failed to generate text');
  }

  Future<Map<String, dynamic>> generateResume(Map<String, dynamic> personalInfo, List<dynamic> education, List<dynamic> experience, List<dynamic> skills) async {
    final response = await http.post(
      Uri.parse('$baseUrl/resume/generate/'),
      headers: {
        'Content-Type': 'application/json',
        'Bypass-Tunnel-Reminder': 'true',
      },
      body: jsonEncode({
        'personal_info': personalInfo,
        'education': education,
        'experience': experience,
        'skills': skills
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to generate resume');
  }

  Future<List<int>> processImage(XFile imageFile, String endpoint) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/image/$endpoint'));
    request.headers['Bypass-Tunnel-Reminder'] = 'true';
    
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    
    final response = await request.send();
    if (response.statusCode == 200) {
      return await response.stream.toBytes();
    }
    throw Exception('Failed to process image');
  }
}
