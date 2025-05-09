import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favori İstasyonlarım"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Hiç favori istasyon bulunamadı.'));
          }

          final favoriteDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: favoriteDocs.length,
            itemBuilder: (context, index) {
              final favorite = favoriteDocs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(favorite['stationName'] ?? 'İstasyon'),
                  subtitle: Text(
                    "Konum: ${favorite['latitude'].toStringAsFixed(4)}, ${favorite['longitude'].toStringAsFixed(4)}",
                  ),
                  trailing: const Icon(Icons.favorite, color: Colors.red),
                ),
              );
            },
          );
        },
      ),
    );
  }
}