import 'package:flutter/material.dart';
import 'map_page.dart';
import '../services/auth_service.dart';

class HomePage extends StatelessWidget {
  final authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Şarj İstasyonları")),
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.login),
          label: Text("Google ile Giriş Yap"),
          onPressed: () async {
            final user = await authService.signInWithGoogle(context);
            if (user != null) {
              print("Giriş yapan kullanıcı: ${user.displayName}");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapPage()),
              );
            } else {
              print("Giriş başarısız");
            }
          },
        ),
      ),
    );
  }
}