import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_search_result.dart';
import '../services/services.dart';

class CreateGroupDialog extends StatefulWidget {
  final void Function(String groupName, List<UserSearchResult> members) onCreate;
  const CreateGroupDialog({super.key, required this.onCreate});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  String _error = '';
  String _userSearchError = '';
  bool _isSearching = false;
  List<UserSearchResult> _userResults = [];
  List<UserSearchResult> _selectedUsers = [];
  Timer? _debounce;
  bool _step2 = false;
  String _groupName = '';
  bool _creating = false;
  String _createError = '';

  @override
  void dispose() {
    _controller.dispose();
    _userSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _submitGroupName() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Group name cannot be empty');
      return;
    }
    setState(() {
      _groupName = name;
      _step2 = true;
      _error = '';
    });
  }

  void _onUserSearchChanged() {
    _debounce?.cancel();
    final query = _userSearchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _userResults = [];
        _userSearchError = '';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() {
        _isSearching = true;
        _userSearchError = '';
      });
      try {
        final users = await WishListService().searchUsers(query);
        setState(() {
          _userResults = users;
        });
      } catch (e) {
        setState(() {
          _userSearchError = 'Search failed: $e';
          _userResults = [];
        });
      } finally {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _toggleUser(UserSearchResult user) {
    setState(() {
      if (_selectedUsers.any((u) => u.email == user.email)) {
        _selectedUsers.removeWhere((u) => u.email == user.email);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _finalSubmit() async {
    setState(() {
      _creating = true;
      _createError = '';
    });
    try {
      final users = _selectedUsers.map((u) => u.email).toList();
      await WishListService().createGroup(_groupName, users);
      widget.onCreate(_groupName, _selectedUsers);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _createError = 'Failed to create group: $e';
      });
    } finally {
      setState(() {
        _creating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_step2 ? 'Add Members' : 'Create Group'),
      content: _step2
          ? SizedBox(
              width: 350,
              height: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Group: $_groupName'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _userSearchController,
                    decoration: const InputDecoration(hintText: 'Search users to add'),
                    onChanged: (_) => _onUserSearchChanged(),
                  ),
                  if (_userSearchError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_userSearchError, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _isSearching
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: _userResults.length,
                            itemBuilder: (context, index) {
                              final user = _userResults[index];
                              final selected = _selectedUsers.any((u) => u.email == user.email);
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text('${user.firstName} ${user.lastName}'),
                                subtitle: Text(user.email),
                                trailing: Checkbox(
                                  value: selected,
                                  onChanged: (_) => _toggleUser(user),
                                ),
                                onTap: () => _toggleUser(user),
                              );
                            },
                          ),
                  ),
                  if (_selectedUsers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        children: _selectedUsers
                            .map((u) => Chip(label: Text('${u.firstName} ${u.lastName}')))
                            .toList(),
                      ),
                    ),
                  if (_createError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_createError, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Group name'),
                  autofocus: true,
                  onSubmitted: (_) => _submitGroupName(),
                ),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_error, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
      actions: _step2
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _creating ? null : _finalSubmit,
                child: _creating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create Group'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _submitGroupName,
                child: const Text('Next'),
              ),
            ],
    );
  }
}
