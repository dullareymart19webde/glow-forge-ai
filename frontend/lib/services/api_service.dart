import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  
  // IMPORTANT: For Android APK on real phone, use your local network IP (192.168.254.113)
  // For Android emulator, use 10.0.2.2. For Web, use 127.0.0.1.
  final String baseUrl = 'http://192.168.254.113:8000/api';

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
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('$baseUrl/image/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Bypass-Tunnel-Reminder': 'true',
      },
      body: jsonEncode({
        'image_base64': base64Image,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final outputBase64 = jsonResponse['image_base64'] as String;
      return base64Decode(outputBase64);
    }
    
    throw Exception('Failed to process image: ${response.statusCode} ${response.body}');
  }
}
