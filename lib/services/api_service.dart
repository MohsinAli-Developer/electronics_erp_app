import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config/api_config.dart'; // <--- import only once

class ApiService {
  static final Logger _logger = Logger();

  // Correct URL for Android Emulator
  // static const String baseUrl = 'https://localhost:7183/api/Auth/register';
  //static const String baseUrl = 'http://192.168.1.7:5010/api/Auth';

  static Future<bool> registerUser(String name, int role,
      String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Auth/register');

    _logger.i("Calling URL: $url"); // <-- added
    _logger.i("Body: ${jsonEncode(
        {"name": name, "role": role, "password": password})}");

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

      _logger.i("Status: ${response.statusCode}"); // <-- added
      _logger.i("Response: ${response.body}"); // <-- added

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