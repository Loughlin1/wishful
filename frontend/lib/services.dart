import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';


class WishListService {
  Future<void> updateWishList(int wishlistId, Map<String, dynamic> wishList) async {
    final headers = await _getAuthHeaders(json: true);
    final response = await http.put(
      Uri.parse('$baseUrl/wishlists/$wishlistId'),
      headers: headers,
      body: jsonEncode(wishList),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update wish list');
    }
  }
  static const String baseUrl = 'http://localhost:8000';

  Future<Map<String, String>> _getAuthHeaders({bool json = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<List<dynamic>> fetchWishLists() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(Uri.parse('$baseUrl/wishlists'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load wish lists');
    }
  }

  Future<void> createWishList(Map<String, dynamic> wishList) async {
    final headers = await _getAuthHeaders(json: true);
    final response = await http.post(
      Uri.parse('$baseUrl/wishlists'),
      headers: headers,
      body: jsonEncode(wishList),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create wish list');
    }
  }

  Future<void> reserveGift(int wishlistId, int itemId, String reservedBy) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/wishlists/$wishlistId/reserve/$itemId?reserved_by=$reservedBy'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reserve gift');
    }
  }

  Future<void> addItemToWishList(int wishlistId, Map<String, dynamic> item) async {
    final headers = await _getAuthHeaders(json: true);
    final response = await http.post(
      Uri.parse('$baseUrl/wishlists/$wishlistId/items'),
      headers: headers,
      body: jsonEncode(item),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add item to wish list');
    }
  }
}
