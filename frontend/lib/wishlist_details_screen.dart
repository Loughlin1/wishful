import 'package:flutter/material.dart';
import 'services.dart';

class WishListDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> wishList;
  const WishListDetailsScreen({super.key, required this.wishList});

  @override
  State<WishListDetailsScreen> createState() => _WishListDetailsScreenState();
}

class _WishListDetailsScreenState extends State<WishListDetailsScreen> {
  late List<dynamic> items;

  @override
  void initState() {
    super.initState();
    items = widget.wishList['items'] ?? [];
  }

  void _reserveGift(int itemId) async {
    try {
      await WishListService().reserveGift(widget.wishList['id'], itemId, 'User');
      setState(() {
        items = items.map((item) {
          if (item['id'] == itemId) {
            item['reserved'] = true;
            item['reserved_by'] = 'User';
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.wishList['owner'] ?? 'Wish List')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(item['name'] ?? ''),
            subtitle: item['reserved'] == true
                ? Text('Reserved by \\${item['reserved_by'] ?? 'someone'}', style: const TextStyle(color: Colors.red))
                : const Text('Available'),
            trailing: item['reserved'] == true
                ? const Icon(Icons.lock, color: Colors.red)
                : ElevatedButton(
                    onPressed: () => _reserveGift(item['id']),
                    child: const Text('Reserve'),
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Item',
      ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    }
  }
}
