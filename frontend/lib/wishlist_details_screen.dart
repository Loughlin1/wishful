import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services.dart';

class WishListDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> wishList;
  const WishListDetailsScreen({super.key, required this.wishList});

  @override
  State<WishListDetailsScreen> createState() => _WishListDetailsScreenState();
}

class _WishListDetailsScreenState extends State<WishListDetailsScreen> {
  late List<dynamic> items;
  late String? ownerId;
  late String? currentUserId;
  late List<dynamic> sharedWith;

  // --- Item edit/delete helpers (must be above build for trailing widget callbacks) ---
  void _showEditItemDialog(Map<String, dynamic> item) {
    final TextEditingController controller = TextEditingController(text: item['name'] ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Item name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await _editItem(item['id'], name);
                  if (mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editItem(int itemId, String newName) async {
    try {
      await WishListService().editItemInWishList(widget.wishList['id'], itemId, newName);
      setState(() {
        items = items.map((item) {
          if (item['id'] == itemId) {
            item['name'] = newName;
          }
          return item;
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to edit item: $e')),
        );
      }
    }
  }

  void _deleteItem(int itemId) async {
    try {
      await WishListService().deleteItemFromWishList(widget.wishList['id'], itemId);
      setState(() {
        items.removeWhere((item) => item['id'] == itemId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e')),
        );
      }
    }
  }


  // --- Item edit/delete helpers (must be above build for trailing widget callbacks) ---

  @override
  void initState() {
    super.initState();
    items = widget.wishList['items'] ?? [];
    ownerId = widget.wishList['owner_id'];
    sharedWith = widget.wishList['shared_with'] ?? [];
    currentUserId = null;
    _getCurrentUserId();
  }

  void _getCurrentUserId() async {
    final user = await FirebaseAuth.instance.currentUser;
    setState(() {
      currentUserId = user?.uid;
    });
  }



  void _reserveGift(int itemId) async {
    try {
      final reservedBy = currentUserId ?? 'User';
      await WishListService().reserveGift(widget.wishList['id'], itemId, reservedBy);
      setState(() {
        items = items.map((item) {
          if (item['id'] == itemId) {
            item['reserved'] = true;
            item['reserved_by'] = reservedBy;
          }
          return item;
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reserve gift: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId != null && currentUserId == ownerId;
    final isShared = currentUserId != null && sharedWith.contains(currentUserId);
    return Scaffold(
      appBar: AppBar(title: Text(widget.wishList['owner'] ?? 'Wish List')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['name'] ?? ''),
                subtitle: item['reserved'] == true
                    ? Text('Reserved by \\${item['reserved_by'] ?? 'someone'}', style: const TextStyle(color: Colors.red))
                    : const Text('Available'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOwner) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit',
                        onPressed: () => _showEditItemDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () => _deleteItem(item['id']),
                      ),
                    ]
                    else if (item['reserved'] != true && (isShared || isOwner)) ...[
                      ElevatedButton(
                        onPressed: () => _reserveGift(item['id']),
                        child: const Text('Reserve'),
                      ),
                    ]
                    else if (item['reserved'] == true) ...[
                      const Icon(Icons.lock, color: Colors.red),
                    ]
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              onPressed: _showAddItemDialog,
              child: const Icon(Icons.add),
              tooltip: 'Add Item',
            )
          : null,
    );
  }

  void _showAddItemDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Item'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Item name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await _addItem(name);
                  if (mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addItem(String name) async {
    final newItem = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': name,
      'reserved': false,
      'reserved_by': null,
    };
    try {
      await WishListService().addItemToWishList(widget.wishList['id'], newItem);
      setState(() {
        items.add(newItem);
      });
      // Optionally, update the wishlist on the backend if you want to persist the change
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    }
  }
}
