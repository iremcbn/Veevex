import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:veevex/pages/map_page.dart';
import 'package:veevex/pages/home_page.dart';
import 'package:veevex/pages/profile_page.dart';
import 'package:veevex/pages/reservation_history_page.dart';
import 'package:veevex/pages/favorites_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
   return MaterialApp(
   title: 'Veevex',
    theme: ThemeData(
     primarySwatch: Colors.green,
      useMaterial3: true,
     ),
     debugShowCheckedModeBanner: false,
     home: AuthGate(),
      routes: {
      '/reservations': (context) => const ReservationHistoryPage(),
      '/favorites': (context) => const FavoritesPage(),
     },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return const MapPage();
        } else {
          return HomePage();
        }
      },
    );
  }
}