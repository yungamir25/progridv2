// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pages/home_screen.dart'; // Import the home screen
import 'authentication/login_page.dart'; // Import the login screen
import '../pages/check_email.dart'; // Import the check email page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tower Progress Tracking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Use initialRoute to specify the starting page
      initialRoute: '/',
      // Define all your named routes here
      routes: {
        '/': (context) => const AuthWrapper(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/check_email': (context) => const CheckEmailPage(),
      },
    );
  }
}

// AuthWrapper widget to decide which screen to show based on user's authentication status
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          // Reload the user to get the latest email verification status
          user.reload();
          if (user.emailVerified) {
            return const HomeScreen();
          } else {
            return const CheckEmailPage();
          }
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}