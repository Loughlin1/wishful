import 'package:flutter/material.dart';
import 'services.dart';
import 'wishlist_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        title: const Text('Wishful'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _wishListsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Error with loading page...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }
          final wishLists = snapshot.data!;
          final user = FirebaseAuth.instance.currentUser;
          final userId = user?.uid;
          final myWishlists = wishLists.where((w) => w['owner_id'] == userId).toList();
          final sharedWishlists = wishLists.where((w) => w['owner_id'] != userId).toList();
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('My Wishlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  if (myWishlists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('No wishlists found.'),
                        ],
                      ),
                    ),
                  ...myWishlists.map((wishList) => ListTile(
                    title: Row(
                      children: [
                        Text(wishList['owner'] ?? 'No Name'),
                        if (wishList['tag'] != null && wishList['tag'].toString().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              wishList['tag'],
                              style: const TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text('${wishList['items']?.length ?? 0} items'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit Name',
                          onPressed: () => _showEditWishListDialog(wishList),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDeleteWishList(wishList['id']),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WishListDetailsScreen(wishList: wishList),
                        ),
                      );
                    },
                  )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: _showCreateWishListDialog,
                      child: const Text('Create Wish List'),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Friends & Family Wishlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  if (sharedWishlists.isNotEmpty)
                    ...sharedWishlists.map((wishList) => ListTile(
                      title: Row(
                        children: [
                          Text(wishList['owner'] ?? 'No Name'),
                          if (wishList['tag'] != null && wishList['tag'].toString().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                wishList['tag'],
                                style: const TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ],
                        ],
                      ),
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
                    )),
                  if (sharedWishlists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              // You can add invite logic here
                            },
                            child: const Text('Invite family and friends to create a wishlist.'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateWishListDialog() {
    final TextEditingController nameController = TextEditingController();
    String? selectedTag;
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<String>>(
        future: WishListService().fetchTagOptions(),
        builder: (context, snapshot) {
          final tagOptions = snapshot.data ?? [];
          return AlertDialog(
            title: const Text('Create Wish List'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Wish List Name'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTag,
                  items: tagOptions.map((tag) => DropdownMenuItem(
                    value: tag,
                    child: Text(tag),
                  )).toList(),
                  onChanged: (value) {
                    selectedTag = value;
                  },
                  decoration: const InputDecoration(hintText: 'Tag (optional)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.of(context).pop();
                    await _createWishList(name, selectedTag);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createWishList(String name, String? tag) async {
    final newWishList = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'owner': name,
      'items': [
        {'id': 1, 'name': 'New Gift', 'reserved': false, 'reserved_by': null},
      ],
      'shared_with': [],
      'tag': (tag != null && tag.isNotEmpty) ? tag : null,
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
  
  void _showEditWishListDialog(Map wishList) {
    final TextEditingController nameController = TextEditingController(text: wishList['owner'] ?? '');
    String? selectedTag = wishList['tag'];
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<String>>(
        future: WishListService().fetchTagOptions(),
        builder: (context, snapshot) {
          final tagOptions = snapshot.data ?? [];
          return AlertDialog(
            title: const Text('Edit Wish List'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Wish List Name'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTag,
                  items: tagOptions.map((tag) => DropdownMenuItem(
                    value: tag,
                    child: Text(tag),
                  )).toList(),
                  onChanged: (value) {
                    selectedTag = value;
                  },
                  decoration: const InputDecoration(hintText: 'Tag (optional)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    Navigator.of(context).pop();
                    await _editWishList(wishList, newName, selectedTag);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editWishList(Map wishList, String newName, String? newTag) async {
    try {
      final updatedWishList = Map<String, dynamic>.from(wishList);
      updatedWishList['owner'] = newName;
      // Always send the tag field, even if empty, to allow clearing
      updatedWishList['tag'] = (newTag != null && newTag.isNotEmpty) ? newTag : '';
      await WishListService().updateWishList(wishList['id'], updatedWishList);
      setState(() {
        _wishListsFuture = WishListService().fetchWishLists();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update wish list: $e')),
        );
      }
    }
  }

  void _confirmDeleteWishList(int wishlistId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wish List'),
        content: const Text('Are you sure you want to delete this wish list? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteWishList(wishlistId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWishList(int wishlistId) async {
    try {
      await WishListService().deleteWishList(wishlistId);
      setState(() {
        _wishListsFuture = WishListService().fetchWishLists();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete wish list: $e')),
        );
      }
    }
  }
}
