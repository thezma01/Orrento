import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orrento/screens/home.dart';
import 'package:orrento/screens/nearbyitems.dart';
import 'package:orrento/screens/chat.dart';
import 'package:orrento/screens/profile.dart';
import 'package:orrento/screens/listitem.dart';
import 'package:orrento/screens/widgets/bottom_nav.dart';
import 'screens/landingpage.dart';
import 'screens/user_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orrento',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3F6FD),
        primaryColor: const Color.fromARGB(255, 14, 44, 85),
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: const ColorScheme.light(
          primary: Color.fromARGB(255, 14, 44, 85),
          secondary: Color(0xFF00E676),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LandingScreen(),
      },
     );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late String userName;
  late DateTime memberSince;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

Future<void> _checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  await Future.delayed(const Duration(seconds: 2));

  if (isLoggedIn) {
    // Get user details from local storage
    final userName = prefs.getString('userName') ?? 'User';
    final createdAtStr = prefs.getString('memberSince');
    final userId = prefs.getInt('userId') ?? 0;

    DateTime memberSince;
    try {
      memberSince = DateTime.parse(createdAtStr ?? '');
    } catch (_) {
      memberSince = DateTime.now();
    }

    // ✅ Navigate with userId
 Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (_) => MainScreen(
      userName: userName,
      memberSince: memberSince,
      userId: userId,
    ),
  ),
  (Route<dynamic> route) => false,
);

  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1D3A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'Orrento',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Rent Anything, Anytime.',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String userName;
  final DateTime memberSince;
 final dynamic userId; // ✅ Define the field here
  const MainScreen({
    super.key,
    required this.userName,
    required this.memberSince,
     required this.userId, // ✅ Add thi
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
       NearbyScreen(),
      const ChatScreen(),
      const ListItemScreen(),
      ProfileScreen(
        userName: widget.userName,
        memberSince: widget.memberSince,
      ),
      DashboardScreen(userId: widget.userId),

    ];
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
