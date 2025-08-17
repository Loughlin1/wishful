import 'dart:convert';
import 'package:http/http.dart' as http;

class WishListService {
  static const String baseUrl = 'http://localhost:8000';

  Future<List<dynamic>> fetchWishLists() async {
    final response = await http.get(Uri.parse('$baseUrl/wishlists'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load wish lists');
    }
  }
  Future<void> createWishList(Map<String, dynamic> wishList) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wishlists'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(wishList),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create wish list');
    }
  }
  Future<void> reserveGift(int wishlistId, int itemId, String reservedBy) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wishlists/$wishlistId/reserve/$itemId?reserved_by=$reservedBy'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reserve gift');
    }
  }
  Future<void> addItemToWishList(int wishlistId, Map<String, dynamic> item) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wishlists/$wishlistId/items'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add item to wish list');
    }
  }
}
