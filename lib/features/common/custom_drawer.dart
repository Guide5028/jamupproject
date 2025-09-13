// import 'package:flutter/material.dart';
// import '../../config/app_theme.dart';

// class CustomDrawer extends StatelessWidget {
//   const CustomDrawer({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           const DrawerHeader(
//             decoration: BoxDecoration(
//               color: AppTheme.primaryColor,
//             ),
//             child: Align(
//               alignment: Alignment.bottomLeft,
//               child: Text(
//                 "JamUP Menu",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.home, color: AppTheme.primaryColor),
//             title: const Text("Home"),
//             onTap: () => Navigator.pop(context),
//           ),
//           ListTile(
//             leading: const Icon(Icons.search, color: AppTheme.primaryColor),
//             title: const Text("Search"),
//             onTap: () => Navigator.pushNamed(context, "/search"),
//           ),
//           ListTile(
//             leading: const Icon(Icons.settings, color: AppTheme.primaryColor),
//             title: const Text("Settings"),
//             onTap: () => Navigator.pushNamed(context, "/settings"),
//           ),
//         ],
//       ),
//     );
//   }
// }
