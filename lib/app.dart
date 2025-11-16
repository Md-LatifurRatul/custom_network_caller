import 'package:flutter/material.dart';
import 'package:network_call/pages/auth/login_page.dart';

class NetworkApp extends StatelessWidget {
  const NetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Network Test",
      home: LoginPage(),
    );
  }
}
