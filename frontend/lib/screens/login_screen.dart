import '../../widgets/wishful_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../utils/guest_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? shareToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = Uri.base;
    // Check for /share/<token> or ?token= in the URL
    final segments = uri.pathSegments;
    if (segments.isNotEmpty && segments.first == 'share' && segments.length > 1) {
      shareToken = segments[1];
    } else if (uri.queryParameters['token'] != null) {
      shareToken = uri.queryParameters['token'];
    }
  }

  Future<void> _signInAsGuest() async {
    if (shareToken == null) return;
    final guestService = GuestService();
    final guestUid = await guestService.acceptShareAsGuest(shareToken!);
    if (guestUid != null) {
      // Optionally store guestUid in local storage for session
      // Fetch the shared wishlist (for demo, just show a placeholder)
      // You may want to fetch the wishlist by token or by guestUid
  // Navigate to wishlist details using go_router (you may want to add a route for this)
  // For now, just go to home
  if (mounted) context.go('/wishlists');
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Guest Sign-In Failed'),
          content: const Text('Could not sign in as guest.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;

  Future<void> _login() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (mounted) context.go('/wishlists');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() { errorMessage = 'Email does not exist.'; });
      } else {
        setState(() { errorMessage = e.message; });
      }
    } finally {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WishfulAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                if (errorMessage != null) ...[
                  Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          ElevatedButton(
                            onPressed: _login,
                            child: const Text('Login'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              context.go('/signup');
                            },
                            child: const Text('Don\'t have an account? Sign Up'),
                          ),
                          if (shareToken != null) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.person_outline),
                              label: const Text('Sign in as Guest'),
                              onPressed: _signInAsGuest,
                            ),
                          ],
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
