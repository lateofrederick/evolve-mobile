import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // Use 10.0.2.2 for Android Emulator to access localhost
  // Use your computer's IP (e.g., 192.168.1.x) for physical devices
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  final String? _authToken;

  ApiClient({String? token}) : _authToken = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }
}