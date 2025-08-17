import 'package:flutter/material.dart';
import 'services.dart';
import 'wishlist_details_screen.dart';

class WishListScreen extends StatefulWidget {
  const WishListScreen({super.key});

  @override
  State<WishListScreen> createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen> {
  late Future<List<dynamic>> _wishListsFuture;

  @override
  void initState() {
    super.initState();
    _wishListsFuture = WishListService().fetchWishLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wish Lists'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _wishListsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No wish lists found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createWishList,
                    child: const Text('Create Wish List'),
                  ),
                ],
              ),
            );
          }
          final wishLists = snapshot.data!;
          return ListView.builder(
            itemCount: wishLists.length,
            itemBuilder: (context, index) {
              final wishList = wishLists[index];
              return ListTile(
                title: Text(wishList['owner'] ?? 'No Name'),
                subtitle: Text('${wishList['items']?.length ?? 0} items'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WishListDetailsScreen(wishList: wishList),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createWishList,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createWishList() async {
    // For demo: create a wish list with a random id and default values
    final newWishList = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'owner': 'User',
      'items': [
        {'id': 1, 'name': 'New Gift', 'reserved': false, 'reserved_by': null},
      ],
    };
    try {
      await WishListService().createWishList(newWishList);
      setState(() {
        _wishListsFuture = WishListService().fetchWishLists();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create wish list: $e')),
        );
      }
    }
  }
}
