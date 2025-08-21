import 'package:flutter/material.dart';
import '../services/services.dart';

class InviteUserDialog extends StatefulWidget {
  const InviteUserDialog({super.key});

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _success;

  Future<void> _sendInvite() async {
    setState(() { _isLoading = true; _error = null; _success = null; });
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() { _error = 'Please enter an email address.'; _isLoading = false; });
      return;
    }
    try {
      await WishListService().shareWishlistByEmail(-1, email); // -1 means generic invite, not for a specific wishlist
      setState(() { _success = 'Invite sent to $email!'; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to send invite: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite a User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(hintText: 'Enter email address'),
            keyboardType: TextInputType.emailAddress,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_success != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_success!, style: const TextStyle(color: Colors.green)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendInvite,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send Invite'),
        ),
      ],
    );
  }
}
