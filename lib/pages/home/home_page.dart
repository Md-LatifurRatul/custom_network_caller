import 'package:flutter/material.dart';
import 'package:network_call/state_management/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          children: [
            Text('Welcome: ${authProvider.user?['username'] ?? 'Guest'}'),
            ElevatedButton(
              onPressed: () async => await authProvider.loadProfile(),
              child: Text('Load Profile (Protected)'),
            ),
          ],
        ),
      ),
    );
  }
}
