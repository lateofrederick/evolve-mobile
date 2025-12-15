import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<String> login(String email, String password) async {
    // We use http direct or ApiClient.
    // Since ApiClient wraps the base URL, we can use it.
    // Note: The backend endpoint expects Form Data (OAuth2 standard),
    // but our ApiClient sends JSON. We might need a specific handling here
    // or update the backend to accept JSON.
    // For standard OAuth2 in FastAPI, we usually send x-www-form-urlencoded.

    final uri = Uri.parse('${ApiClient.baseUrl}/auth/token');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Login Failed: ${response.body}');
    }
  }
}