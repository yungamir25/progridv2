// check_email_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authentication/login_page.dart';

class CheckEmailPage extends StatefulWidget {
  const CheckEmailPage({super.key});

  @override
  _CheckEmailPageState createState() => _CheckEmailPageState();
}

class _CheckEmailPageState extends State<CheckEmailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Sign out the current user before navigating back.
            await FirebaseAuth.instance.signOut();
            // Navigate back to the previous screen, which is the login page.
            Navigator.pop(context, LoginScreen());
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'A verification link has been sent to your email address. Please click the link to verify your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  User? user = FirebaseAuth.instance.currentUser;
                  await user?.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification link resent.'),
                    ),
                  );
                },
                child: const Text('Resend Email'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  User? user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    await user.reload();

                    if (user.emailVerified) {
                      Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email not yet verified. Please try again after verifying.'),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No user is currently signed in. Please sign in again.'),
                      ),
                    );
                  }
                },
                child: const Text('I have verified my email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}