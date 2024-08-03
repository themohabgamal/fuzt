import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:ui' as ui;

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _discountController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();

  void _generateQRCode() async {
    String discount = _discountController.text;
    if (discount.isEmpty) return;

    for (int i = 0; i < 10; i++) {
      String qrCodeId = '${DateTime.now().millisecondsSinceEpoch}_$i';

      await FirebaseFirestore.instance
          .collection('qr_codes')
          .doc('generated_qr_codes')
          .collection('qr_codes')
          .doc(qrCodeId)
          .set({
        'id': qrCodeId,
        'discount': discount,
        'used': false,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.deepPurple,
        content: Text(
          '10 QR Codes generated with $discount LE discount',
          style: const TextStyle(color: Colors.white),
        )));
  }

  Future<void> requestPermission() async {
    if (await Permission.storage.request().isGranted) {
      // Permission is granted
    } else {
      // Permission is denied
      await Permission.storage.request();
    }
  }

  Future<void> _saveQRCode() async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/qr_code_with_logo.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      await requestPermission();

      await GallerySaver.saveImage(file.path, albumName: 'QRCodeApp');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code saved to gallery')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save QR Code')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _discountController,
              decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurple, width: 1),
                  ),
                  labelText: 'Discount Amount'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _generateQRCode,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Generate QR Code',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_discountController.text.isNotEmpty) ...[
              RepaintBoundary(
                key: _qrKey,
                child: PrettyQrView(
                  qrImage: QrImage(
                    QrCode.fromData(
                      data: _discountController.text,
                      errorCorrectLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                  decoration: PrettyQrDecoration(
                    shape: PrettyQrSmoothSymbol(
                      color: Colors.blue,
                    ),
                    image: PrettyQrDecorationImage(
                      image: const AssetImage(
                          'assets/fuztr.png'), // Path to your logo
                      position: PrettyQrDecorationImagePosition.embedded,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveQRCode,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Save QR Code',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
