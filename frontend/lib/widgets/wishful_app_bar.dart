import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'invite_user_dialog.dart';

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
            : Row(
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.account_circle, color: Colors.black),
                    onSelected: (value) async {
                      if (value == 'invite') {
                        showDialog(
                          context: context,
                          builder: (context) => const InviteUserDialog(),
                        );
                      } else if (value == 'logout') {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) context.go('/');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'invite',
                        child: ListTile(
                          leading: Icon(Icons.mail_outline),
                          title: Text('Invite'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: ListTile(
                          leading: Icon(Icons.logout),
                          title: Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
