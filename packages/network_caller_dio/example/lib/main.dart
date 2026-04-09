import 'package:flutter/material.dart';
import 'package:network_caller_dio/network_caller_dio.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('network_caller_dio Example')),
        body: const Center(child: DioExample()),
      ),
    );
  }
}

class DioExample extends StatefulWidget {
  const DioExample({super.key});

  @override
  State<DioExample> createState() => _DioExampleState();
}

class _DioExampleState extends State<DioExample> {
  // Create caller once — with custom interceptor
  final _caller = DioNetworkCaller(
    config: const NetworkConfig(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      retryPolicy: RetryPolicy.standard(),
      logger: ConsoleNetworkLogger(),
    ),
    tokenStorage: SecureTokenStorage(),
  );

  String _result = 'Tap the button to fetch data';

  Future<void> _fetchPosts() async {
    setState(() => _result = 'Loading...');

    final res = await _caller.get<List<dynamic>>(
      url: '/posts',
      queryParameters: {'userId': '1'},
      parser: (json) => json as List,
    );

    if (!mounted) return;
    setState(() {
      if (res.isSuccess) {
        _result =
            'Fetched ${res.data!.length} posts\n'
            'Status: ${res.statusCode}\n'
            'First title: ${res.data!.first['title']}';
      } else {
        _result = 'Error: ${res.exception}';
      }
    });
  }

  @override
  void dispose() {
    _caller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_result, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchPosts,
            child: const Text('Fetch Posts'),
          ),
        ],
      ),
    );
  }
}
