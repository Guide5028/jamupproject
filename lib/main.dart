import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_fonts.dart';
import 'core/constants/app_constants.dart';

// Pages
import 'features/home/pages/home_page.dart';
import 'features/gigs/pages/gig_page.dart';
import 'features/profile/pages/profile_page.dart';
import 'features/musicians/pages/musicians_page.dart';
import 'features/messages/pages/messages_page.dart';
import 'features/auth/pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase
  await Supabase.initialize(
    url: 'https://yaxfmxenmotfjvzdyphz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlheGZteGVubW90Zmp2emR5cGh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc3NzUzMjMsImV4cCI6MjA3MzM1MTMyM30.C2NEuCHEx36DcT3L49p3KDTn0NMVfAa1jUKJVc49cro',
  );

  runApp(const JamUpApp());
}

class JamUpApp extends StatelessWidget {
  const JamUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryGold,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: AppFonts.textTheme,
        useMaterial3: true,
      ),
      //check if user logged in
      home: Supabase.instance.client.auth.currentUser == null
          ? const LoginPage()
          : const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    GigPage(),
    MusiciansPage(),
    MessagesPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGold,
        unselectedItemColor: AppColors.accentBrown,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined), label: "Gigs"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline), label: "Musicians"),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: "Messages"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}
