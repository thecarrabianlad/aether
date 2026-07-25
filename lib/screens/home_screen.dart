import 'package:flutter/material.dart';
import 'package:aether/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/foundation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('HomeScreen: build method called');
    return const DashboardScreen();
  }
}
