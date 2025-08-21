import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/services.dart';
import '../models/wish_list.dart';
import '../models/wish_item.dart';
import '../widgets/wishful_app_bar.dart';
import '../widgets/share_dialog.dart';


class WishListDetailsScreen extends StatefulWidget {
  final WishList wishList;
  const WishListDetailsScreen({super.key, required this.wishList});

  @override
  State<WishListDetailsScreen> createState() => _WishListDetailsScreenState();
}

class _WishListDetailsScreenState extends State<WishListDetailsScreen> {
  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return ShareDialog(wishListId: widget.wishList.id);
      },
    );
  }
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
    final TextEditingController nameController = TextEditingController(text: item.name);
    final TextEditingController linkController = TextEditingController(text: item.link ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Item name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(hintText: 'Link (optional)'),
              ),
            ],
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
                final name = nameController.text.trim();
                final link = linkController.text.trim();
                if (name.isNotEmpty) {
                  await _editItem(item.id, name, link);
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

  Future<void> _editItem(int itemId, String newName, String link) async {
    try {
      await WishListService().editItemInWishList(widget.wishList.id, itemId, newName, link);
      setState(() {
        items = items.map((item) {
          if (item.id == itemId) {
            return WishItem(
              id: item.id,
              name: newName,
              reserved: item.reserved,
              reservedBy: item.reservedBy,
              link: link.isNotEmpty ? link : null,
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
    final TextEditingController nameController = TextEditingController();
    final TextEditingController linkController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Item name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(hintText: 'Link (optional)'),
              ),
            ],
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
                final name = nameController.text.trim();
                final link = linkController.text.trim();
                if (name.isNotEmpty) {
                  await _addItem(name, link);
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

  Future<void> _addItem(String name, String link) async {
    final newItem = WishItem(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      reserved: false,
      reservedBy: null,
      link: link.isNotEmpty ? link : null,
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
      appBar: const WishfulAppBar(),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // Title row above the items
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.wishList.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.black),
                        tooltip: 'Share Wishlist',
                        onPressed: _showShareDialog,
                        padding: const EdgeInsets.only(left: 0, right: 0),
                        constraints: BoxConstraints(),
                      ),
                  ],
                ),
              ),
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (item.link != null && item.link!.isNotEmpty)
                                    GestureDetector(
                                      onTap: () async {
                                        final url = Uri.parse(item.link!);
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        }
                                      },
                                      child: Text(
                                        item.link!.length > 40
                                            ? '${item.link!.substring(0, 37)}...'
                                            : item.link!,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  item.reserved
                                      ? Text('Reserved by ${item.reservedBy ?? 'someone'}', style: const TextStyle(color: Colors.red))
                                      : const Text('Available'),
                                ],
                              ),
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
