import 'package:flutter/material.dart';
import 'dart:async';
import '../services/services.dart';
import '../models/user_search_result.dart';
import '../models/group_search_result.dart';
import 'create_group_dialog.dart';
import 'group_members_dialog.dart';

class ShareDialog extends StatefulWidget {
  final int wishListId;
  const ShareDialog({super.key, required this.wishListId});

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<UserSearchResult> _results = [];
  List<GroupSearchResult> _groupResults = [];
  bool _isLoading = false;
  String _error = '';
  Timer? _debounce;
  int _tabIndex = 0; // 0 = Users, 1 = Groups

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _groupResults = [];
        _error = '';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_tabIndex == 0) {
        _search();
      } else {
        _searchGroups();
      }
    });
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final query = _searchController.text.trim();
    try {
      final users = await WishListService().searchUsers(query);
      if (!mounted) return;
      setState(() {
        _results = users;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Search failed: $e';
        _results = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchGroups() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final query = _searchController.text.trim();
    try {
      final groups = await WishListService().searchGroups(query);
      if (!mounted) return;
      setState(() {
        _groupResults = groups;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Search failed: $e';
        _groupResults = [];
      });
    } finally {
      if (!mounted) return;
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
        SnackBar(content: Text('Failed to share with group: $e')),
      );
    }
  }

  bool get _hasExactMatch {
    final input = _searchController.text.trim().toLowerCase();
    return _results.any((u) =>
      u.email.toLowerCase() == input ||
      ('${u.firstName} ${u.lastName}'.trim().toLowerCase() == input)
    );
  }

  @override
  Widget build(BuildContext context) {
    final input = _searchController.text.trim();
    final showInvite = input.isNotEmpty && !_hasExactMatch && !_isLoading;
    return DefaultTabController(
      length: 2,
      initialIndex: _tabIndex,
      child: AlertDialog(
        title: const Text('Share Wishlist'),
        content: SizedBox(
          width: 350,
          height: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                onTap: (i) {
                  setState(() {
                    _tabIndex = i;
                    _onSearchChanged();
                  });
                },
                tabs: const [
                  Tab(text: 'Users'),
                  Tab(text: 'Groups'),
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
              ),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _tabIndex == 0 ? 'Enter name or email' : 'Enter group name',
                ),
                keyboardType: TextInputType.text,
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_error, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          ListView.builder(
                            itemCount: _results.length + (showInvite ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (showInvite && index == 0) {
                                return ListTile(
                                  leading: const Icon(Icons.person_add_alt_1),
                                  title: Text('Invite "$input"'),
                                  subtitle: Text('Send invite to this email'),
                                  trailing: ElevatedButton(
                                    onPressed: () => _shareWithUser(input),
                                    child: const Text('Invite'),
                                  ),
                                );
                              }
                              final resultIndex = showInvite ? index - 1 : index;
                              if (_results.isEmpty && !showInvite) {
                                return const ListTile(
                                  title: Text('No users found'),
                                );
                              }
                              final item = _results[resultIndex];
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
                          ),
                          ListView.builder(
                            itemCount: _groupResults.isEmpty ? 1 : _groupResults.length,
                            itemBuilder: (context, index) {
                              if (_groupResults.isEmpty) {
                                final input = _searchController.text.trim();
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ListTile(
                                      title: Text(
                                        input.isEmpty
                                            ? 'Please search for a group'
                                            : 'No groups found',
                                      ),
                                    ),
                                    if (input.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.add),
                                        label: const Text('Create Group'),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => CreateGroupDialog(
                                              onCreate: (groupName, members) {
                                                // TODO: Call your group creation service here
                                                // Optionally refresh group search after creation
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                );
                              }
                              final group = _groupResults[index];
                              return ListTile(
                                leading: const Icon(Icons.group),
                                title: Text(group.name),
                                subtitle: Text('Group ID: ${group.id}'),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => GroupMembersDialog(
                                      groupName: group.name,
                                      groupId: group.id,
                                    ),
                                  );
                                },
                                trailing: ElevatedButton(
                                  onPressed: () => _shareWithGroup(group.id),
                                  child: const Text('Share'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
      ),
    );
  }
}
