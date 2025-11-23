import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ApiService {
  static final Logger _logger = Logger();

  // Correct URL for Android Emulator
  static const String baseUrl = 'https://localhost:7183/api/Auth/register';

  static Future<bool> registerUser(String name, int role, String password) async {
    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "role": role,
          "password": password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        _logger.e("Server Error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      _logger.e("Request Failed: $e");
      return false;
    }
  }
}
