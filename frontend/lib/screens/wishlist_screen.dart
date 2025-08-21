import 'package:flutter/material.dart';
import '../services/services.dart';
import '../widgets/wishful_app_bar.dart';
import '../models/wish_list.dart';
import 'wishlist_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/invite_user_dialog.dart';
import '../widgets/share_dialog.dart';


class WishListScreen extends StatefulWidget {
  const WishListScreen({super.key});

  @override
  State<WishListScreen> createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen> {
  late Future<List<WishList>> _wishListsFuture;

  String _ownerFullName(WishList wishList) {
    final first = wishList.ownerFirstName;
    final last = wishList.ownerLastName;
    if ((first != null && first.isNotEmpty) || (last != null && last.isNotEmpty)) {
      return [first, last].where((e) => e != null && e.isNotEmpty).join(' ');
    }
    return wishList.name;
  }

  @override
  void initState() {
    super.initState();
  _wishListsFuture = WishListService().fetchWishLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WishfulAppBar(),
      body: FutureBuilder<List<WishList>>(
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
          final myWishlists = wishLists.where((w) => w.ownerId == userId).toList();
          final sharedWishlists = wishLists.where((w) => w.ownerId != userId).toList();
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 768),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            wishList.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _ownerFullName(wishList),
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (wishList.tag != null && wishList.tag!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              wishList.tag!,
                              style: const TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // subtitle: Text('${wishList.items.length} items'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.green),
                          tooltip: 'Share',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => ShareDialog(wishListId: wishList.id),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit Name',
                          onPressed: () => _showEditWishListDialog(wishList),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDeleteWishList(wishList.id),
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
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0), // adjust as needed
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: ElevatedButton(
                            onPressed: _showCreateWishListDialog,
                            child: const Text('Create new Wish List'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),// Added this for extra space
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Friends & Family Wishlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  if (sharedWishlists.isNotEmpty)
                    ...sharedWishlists.map((wishList) => ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              wishList.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _ownerFullName(wishList),
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (wishList.tag != null && wishList.tag!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                wishList.tag!,
                                style: const TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // subtitle: Text('${wishList.items.length} items'),
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
                              showDialog(
                                context: context,
                                builder: (context) => const InviteUserDialog(),
                              );
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
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    final newWishList = WishList(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      ownerId: userId,
      ownerFirstName: null,
      ownerLastName: null,
      items: [],
      sharedWith: [],
      tag: (tag != null && tag.isNotEmpty) ? tag : null,
    );
    try {
      await WishListService().createWishList(newWishList.toJson());
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
  
  void _showEditWishListDialog(WishList wishList) {
    final TextEditingController nameController = TextEditingController(text: wishList.name);
    String? selectedTag = wishList.tag;
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

  Future<void> _editWishList(WishList wishList, String newName, String? newTag) async {
    try {
      final updatedWishList = WishList(
        id: wishList.id,
        name: newName,
        ownerId: wishList.ownerId,
        ownerFirstName: wishList.ownerFirstName,
        ownerLastName: wishList.ownerLastName,
        items: wishList.items,
        sharedWith: wishList.sharedWith,
        tag: (newTag != null && newTag.isNotEmpty) ? newTag : '',
      );
      await WishListService().updateWishList(wishList.id, updatedWishList.toJson());
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
