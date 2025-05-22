import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          onNavigationRequest: (navigation) async {
            final url = navigation.url;
            if (url.contains('odeme-basarili')) {
              final uri = Uri.parse(url);
              final station = uri.queryParameters['station'] ?? 'Bilinmeyen';
              final timeString = uri.queryParameters['time'];
              final priceString = uri.queryParameters['price'];
              final durationString = uri.queryParameters['duration'] ?? '1';

              if (timeString != null && priceString != null) {
                final reservationTime = DateTime.tryParse(timeString);
                final price = double.tryParse(priceString);
                final durationInHours = int.tryParse(durationString) ?? 1;
                final user = FirebaseAuth.instance.currentUser;

                if (reservationTime != null && price != null && user != null) {
                  await _saveReservationToFirestore(
                    userId: user.uid,
                    stationTitle: station,
                    reservationDateTime: reservationTime,
                    price: price,
                    durationInHours: durationInHours,
                  );
                }
              }

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

  Future<void> _saveReservationToFirestore({
    required String userId,
    required String stationTitle,
    required DateTime reservationDateTime,
    required double price,
    required int durationInHours,
  }) async {
    final totalAmount = price * durationInHours;

    await FirebaseFirestore.instance.collection('reservations').add({
      'userId': userId,
      'stationTitle': stationTitle,
      'reservationTime': Timestamp.fromDate(reservationDateTime),
      'pricePerHour': price,
      'duration': durationInHours,
      'totalAmount': totalAmount,
      'timestamp': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ödeme")),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}