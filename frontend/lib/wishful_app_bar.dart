import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class WishfulAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WishfulAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundImage: AssetImage('web/icons/wishful_icon.jpg'),
            radius: 20,
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 12),
          const Text('Wishful'),
        ],
      ),
      actions: [
        user == null
            ? TextButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login, color: Colors.black),
                label: const Text('Log in', style: TextStyle(color: Colors.black)),
              )
            : TextButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) context.go('/');
                },
                icon: const Icon(Icons.logout, color: Colors.black),
                label: const Text('Logout', style: TextStyle(color: Colors.black)),
              ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
