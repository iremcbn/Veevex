import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Favori İstasyonlarım")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Favori istasyonunuz yok."));
          }

          final favorites = snapshot.data!.docs;

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final data = favorites[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.ev_station),
                title: Text(data['stationName'] ?? "İstasyon"),
                subtitle: Text("Konum: ${data['latitude']}, ${data['longitude']}"),
              );
            },
          );
        },
      ),
    );
  }
}