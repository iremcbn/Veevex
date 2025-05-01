import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'profile_page.dart'; 

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
    _loadCustomStations();
  }

  Future<void> _fetchStations() async {
    final url = Uri.parse(
      'https://api.openchargemap.io/v3/poi/?output=json&countrycode=TR&latitude=40.3522&longitude=27.9706&distance=10&distanceunit=KM',
    );
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
        _markers.addAll(loadedMarkers);
      });
    } else {
      print('API error: ${response.statusCode}');
    }
  }

  Future<void> _addCustomStation(LatLng point) async {
    String? title = await _getTextInput("İstasyon Başlığı Gir:");
    if (title == null || title.isEmpty) return;

    FirebaseFirestore.instance.collection('customStations').add({
      'title': title,
      'latitude': point.latitude,
      'longitude': point.longitude,
    });

    setState(() {
      _markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: point,
          builder: (ctx) => GestureDetector(
            onTap: () => _showReservationDialog(title),
            child: Icon(Icons.ev_station, color: Colors.orange, size: 40),
          ),
        ),
      );
    });
  }

  Future<void> _loadCustomStations() async {
    final snapshot = await FirebaseFirestore.instance.collection('customStations').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final title = data['title'];
      final lat = data['latitude'];
      final lon = data['longitude'];

      setState(() {
        _markers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(lat, lon),
            builder: (ctx) => GestureDetector(
              onTap: () => _showReservationDialog(title),
              child: Icon(Icons.ev_station, color: Colors.orange, size: 40),
            ),
          ),
        );
      });
    }
  }

  Future<void> _saveReservation(String stationTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('reservations').add({
      'userId': user.uid,
      'stationTitle': stationTitle,
      'timestamp': Timestamp.now(),
    });
  }

  Future<String?> _getTextInput(String hint) async {
    String input = '';
    return await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(hint),
          content: TextField(
            onChanged: (value) => input = value,
            decoration: InputDecoration(hintText: "örn: Evdeki Şarj Noktam"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("İptal")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, input), child: Text("Kaydet")),
          ],
        );
      },
    );
  }

  void _showReservationDialog(String stationTitle) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Rezervasyon"),
          content: Text("$stationTitle istasyonuna rezervasyon yapmak istiyor musunuz?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveReservation(stationTitle);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Rezervasyon gönderildi."),
                ));
              },
              child: Text("Evet"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Harita"),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(40.3522, 27.9706), 
          zoom: 13.0,
          onLongPress: (tapPos, latlng) {
            _addCustomStation(latlng); 
          },
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
