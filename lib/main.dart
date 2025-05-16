import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
      home: const AuthGate(),
      routes: {
        '/reservations': (context) => ReservationHistoryPage(),
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


Future<String?> createPayment({
  required String email,
  required String stationTitle,
  required double amount,
  String userIp = '127.0.0.1',
}) async {
  final url = Uri.parse('https://yourbackend.com/api/payment/create'); 

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'Email': email,
      'StationTitle': stationTitle,
      'Amount': amount,
      'UserIp': userIp,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['paymentUrl'];
  } else {
    return null;
  }
}


class PaymentWebView extends StatelessWidget {
  final String paymentUrl;

  const PaymentWebView({Key? key, required this.paymentUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme Sayfası')),
      body: WebView(
        initialUrl: paymentUrl,
        javascriptMode: JavascriptMode.unrestricted,
        navigationDelegate: (NavigationRequest request) {
          if (request.url.contains('odeme-basarili')) {
            Navigator.pop(context, 'success');
            return NavigationDecision.prevent;
          } else if (request.url.contains('odeme-hata')) {
            Navigator.pop(context, 'failure');
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }
}

class PaymentHomePage extends StatelessWidget {
  const PaymentHomePage({Key? key}) : super(key: key);

  void startPayment(BuildContext context) async {
    final paymentUrl = await createPayment(
      email: 'kullanici@mail.com',
      stationTitle: 'My Station',
      amount: 10.0,
    );

    if (paymentUrl != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebView(paymentUrl: paymentUrl),
        ),
      );

      if (result == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödeme başarılı!')),
        );
      } else if (result == 'failure') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödeme başarısız.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödeme sayfası alınamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme Örneği')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => startPayment(context),
          child: const Text('Ödemeyi Başlat'),
        ),
      ),
    );
  }
}
