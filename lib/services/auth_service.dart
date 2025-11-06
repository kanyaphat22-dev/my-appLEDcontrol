import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://172.24.13.135/web"; // ✅ เปลี่ยนเป็น URL ของคุณ

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api_login.php"),
        body: {'username': username, 'password': password},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {"success": false, "message": "Server error: ${response.statusCode}"};
    } catch (e) {
      return {"success": false, "message": "เชื่อมต่อไม่ได้: $e"};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String fullname,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api_register.php"),
        body: {
          'email': email,
          'fullname': fullname,
          'username': username,
          'password': password,
        },
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {"success": false, "message": "Server error: ${response.statusCode}"};
    } catch (e) {
      return {"success": false, "message": "เชื่อมต่อไม่ได้: $e"};
    }
  }
}
