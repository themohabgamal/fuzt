import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qrcode/pages/admin/used_qr_code_receipt_screen.dart';
import 'package:qrcode/pages/login_screen.dart';
import 'package:qrcode/theme/my_colors.dart';
import 'generated_qr_codes_screen.dart';
import 'shared_qr_codes_screen.dart';
import 'used_qr_codes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    const GeneratedQRCodesScreen(),
    const SharedQRCodesScreen(),
    const UsedQRCodesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String displayName = user?.displayName ?? 'User';
    String initial = displayName.isNotEmpty ? displayName[0] : 'U';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Admin Panel',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: _screens.elementAt(_selectedIndex),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: MyColors.primaryColor),
              accountName: Text(displayName),
              accountEmail: Text(
                user?.email ?? 'No email',
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Text(
                  initial,
                  style: const TextStyle(fontSize: 40.0, color: Colors.white),
                ),
              ),
            ),
            ListTile(
              title: const Text('History'),
              leading: const Icon(Icons.history),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UsedQRCodesReceiptScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Log Out'),
              leading: const Icon(Icons.logout),
              onTap: _logout,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MyColors.primaryColor,
        onPressed: () {
          Navigator.pushNamed(context, '/admin');
        },
        child: const Icon(Icons.qr_code, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        height: 80, // Increased height
        decoration: const BoxDecoration(
          color: MyColors.primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), // Rounded top-left corner
            topRight: Radius.circular(24), // Rounded top-right corner
          ),
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor:
              Colors.transparent, // Transparent to show container color
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(
                Icons.add_to_home_screen,
                size: 30,
              ),
              label: 'Generated',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.share,
                size: 30,
              ),
              label: 'Shared',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.done_all,
                size: 30,
              ),
              label: 'Used',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70, // Color for unselected items
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
