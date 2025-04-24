import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _fetchStations();
  }

  Future<void> _fetchStations() async {
    final url = Uri.parse(
        'https://api.openchargemap.io/v3/poi/?output=json&countrycode=TR&latitude=40.3522&longitude=27.9706&distance=10&distanceunit=KM');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List<Marker> loadedMarkers = [];
      for (var station in data) {
        final lat = station['AddressInfo']['Latitude'];
        final lon = station['AddressInfo']['Longitude'];
        final title = station['AddressInfo']['Title'];

        loadedMarkers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(lat, lon),
            builder: (ctx) => Icon(
              Icons.ev_station,
              color: Colors.green,
              size: 40,
            ),
          ),
        );
      }

      setState(() {
        _markers = loadedMarkers;
      });
    } else {
      print('API error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Harita")),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(40.3522, 27.9706),
          zoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}