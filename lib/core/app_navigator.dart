import 'package:flutter/material.dart';

/// A global navigator key shared between [MaterialApp] (in main.dart)
/// and [NotificationService] so deep-link routing can happen outside
/// of any widget's BuildContext.
///
/// Usage:
///   • Pass to `MaterialApp(navigatorKey: navigatorKey, ...)`
///   • Call `navigatorKey.currentState?.push(...)` from notification handlers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
