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

Future<String?> createPayment({
  required String email,
  required String stationTitle,
  required double amount,
  String userIp = '127.0.0.1',
}) async {
  final url = Uri.parse('https://yourbackend.com/api/payment/create');

  try {
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
      debugPrint('Payment creation failed: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    debugPrint('Error creating payment: $e');
    return null;
  }
}

class PaymentPage extends StatefulWidget {
  final String paymentUrl;

  const PaymentPage({required this.paymentUrl, Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (navigation) {
            final url = navigation.url;
            if (url.contains('odeme-basarili')) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            } else if (url.contains('odeme-hata')) {
              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ödeme")),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
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
          builder: (_) => PaymentPage(paymentUrl: paymentUrl),
        ),
      );

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödeme başarılı!')),
        );
      } else if (result == false) {
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