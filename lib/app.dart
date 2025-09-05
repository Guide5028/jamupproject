import 'package:flutter/material.dart';
import 'pages/home/home_page.dart';
import 'utils/colors.dart';
import 'utils/fonts.dart';

class JamUpApp extends StatelessWidget {
  const JamUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JamUP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryGold,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.darkBrown,
          elevation: 0,
          titleTextStyle: AppFonts.appBarTitle,
        ),
        textTheme: AppFonts.textTheme,
      ),
      home: const HomePage(),
    );
  }
}
