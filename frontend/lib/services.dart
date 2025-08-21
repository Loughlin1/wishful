
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';

class WishListService {
  static const String baseUrl = 'http://localhost:8000';


  Future<bool> registerUser({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    required String? token,
  }) async {
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '{"uid": "$uid", "first_name": "$firstName", "last_name": "$lastName", "email": "$email"}',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> acceptInvite(String inviteCode, String userId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/wishlists/share/$inviteCode/accept'),
        headers: {'Content-Type': 'application/json'},
        body: '{"user_id": "$userId"}',
      );
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<Map<String, dynamic>> fetchInviteInfo(String inviteCode) async {
    final response = await http.get(Uri.parse('$baseUrl/share/$inviteCode/info'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Invalid or expired invite link');
    }
  }

  // Share a wishlist by email (returns a share link)
  Future<String> shareWishlistByEmail(int wishlistId, String email) async {
    final headers = await _getAuthHeaders(json: true);
    final response = await http.post(
      Uri.parse('$baseUrl/wishlists/$wishlistId/share'),
      headers: headers,
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['link'] ?? '';
    } else {
      final error = jsonDecode(response.body)['detail'];
      throw Exception('Failed to share wishlist: $error');
    }
  }

  // Create a group
  Future<Map<String, dynamic>> createGroup(String name) async {
    final headers = await _getAuthHeaders(json: true);
    final response = await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: headers,
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['detail'];
      throw Exception('Failed to create group: $error');
    }
  }

  // Add a member to a group by email
  Future<String> addMemberToGroup(int groupId, String email) async {
    final headers = await _getAuthHeaders(json: true);
    final response = await http.post(
      Uri.parse('$baseUrl/groups/$groupId/members'),
      headers: headers,
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'] ?? '';
    } else {
      final error = jsonDecode(response.body)['detail'];
      throw Exception('Failed to add member: $error');
    }
  }

  // Share a wishlist with a group
  Future<String> shareWishlistWithGroup(int wishlistId, int groupId) async {
    final headers = await _getAuthHeaders(json: true);
    final response = await http.post(
      Uri.parse('$baseUrl/wishlists/$wishlistId/share-group'),
      headers: headers,
      body: jsonEncode({'group_id': groupId}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'] ?? '';
    } else {
      final error = jsonDecode(response.body)['detail'];
      throw Exception('Failed to share wishlist with group: $error');
    }
  }

  Future<List<String>> fetchTagOptions() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(Uri.parse('$baseUrl/wishlist-tags'), headers: headers);
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load tag options');
    }
  }

  Future<void> deleteWishList(int wishlistId) async {
    final headers = await _getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/wishlists/$wishlistId'),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete wish list');
    }
  }

  Future<void> editItemInWishList(int wishlistId, int itemId, String newName, String link) async {
    final headers = await _getAuthHeaders(json: true);
    final response = await http.put(
      Uri.parse('$baseUrl/wishlists/$wishlistId/items/$itemId'),
      headers: headers,
      body: jsonEncode({'name': newName, 'link': link}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to edit item');
    }
  }

  Future<void> deleteItemFromWishList(int wishlistId, int itemId) async {
    final headers = await _getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/wishlists/$wishlistId/items/$itemId'),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete item');
    }
  }
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

  Future<Map<String, String>> _getAuthHeaders({bool json = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<List<WishList>> fetchWishLists() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(Uri.parse('$baseUrl/wishlists'), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => WishList.fromJson(json)).toList();
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
        final error = jsonDecode(response.body)['detail'];
      throw Exception('Failed to reserve gift $error');
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
