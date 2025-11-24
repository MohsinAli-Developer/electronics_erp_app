// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:logger/logger.dart';
// import '../config/api_config.dart'; // <--- import only once
//
// class ApiService {
//   static final Logger _logger = Logger();
//
//   // Correct URL for Android Emulator
//   // static const String baseUrl = 'https://localhost:7183/api/Auth/register';
//   //static const String baseUrl = 'http://192.168.1.7:5010/api/Auth';
//
//   static Future<bool> registerUser(String name, int role,
//       String password) async {
//     final url = Uri.parse('${ApiConfig.baseUrl}/Auth/register');
//
//     _logger.i("Calling URL: $url"); // <-- added
//     _logger.i("Body: ${jsonEncode(
//         {"name": name, "role": role, "password": password})}");
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "name": name,
//           "role": role,
//           "password": password,
//         }),
//       );
//
//       _logger.i("Status: ${response.statusCode}"); // <-- added
//       _logger.i("Response: ${response.body}"); // <-- added
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return true;
//       } else {
//         _logger.e("Server Error: ${response.statusCode} - ${response.body}");
//         return false;
//       }
//     } catch (e) {
//       _logger.e("Request Failed: $e");
//       return false;
//     }
//   }
// }



import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config/api_config.dart';

class ApiService {
  static final Logger _logger = Logger();

  // ---------------------------
  // COMMON GET REQUEST METHOD
  // ---------------------------
  static Future<dynamic> getRequest(String endpoint) async {
    final url = Uri.parse("${ApiConfig.baseUrl}$endpoint");

    _logger.i("GET → $url");

    try {
      final response = await http.get(url);

      _logger.i("Status: ${response.statusCode}");
      _logger.i("Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger.e("GET Error ${response.statusCode}");
        return null;
      }
    } catch (e) {
      _logger.e("GET Exception: $e");
      return null;
    }
  }

  // ---------------------------
  // COMMON POST REQUEST METHOD
  // ---------------------------
  static Future<dynamic> postRequest(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse("${ApiConfig.baseUrl}$endpoint");

    _logger.i("POST → $url");
    _logger.i("Body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      _logger.i("Status: ${response.statusCode}");
      _logger.i("Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        _logger.e("POST Error ${response.statusCode}");
        return null;
      }
    } catch (e) {
      _logger.e("POST Exception: $e");
      return null;
    }
  }

  // ============================================================
  //                     AUTH API
  // ============================================================

  static Future<bool> registerUser(String name, int role, String password) async {
    final response = await postRequest("/Auth/register", {
      "name": name,
      "role": role,
      "password": password,
    });

    return response != null;
  }

  // ============================================================
  //                    DASHBOARD API CALLS
  // ============================================================

  static Future<List<dynamic>> getVendors() async {
    return await getRequest("/Vendors") ?? [];
  }

  static Future<List<dynamic>> getWarehouses() async {
    return await getRequest("/Warehouse") ?? [];
  }

  static Future<List<dynamic>> getProducts() async {
    return await getRequest("/Products") ?? [];
  }

  static Future<List<dynamic>> getCustomers() async {
    return await getRequest("/Customers") ?? [];
  }

  static Future<List<dynamic>> getSalesSummary() async {
    return await getRequest("/StockMovement/GetSalesSummary") ?? [];
  }
}
