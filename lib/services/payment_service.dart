import 'dart:convert';
import 'package:http/http.dart' as http;

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
