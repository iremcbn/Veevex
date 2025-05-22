import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  Future<void> _deleteFavorite(String docId) async {
    await FirebaseFirestore.instance.collection('favorites').doc(docId).delete();
  }

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
          if (snapshot.hasError) {
            return Center(child: Text("Bir hata oluştu: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Favori istasyonunuz yok."));
          }

          final favorites = snapshot.data!.docs;

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final doc = favorites[index];
              final data = doc.data() as Map<String, dynamic>;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await _deleteFavorite(doc.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${data['stationName']} favorilerden kaldırıldı.")),
                  );
                },
                child: ListTile(
                  leading: const Icon(Icons.ev_station),
                  title: Text(data['stationName'] ?? "İstasyon"),
                  subtitle: Text("Konum: ${data['latitude']}, ${data['longitude']}"),
                  onTap: () {
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}