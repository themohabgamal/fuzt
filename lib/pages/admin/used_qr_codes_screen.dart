import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UsedQRCodesScreen extends StatefulWidget {
  const UsedQRCodesScreen({super.key});

  @override
  _UsedQRCodesScreenState createState() => _UsedQRCodesScreenState();
}

class _UsedQRCodesScreenState extends State<UsedQRCodesScreen> {
  List<Map<String, dynamic>> usedQRCodes = [];
  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    _fetchUsedQRCodes();
  }

  Future<void> _fetchUsedQRCodes() async {
    final firestore = FirebaseFirestore.instance;
    try {
      Query query = firestore
          .collection('qr_codes')
          .doc('used_qr_codes')
          .collection('qr_codes')
          .orderBy('scanned_at', descending: true)
          .limit(30);

      if (fromDate != null) {
        query = query.where('scanned_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate!));
      }
      if (toDate != null) {
        query = query.where('scanned_at',
            isLessThanOrEqualTo: Timestamp.fromDate(toDate!));
      }

      final usedDocs = await query.get();

      setState(() {
        usedQRCodes = usedDocs.docs
            .map((doc) => {
                  'id': doc.id,
                  'discount': doc['discount'],
                  'scanned_at': doc['scanned_at'],
                  'scanned_by': doc['scanned_by'],
                  'customer_phone': doc['customer_phone'] ?? 'N/A',
                })
            .toList();
      });
    } catch (e) {
      _showErrorDialog('Error fetching used QR codes. Please try again later.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQRCode(String id) async {
    final firestore = FirebaseFirestore.instance;
    try {
      await firestore
          .collection('qr_codes')
          .doc('used_qr_codes')
          .collection('qr_codes')
          .doc(id)
          .delete();

      setState(() {
        usedQRCodes.removeWhere((qrCode) => qrCode['id'] == id);
      });
    } catch (e) {
      _showErrorDialog('Error deleting QR code. Please try again later.');
    }
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != fromDate) {
      setState(() {
        fromDate = picked;
        _fetchUsedQRCodes(); // Fetch data after setting the date
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != toDate) {
      setState(() {
        toDate = picked;
        _fetchUsedQRCodes(); // Fetch data after setting the date
      });
    }
  }

  void _resetFilters() {
    setState(() {
      fromDate = null;
      toDate = null;
      _fetchUsedQRCodes(); // Fetch all data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Clear to get all used QR codes',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          if (fromDate != null || toDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _resetFilters,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                    ),
                    onPressed: () => _selectFromDate(context),
                    child: Text(
                      fromDate == null
                          ? 'From Date'
                          : "From: ${DateFormat.yMMMd().format(fromDate!)}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                    ),
                    onPressed: () => _selectToDate(context),
                    child: Text(
                      toDate == null
                          ? 'To Date'
                          : "To: ${DateFormat.yMMMd().format(toDate!)}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: usedQRCodes.length,
                itemBuilder: (context, index) {
                  final qrCode = usedQRCodes[index];
                  final scannedAt = qrCode['scanned_at'] as Timestamp;
                  final formattedDate =
                      DateFormat.yMMMMd().add_jm().format(scannedAt.toDate());

                  return ListTile(
                    title: Text('Discount: ${qrCode['discount']} LE'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${qrCode['id']}'),
                        Text('Scanned At: $formattedDate'),
                        Text('Scanned By: ${qrCode['scanned_by']}'),
                        Text('Customer Phone: ${qrCode['customer_phone']}'),
                      ],
                    ),
                    onTap: () async {
                      final shouldDelete = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor:
                                const Color.fromARGB(255, 28, 26, 53),
                            title: const Text('Confirm'),
                            content: const Text(
                                'Are you sure you want to delete this QR code?'),
                            actions: [
                              ElevatedButton(
                                child: const Text('Cancel'),
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                              ElevatedButton(
                                child: const Text('Yes'),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldDelete) {
                        await _deleteQRCode(qrCode['id']);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
