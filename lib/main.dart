import 'package:flutter/material.dart';
import 'package:network_call/app.dart';
import 'package:network_call/state_management/provider/auth_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],

      child: const NetworkApp(),
    ),
  );
}
