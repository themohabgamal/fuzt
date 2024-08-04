import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qrcode/theme/my_colors.dart';

class SharedQRCodesScreen extends StatefulWidget {
  const SharedQRCodesScreen({super.key});

  @override
  State<SharedQRCodesScreen> createState() => _SharedQRCodesScreenState();
}

class _SharedQRCodesScreenState extends State<SharedQRCodesScreen> {
  Future<void> _clearSharedQRCodes() async {
    final firestore = FirebaseFirestore.instance;
    final collectionRef = firestore
        .collection('qr_codes')
        .doc('shared_qr_codes')
        .collection('qr_codes');

    try {
      // Get all documents in the collection
      final querySnapshot = await collectionRef.get();

      // Delete each document
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.deepPurple,
            content: Text(
              'Shared QR codes have been deleted successfully',
              style: TextStyle(color: Colors.white),
            )),
      );
    } catch (e) {
      print('Error clearing shared QR codes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            child: const Row(
              children: [
                Text("Clear All"),
                Icon(Icons.clear),
              ],
            ),
            onPressed: () async {
              final shouldClear = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: MyColors.secondaryColor,
                    title: const Text(
                      'Confirm',
                      style: TextStyle(color: Colors.black),
                    ),
                    content: const Text(
                      'Are you sure you want to clear all shared QR codes?',
                      style: TextStyle(color: Colors.black),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: const Text('Yes'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  );
                },
              );

              if (shouldClear) {
                await _clearSharedQRCodes();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('qr_codes')
            .doc('shared_qr_codes')
            .collection('qr_codes')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No Shared QR codes found'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              String qrCodeId = data['id'];
              String discount = data['discount'];
              bool used = data['used'];

              return ListTile(
                title: Text('Discount: $discount'),
                subtitle: Text('QR Code ID: $qrCodeId'),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
