import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/charge_station.dart';

class ChargeApiService {
  static Future<List<ChargeStation>> fetchStations(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://api.openchargemap.io/v3/poi/?output=json&countrycode=TR&latitude=$latitude&longitude=$longitude&maxresults=20&compact=true&verbose=false');

    final response = await http.get(url, headers: {
      'X-API-Key': 'ec9a2cf1-dcff-482c-9489-49fb79fdac87'
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ChargeStation.fromJson(json)).toList();
    } else {
      throw Exception('İstasyonlar alınamadı: ${response.statusCode}');
    }
  }
}