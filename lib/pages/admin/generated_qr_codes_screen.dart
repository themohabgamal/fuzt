import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qrcode/theme/my_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:uuid/uuid.dart';

class GeneratedQRCodesScreen extends StatefulWidget {
  const GeneratedQRCodesScreen({super.key});

  @override
  _GeneratedQRCodesScreenState createState() => _GeneratedQRCodesScreenState();
}

class _GeneratedQRCodesScreenState extends State<GeneratedQRCodesScreen> {
  final GlobalKey _qrKey = GlobalKey();
  String? _currentQrCodeId;

  Future<void> _showQrCodeOptions(BuildContext context, String qrCodeId) async {
    setState(() {
      _currentQrCodeId = qrCodeId;
    });

    await showModalBottomSheet(
      backgroundColor: MyColors.primaryColor,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.white, // White background for the QR code
                      padding: const EdgeInsets.all(
                          8.0), // Padding around the QR code
                      child: SizedBox(
                        width: 75, // Smaller width
                        height: 75, // Smaller height
                        child: RepaintBoundary(
                          key: _qrKey,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(10),
                            child: Center(
                              child: PrettyQrView(
                                qrImage: QrImage(
                                  QrCode.fromData(
                                    data: qrCodeId,
                                    errorCorrectLevel: QrErrorCorrectLevel.H,
                                  ),
                                ),
                                decoration: PrettyQrDecoration(
                                  shape: PrettyQrSmoothSymbol(
                                    color: Colors.black,
                                  ),
                                  image: PrettyQrDecorationImage(
                                    image: const AssetImage(
                                        'assets/fuztr.png'), // Path to your logo
                                    position: PrettyQrDecorationImagePosition
                                        .embedded,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This is your QR code',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                        Text(
                          'Save it or share it now',
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await _handleShareQrCode(context, qrCodeId);
                    },
                    child: const Text('Share'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _handleSaveToGallery(context, qrCodeId);
                    },
                    child: const Text('Save to Gallery'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleShareQrCode(BuildContext context, String qrCodeId) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final RenderRepaintBoundary? boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to render QR code')),
        );
        return;
      }

      try {
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List imageBytes = byteData!.buffer.asUint8List();

        final uniqueId = const Uuid().v4();
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/qr_code_$uniqueId.png';
        final file = File(path);

        await file.writeAsBytes(imageBytes);

        if (await file.exists()) {
          await Share.shareXFiles([XFile(path)],
              text: 'Here is your QR code with logo!');

          bool shared = await _showConfirmationDialog(
              context, 'QR code shared successfully?');
          if (shared) {
            await _moveQrCodeToShared(qrCodeId);
          }
        } else {
          throw Exception('Failed to save image file');
        }
      } catch (e) {
        print('Error capturing QR code: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    });
  }

  Future<void> _handleSaveToGallery(
      BuildContext context, String qrCodeId) async {
    try {
      final RenderRepaintBoundary? boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to render QR code')),
        );
        return;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List imageBytes = byteData!.buffer.asUint8List();

      final uniqueId = const Uuid().v4();
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/qr_code_$uniqueId.png';
      final file = File(path);

      await file.writeAsBytes(imageBytes);

      if (await file.exists()) {
        bool success =
            await GallerySaver.saveImage(path, albumName: 'QR Codes') ?? false;
        if (success) {
          bool saved = await _showConfirmationDialog(
              context, 'Mark this QR code as shared?');
          if (saved) {
            await _moveQrCodeToShared(qrCodeId);
          }
        } else {
          throw Exception('Failed to save image to gallery');
        }
        Navigator.pop(context);
      } else {
        throw Exception('Failed to save image file');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _editQrCodeDiscount(
      String qrCodeId, String currentDiscount) async {
    final firestore = FirebaseFirestore.instance;
    final docRef = firestore
        .collection('qr_codes')
        .doc('generated_qr_codes')
        .collection('qr_codes')
        .doc(qrCodeId);

    TextEditingController discountController =
        TextEditingController(text: currentDiscount);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Discount'),
          content: TextField(
            controller: discountController,
            decoration: const InputDecoration(labelText: 'Discount Amount'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final newDiscount = discountController.text;
                if (newDiscount.isNotEmpty) {
                  await docRef.update({'discount': newDiscount});
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteQrCode(String qrCodeId) async {
    final firestore = FirebaseFirestore.instance;
    final docRef = firestore
        .collection('qr_codes')
        .doc('generated_qr_codes')
        .collection('qr_codes')
        .doc(qrCodeId);

    final shouldDelete = await _showConfirmationDialog(
        context, 'Are you sure you want to delete this QR code?');

    if (shouldDelete) {
      try {
        await docRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.deepPurple,
            content: Text(
              'QR code deleted.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error deleting QR code: $e'),
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: MyColors.secondaryColor,
              title: const Text(
                'Confirmation!',
                style: TextStyle(color: Colors.black),
              ),
              content: Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Yes'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _moveQrCodeToShared(String qrCodeId) async {
    final firestore = FirebaseFirestore.instance;

    final generatedDocRef = firestore
        .collection('qr_codes')
        .doc('generated_qr_codes')
        .collection('qr_codes')
        .doc(qrCodeId);
    final sharedDocRef = firestore
        .collection('qr_codes')
        .doc('shared_qr_codes')
        .collection('qr_codes')
        .doc(qrCodeId);
    try {
      final docSnapshot = await generatedDocRef.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;

        await sharedDocRef.set(data);
        await generatedDocRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.deepPurple,
            content: Text(
              'Moved QR code to shared collection',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Error moving QR code',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('qr_codes')
            .doc('generated_qr_codes')
            .collection('qr_codes')
            .orderBy('id', descending: true) // Sort by ID in descending order
            .limit(30) // Limit to the latest 30 QR codes
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No QR codes found'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              String qrCodeId = data['id'];
              String discount = data['discount'];
              bool used = data['used'];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  tileColor: MyColors.secondaryColor,
                  title: Text('Discount: $discount'),
                  subtitle: Text('QR Code ID: $qrCodeId'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'share') {
                        _showQrCodeOptions(context, qrCodeId);
                      } else if (value == 'edit') {
                        _editQrCodeDiscount(qrCodeId, discount);
                      } else if (value == 'delete') {
                        _deleteQrCode(qrCodeId);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'share',
                        child: Text('Share'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit Discount'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
