import 'package:flutter/material.dart';
import 'services.dart';
import 'package:go_router/go_router.dart';

class InviteLandingPage extends StatefulWidget {
  final String inviteCode;
  const InviteLandingPage({super.key, required this.inviteCode});

  @override
  State<InviteLandingPage> createState() => _InviteLandingPageState();
}

class _InviteLandingPageState extends State<InviteLandingPage> {
  String? inviterName;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchInviteInfo();
  }

  Future<void> fetchInviteInfo() async {
    try {
      final info = await WishListService().fetchInviteInfo(widget.inviteCode);
      setState(() {
        inviterName = info['invite_username'];
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = "Invalid or expired invite link.";
        loading = false;
      });
    }
  }

  void goToSignup() {
    context.go('/signup?inviteCode=${widget.inviteCode}');
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        body: Center(child: Text(error!)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Wishful Invite")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to Wishful!",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              "You have been invited by $inviterName.\nPlease sign up to access their wishlist.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: goToSignup,
              child: const Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
