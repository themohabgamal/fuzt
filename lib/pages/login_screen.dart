import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:qrcode/theme/my_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isPasswordVisible = false; // Password visibility state
  bool isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
    // Check if the user is already logged in
    _checkIfLoggedIn();
  }

  void _checkIfLoggedIn() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Get user role
      String role = await getUserRole(user.uid);
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/home_screen');
      } else if (role == 'cashier') {
        Navigator.pushReplacementNamed(context, '/cashier');
      }
    } else {
      setState(() {
        isLoading = false; // Hide loading indicator if no user is logged in
      });
    }
  }

  void _login() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Get user role
      String role = await getUserRole(userCredential.user!.uid);
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/home_screen');
      } else if (role == 'cashier') {
        Navigator.pushReplacementNamed(context, '/cashier');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<String> getUserRole(String uid) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    print(userDoc['role']);
    if (userDoc.exists) {
      return userDoc['role'];
    } else {
      throw Exception('User not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Icon
                        Image.asset(
                          'assets/fuztr.png',
                          width: 100,
                        ),
                        const SizedBox(height: 20),
                        // Welcome Back Message
                        const Text(
                          'Welcome to Fuzt!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Please sign in to continue',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Email TextField
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(
                                color: Colors.black.withOpacity(0.5),
                                fontWeight: FontWeight.w400),
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Colors.black,
                            ),
                            filled: true,
                            fillColor: MyColors.secondaryColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        // Password TextField
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(
                                color: Colors.black.withOpacity(0.5),
                                fontWeight: FontWeight.w400),
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Colors.black,
                            ),
                            filled: true,
                            fillColor: MyColors.secondaryColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.black54,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !isPasswordVisible,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 20),
                        // Login Button
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      MyColors.primaryColor, // Text color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 5,
                                  shadowColor: Colors.black.withOpacity(0.3),
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isLoading) // Show loading indicator when isLoading is true
            Center(
              child: LoadingAnimationWidget.dotsTriangle(
                  color: MyColors.primaryColor, size: 50),
            ),
        ],
      ),
    );
  }
}
