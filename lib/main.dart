import 'package:flutter/material.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard.dart';   // <-- required

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Electronics ERP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),

      // START SCREEN → Register
      home: const RegisterScreen(),

      // NAMED ROUTES
      routes: {
        "/register": (context) => const RegisterScreen(),
        "/dashboard": (context) => const DashboardScreen(),
      },
    );
  }
}
