import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qrcode/pages/login_screen.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  _CashierScreenState createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController scannerController = MobileScannerController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  String cashierName = '';
  bool isProcessing = false; // Flag to control scanning
  bool _showingDialog = false; // Flag to control dialog showing
  late AnimationController _animationController; // Controller for the animation
  late Animation<double> _animation; // Animation for the scan effect
  String? _qrCodeId; // Store QR code ID to process after confirmation
  final TextEditingController _phoneController =
      TextEditingController(); // Controller for phone number input

  @override
  void initState() {
    super.initState();
    _getCurrentUser();

    // Initialize the animation controller and animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Listen to barcode stream
    scannerController.barcodes.listen(_handleBarcode);
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      cashierName = user?.email ?? 'Unknown';
    });
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (isProcessing || _showingDialog) {
      return; // Exit if already processing or dialog is showing
    }

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String qrCodeId = barcode.rawValue!;
      await _processQRCode(qrCodeId); // Process each QR code
      break; // Process only one QR code at a time
    }
  }

  Future<void> _processQRCode(String qrCodeId) async {
    setState(() {
      isProcessing = true; // Set flag to true while processing
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Check in the used QR codes collection first
      final usedDocRef = firestore
          .collection('qr_codes')
          .doc('used_qr_codes')
          .collection('qr_codes')
          .doc(qrCodeId);

      final usedDocSnapshot = await usedDocRef.get();

      if (usedDocSnapshot.exists) {
        // QR code has been used before
        if (!_showingDialog) {
          _showingDialog = true; // Set flag to prevent multiple dialogs
          _showErrorDialog('This QR code has already been used.');
        }
      } else {
        // QR code not found in used collection, check in the shared collection
        final sharedDocRef = firestore
            .collection('qr_codes')
            .doc('shared_qr_codes')
            .collection('qr_codes')
            .doc(qrCodeId);

        final sharedDocSnapshot = await sharedDocRef.get();

        if (sharedDocSnapshot.exists) {
          final qrData = sharedDocSnapshot.data()!;
          if (!(qrData['used'] ?? false)) {
            // QR code is valid and not used
            String discount = qrData['discount'];
            _qrCodeId = qrCodeId; // Store QR code ID for later use

            if (!_showingDialog) {
              _showingDialog = true; // Set flag to prevent multiple dialogs
              _showDiscountDialog(discount, qrCodeId);
            }
          } else {
            if (!_showingDialog) {
              _showingDialog = true; // Set flag to prevent multiple dialogs
              _showErrorDialog('This QR code has already been used.');
            }
          }
        } else {
          // QR code does not exist in either collection, show nothing
        }
      }
    } catch (e) {
      if (!_showingDialog) {
        _showingDialog = true; // Set flag to prevent multiple dialogs
        _showErrorDialog('Error processing QR code. Please try again.');
      }
    } finally {
      setState(() {
        isProcessing = false; // Reset flag after processing
      });
    }
  }

  void _showDiscountDialog(String discount, String qrCodeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple,
        title: const Text('Discount Available!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'This QR code offers a discount of $discount LE. Enter the customer phone number to confirm:'),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final phoneNumber = _phoneController.text;
              if (phoneNumber.length != 11) {
                _showTemporaryMessage(
                    'Please enter a valid phone number with 11 digits.');
              } else {
                Navigator.pop(context);
                await _confirmDiscount(qrCodeId);
                _phoneController.clear();
              }
            },
            child: const Text('Confirm'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showingDialog = false; // Reset flag after dialog is dismissed
              });
              _resumeScanning();
              _phoneController.clear();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    _pauseScanning(); // Pause scanning while dialog is shown
  }

  void _showTemporaryMessage(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _confirmDiscount(String qrCodeId) async {
    if (_qrCodeId != null) {
      final firestore = FirebaseFirestore.instance;

      final sharedDocRef = firestore
          .collection('qr_codes')
          .doc('shared_qr_codes')
          .collection('qr_codes')
          .doc(qrCodeId);

      final usedDocRef = firestore
          .collection('qr_codes')
          .doc('used_qr_codes')
          .collection('qr_codes')
          .doc(qrCodeId);

      try {
        final qrData = (await sharedDocRef.get()).data()!;

        // Mark QR code as used
        await sharedDocRef.update({'used': true});

        // Move QR code to used_qr_codes collection
        await usedDocRef.set({
          ...qrData,
          'scanned_by': cashierName,
          'scanned_at': Timestamp.now(),
          'used': true,
          'customer_phone': _phoneController.text, // Add phone number here
        });

        // Optionally, remove the QR code from the shared collection
        await sharedDocRef.delete();
      } catch (e) {
        // Handle potential errors
        print('Error confirming discount: $e');
      } finally {
        setState(() {
          _showingDialog = false; // Reset flag after confirmation
        });
        _resumeScanning(); // Resume scanning after confirmation
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red,
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showingDialog = false; // Reset flag after dialog is dismissed
              });
              _resumeScanning(); // Resume scanning after dialog is dismissed
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    _pauseScanning(); // Pause scanning while dialog is shown
  }

  void _pauseScanning() {
    scannerController.stop(); // Stop scanning
  }

  void _resumeScanning() {
    scannerController.start(); // Resume scanning
  }

  @override
  void dispose() {
    _animationController.dispose(); // Dispose the animation controller
    _phoneController.dispose(); // Dispose the phone number controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey, // Set the scaffold key for showing snackbars
      appBar: AppBar(
        title: const Text('Cashier Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: scannerController,
              fit: BoxFit.cover,
              onDetect: (barcodes) {
                _handleBarcode(barcodes);
              },
            ),
          ),
          if (isProcessing) // Show loading indicator while processing
            Center(
              child: LoadingAnimationWidget.hexagonDots(
                color: Colors.white,
                size: 30,
              ),
            ),
          if (isProcessing) // Show scan animation overlay
            FadeTransition(
              opacity: _animation,
              child: Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: const Center(
                    child: Text(
                      'Scanning...',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
