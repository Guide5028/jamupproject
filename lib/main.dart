import 'package:flutter/material.dart';
import 'package:jamup_app/config/app_theme.dart';
import 'package:jamup_app/core/services/notification_service.dart';
import 'package:jamup_app/features/auth/widgets/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import 'core/app_navigator.dart';
import 'core/constants/app_constants.dart';

// Pages
import 'features/home/pages/home_page.dart';
import 'features/gigs/pages/gig_page.dart';
import 'features/profile/pages/profile_page.dart';
import 'features/musicians/pages/musicians_page.dart';
import 'features/messages/pages/messages_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // LOAD .env
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Initialize OneSignal. Wrapped in try/catch so that if push setup ever
  // fails, the app STILL reaches runApp() and shows a screen, instead of
  // dying on the native splash. Optional services should degrade, not crash.
  try {
    await NotificationService.initialize();
  } catch (e, st) {
    debugPrint('Notification init failed (continuing anyway): $e\n$st');
  }

  runApp(const JamUpApp());
}

class JamUpApp extends StatelessWidget {
  const JamUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      home: const AuthGate(),
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
