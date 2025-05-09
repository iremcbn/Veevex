import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  final LatLng _initialPosition = LatLng(35.6896, -0.6412);
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() {
    setState(() {
      _markers.addAll([
        Marker(
          markerId: MarkerId('1'),
          position: LatLng(35.6896, -0.6412),
          infoWindow: InfoWindow(title: 'Şarj İstasyonu 1'),
          onTap: () => _toggleFavorite('1', 'Şarj İstasyonu 1', 35.6896, -0.6412),
        ),
        Marker(
          markerId: MarkerId('2'),
          position: LatLng(36.7538, 3.042),
          infoWindow: InfoWindow(title: 'Şarj İstasyonu 2'),
          onTap: () => _toggleFavorite('2', 'Şarj İstasyonu 2', 36.7538, 3.042),
        ),
      ]);
    });
  }

  Future<void> _toggleFavorite(String stationId, String name, double lat, double lng) async {
    final favorites = FirebaseFirestore.instance.collection('favorites');
    final doc = await favorites
        .where('userId', isEqualTo: uid)
        .where('stationId', isEqualTo: stationId)
        .limit(1)
        .get();

    if (doc.docs.isEmpty) {
      await favorites.add({
        'userId': uid,
        'stationId': stationId,
        'stationName': name,
        'latitude': lat,
        'longitude': lng,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$name favorilere eklendi")),
      );
    } else {
      await favorites.doc(doc.docs.first.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$name favorilerden çıkarıldı")),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Şarj İstasyonları Haritası'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              Navigator.pushNamed(context, '/favorites');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 7.0,
            ),
            markers: _markers,
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Konum Ara...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Harita'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Ödemeler'),
          BottomNavigationBarItem(icon: Icon(Icons.add_location), label: 'İstasyon Ekle'),
        ],
        onTap: (index) {},
      ),
    );
  }
}