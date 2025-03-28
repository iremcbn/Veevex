
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: SignupScreen()));
}

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Veevex",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Create an account",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Text("Enter your email to sign up",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              const TextField(
                decoration: InputDecoration(
                  hintText: "email@domain.com",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {},
                child: const Text(
                    "Continue", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 15),
              const Text("or", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 15),
              _buildSocialButton(Icons.g_mobiledata, "Continue with Google"),
              const SizedBox(height: 10),
              _buildSocialButton(Icons.apple, "Continue with Apple"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String text) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50)),
      onPressed: () {},
      icon: Icon(icon, color: Colors.black),
      label: Text(text, style: const TextStyle(color: Colors.black)),
    );
  }
}
