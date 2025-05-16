import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatelessWidget {
  final String paymentUrl;

  const PaymentWebView({Key? key, required this.paymentUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ödeme Sayfası')),
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
