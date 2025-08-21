import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'screens/wishlist_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/invite_landing_page.dart';
import 'screens/welcome_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WishfulApp());
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/wishlists',
      builder: (context, state) => const WishListScreen(),
    ),
    GoRoute(
      path: '/share/:inviteCode',
      builder: (context, state) {
        final inviteCode = state.pathParameters['inviteCode']!;
        return InviteLandingPage(inviteCode: inviteCode);
      },
    ),
  ],
  initialLocation: '/',
);

class WishfulApp extends StatelessWidget {
  const WishfulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Wishful',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: _router,
    );
  }
}

