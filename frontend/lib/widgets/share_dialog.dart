import 'package:flutter/material.dart';
import '../services/services.dart';

class ShareDialog extends StatefulWidget {
  final int wishListId;
  const ShareDialog({super.key, required this.wishListId});

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _search();
    } else {
      setState(() {
        _results = [];
        _error = '';
      });
    }
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final query = _searchController.text.trim();
    try {
      if (_tabController.index == 0) {
        final users = await WishListService().searchUsers(query);
        setState(() {
          _results = users;
        });
      } else {
        final groups = await WishListService().searchGroups(query);
        setState(() {
          _results = groups;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
        _results = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareWithUser(String email) async {
    try {
      await WishListService().shareWishlistByEmail(widget.wishListId, email);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share link sent to $email')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }

  Future<void> _shareWithGroup(int groupId) async {
    try {
      await WishListService().shareWishlistWithGroup(widget.wishListId, groupId);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wishlist shared with group')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Wishlist'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'User'),
                Tab(text: 'Group'),
              ],
              onTap: (_) => _onSearchChanged(),
            ),
            const SizedBox(height: 8),
            if (_tabController.index == 0) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Invite by email',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading || _searchController.text.trim().isEmpty
                        ? null
                        : () => _shareWithUser(_searchController.text.trim()),
                    child: const Text('Invite'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _tabController.index == 0 ? 'Search users by name or email' : 'Search groups by name',
                suffixIcon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
              ),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _tabController.index == 0
                  ? (_results.isEmpty && !_isLoading
                      ? const Text('No results')
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text('${item.firstName} ${item.lastName}'),
                              subtitle: Text(item.email),
                              trailing: ElevatedButton(
                                onPressed: () => _shareWithUser(item.email),
                                child: const Text('Share'),
                              ),
                            );
                          },
                        ))
                  : (_results.isEmpty && !_isLoading
                      ? const Text('No results')
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            return ListTile(
                              leading: const Icon(Icons.group),
                              title: Text(item.name),
                              subtitle: Text('Owner: ${item.ownerId}'),
                              trailing: ElevatedButton(
                                onPressed: () => _shareWithGroup(item.id),
                                child: const Text('Share'),
                              ),
                            );
                          },
                        )),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
