import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;

  Future<void> _signUp() async {
    setState(() { isLoading = true; errorMessage = null; });
    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        errorMessage = 'Passwords do not match';
        isLoading = false;
      });
      return;
    }
    if (firstNameController.text.trim().isEmpty || lastNameController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'First and last name are required';
        isLoading = false;
      });
      return;
    }
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final user = userCredential.user;
      if (user != null) {
        // Send user info to backend
        final token = await user.getIdToken();
        final response = await registerUser(
          uid: user.uid,
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          email: emailController.text.trim(),
          token: token,
        );
        if (!response) {
          setState(() { errorMessage = 'Failed to register user on server.'; });
          return;
        }
      }
      if (mounted) Navigator.of(context).pop(); // Go back to login
    } on FirebaseAuthException catch (e) {
      setState(() { errorMessage = e.message; });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  Future<bool> registerUser({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    required String? token,
  }) async {
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '{"uid": "$uid", "first_name": "$firstName", "last_name": "$lastName", "email": "$email"}',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
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
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                if (errorMessage != null) ...[
                  Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signUp,
                        child: const Text('Sign Up'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
