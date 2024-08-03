import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:qrcode/pages/admin/admin_screen.dart';
import 'package:qrcode/pages/admin/home_screen.dart';
import 'package:qrcode/pages/cashier_screen.dart';
import 'package:qrcode/pages/login_screen.dart';
import 'package:qrcode/theme/my_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

createUser() async {
  await FirebaseFirestore.instance.collection('users').add({
    'email': 'admin@fuzt.com',
    'role': 'admin',
  });
  await FirebaseFirestore.instance.collection('users').add({
    'email': 'accountant@fuzt.com',
    'role': 'admin',
  });
  await FirebaseFirestore.instance.collection('users').add({
    'email': 'x_cashier1@fuzt.com',
    'role': 'cashier',
  });
  await FirebaseFirestore.instance.collection('users').add({
    'email': 'x_cashier2@fuzt.com',
    'role': 'cashier',
  });
  await FirebaseFirestore.instance.collection('users').add({
    'email': 'y_cashier1@fuzt.com',
    'role': 'cashier',
  });
  await FirebaseFirestore.instance.collection('users').add({
    'email': 'y_cashier2@fuzt.com',
    'role': 'cashier',
  });
  await FirebaseFirestore.instance.collection('users').add({
    'email': 'z_cashier1@fuzt.com',
    'role': 'cashier',
  });
  await FirebaseFirestore.instance.collection('users').add({
    'email': 'z_cashier2@fuzt.com',
    'role': 'cashier',
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Discount QR Code App',
      theme: ThemeData.light(
        useMaterial3: true,
      ).copyWith(
          splashColor: Colors.transparent,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
          scaffoldBackgroundColor: Colors.white),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/admin': (context) => const AdminScreen(),
        '/home_screen': (context) => const HomeScreen(),
        '/cashier': (context) => const CashierScreen(),
      },
    );
  }
}
