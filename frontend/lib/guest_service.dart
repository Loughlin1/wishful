import 'dart:convert';
import 'package:http/http.dart' as http;

class GuestService {
  static const String baseUrl = 'http://localhost:8000';

  Future<String?> acceptShareAsGuest(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wishlists/share/$token'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['guest_uid'] as String?;
    } else {
      return null;
    }
  }
}
