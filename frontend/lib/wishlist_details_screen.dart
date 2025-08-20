import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services.dart';
import 'models.dart';


class WishListDetailsScreen extends StatefulWidget {
  final WishList wishList;
  const WishListDetailsScreen({super.key, required this.wishList});

  @override
  State<WishListDetailsScreen> createState() => _WishListDetailsScreenState();
}

class _WishListDetailsScreenState extends State<WishListDetailsScreen> {
  late List<WishItem> items;
  late String? ownerId;
  late String? currentUserId;
  late List<String>? sharedWith;

  @override
  void initState() {
    super.initState();
    items = widget.wishList.items;
    ownerId = widget.wishList.ownerId;
    sharedWith = widget.wishList.sharedWith;
    currentUserId = null;
    _getCurrentUserId();
  }

  void _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      currentUserId = user?.uid;
    });
  }

  void _showEditItemDialog(WishItem item) {
    final TextEditingController controller = TextEditingController(text: item.name);
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
              onPressed: () {
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await _editItem(item.id, name);
                  if (!mounted) return;
                  Navigator.of(context).pop();
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
      await WishListService().editItemInWishList(widget.wishList.id, itemId, newName);
      setState(() {
        items = items.map((item) {
          if (item.id == itemId) {
            return WishItem(
              id: item.id,
              name: newName,
              reserved: item.reserved,
              reservedBy: item.reservedBy,
            );
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
      await WishListService().deleteItemFromWishList(widget.wishList.id, itemId);
      setState(() {
        items.removeWhere((item) => item.id == itemId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e')),
        );
      }
    }
  }

  void _reserveGift(int itemId) async {
    try {
      final reservedBy = currentUserId ?? 'User';
      await WishListService().reserveGift(widget.wishList.id, itemId, reservedBy);
      setState(() {
        items = items.map((item) {
          if (item.id == itemId) {
            return WishItem(
              id: item.id,
              name: item.name,
              reserved: true,
              reservedBy: reservedBy,
            );
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
              onPressed: () {
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await _addItem(name);
                  if (!mounted) return;
                  Navigator.of(context).pop();
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
    final newItem = WishItem(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      reserved: false,
      reservedBy: null,
    );
    try {
      await WishListService().addItemToWishList(widget.wishList.id, newItem.toJson());
      setState(() {
        items.add(newItem);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId != null && currentUserId == ownerId;
    final isShared = currentUserId != null && (sharedWith?.contains(currentUserId) ?? false);
    return Scaffold(
      appBar: AppBar(title: Text(widget.wishList.name)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              Expanded(
                child: items.isEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 16.0, left: 16.0),
                            child: Text('No items found'),
                          ),
                          if (isOwner)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                              child: ElevatedButton.icon(
                                onPressed: _showAddItemDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                              ),
                            ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: isOwner ? items.length + 1 : items.length,
                        itemBuilder: (context, index) {
                          if (index < items.length) {
                            final item = items[index];
                            return ListTile(
                              title: Text(item.name),
                              subtitle: item.reserved
                                  ? Text('Reserved by ${item.reservedBy ?? 'someone'}', style: const TextStyle(color: Colors.red))
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
                                      onPressed: () => _deleteItem(item.id),
                                    ),
                                  ]
                                  else if (!item.reserved && (isShared || isOwner)) ...[
                                    ElevatedButton(
                                      onPressed: () => _reserveGift(item.id),
                                      child: const Text('Reserve'),
                                    ),
                                  ]
                                  else if (item.reserved) ...[
                                    const Icon(Icons.lock, color: Colors.red),
                                  ]
                                ],
                              ),
                            );
                          } else {
                            // Add Item button as the last row
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: ElevatedButton.icon(
                                onPressed: _showAddItemDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                              ),
                            );
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
