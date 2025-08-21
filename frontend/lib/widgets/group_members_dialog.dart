import 'package:flutter/material.dart';
import '../models/user_search_result.dart';
import '../services/services.dart';

class GroupMembersDialog extends StatefulWidget {
  final String groupName;
  final int groupId;
  const GroupMembersDialog({super.key, required this.groupName, required this.groupId});

  @override
  State<GroupMembersDialog> createState() => _GroupMembersDialogState();
}

class _GroupMembersDialogState extends State<GroupMembersDialog> {
  List<UserSearchResult> _members = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final members = await WishListService().getGroupMembers(widget.groupId);
      setState(() {
        _members = members;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load members: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Members of ${widget.groupName}'),
      content: SizedBox(
        width: 350,
        height: 350,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                : _members.isEmpty
                    ? const Center(child: Text('No members in this group.'))
                    : ListView.builder(
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final user = _members[index];
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text('${user.firstName} ${user.lastName}'),
                            subtitle: Text(user.email),
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
