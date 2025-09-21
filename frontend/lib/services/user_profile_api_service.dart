import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserProfileApiService {
  final String baseUrl;
  UserProfileApiService({required this.baseUrl});

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? await user.getIdToken() : null;
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$baseUrl/profile/$uid'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return UserProfile.fromMap(json.decode(response.body));
    }
    if (response.statusCode == 404) return null;
    throw Exception('Failed to load profile');
  }

  Future<UserProfile> createProfile(UserProfile profile, String uid) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.post(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({...profile.toMap(), 'uid': uid}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return UserProfile.fromMap(json.decode(response.body));
    }
    throw Exception('Failed to create profile');
  }

  Future<UserProfile> updateProfile(UserProfile profile, String uid) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.put(
      Uri.parse('$baseUrl/profile/$uid'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(profile.toMap()),
    );
    if (response.statusCode == 200) {
      return UserProfile.fromMap(json.decode(response.body));
    }
    throw Exception('Failed to update profile');
  }
}
