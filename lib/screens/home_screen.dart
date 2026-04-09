import 'package:adapti_flow/adapti_flow.dart';
import 'package:flutter/material.dart';
import 'package:network_call/screens/advanced_features_tab.dart';
import 'package:network_call/screens/api_operations_tab.dart';
import 'package:network_call/screens/error_tests_tab.dart';
import 'package:network_call/screens/token_management_tab.dart';
import 'package:network_caller_dio/network_caller_dio.dart' hide SecureTokenStorage;
import 'package:network_caller_http/network_caller_http.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Shared token storage — both callers see the same tokens
  final SecureTokenStorage _tokenStorage = SecureTokenStorage();

  // Shared config
  static const _config = NetworkConfig(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    logger: ConsoleNetworkLogger(),
  );

  // Callers — using the NEW package APIs
  late final HttpNetworkCaller _httpCaller = HttpNetworkCaller(
    config: _config,
    tokenStorage: _tokenStorage,
  );
  late final DioNetworkCaller _dioCaller = DioNetworkCaller(
    config: _config,
    tokenStorage: _tokenStorage,
  );

  // Current selection
  bool _useDio = false;
  NetworkInterface get _caller => _useDio ? _dioCaller : _httpCaller;
  String get _callerLabel => _useDio ? 'Dio' : 'HTTP';

  // TokenManager from whichever caller is active (both share same storage)
  TokenManager get _tokenManager =>
      _useDio ? _dioCaller.tokenManager : _httpCaller.tokenManager;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _httpCaller.dispose();
    _dioCaller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: ResponsiveText(
          'Network Caller Demo',
          baseFontSize: 20,
          style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('HTTP')),
                ButtonSegment(value: true, label: Text('Dio')),
              ],
              selected: {_useDio},
              onSelectionChanged: (v) => setState(() => _useDio = v.first),
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.api), text: 'API Ops'),
            Tab(icon: Icon(Icons.error_outline), text: 'Errors'),
            Tab(icon: Icon(Icons.key), text: 'Tokens'),
            Tab(icon: Icon(Icons.tune), text: 'Advanced'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ApiOperationsTab(caller: _caller, callerLabel: _callerLabel),
          ErrorTestsTab(caller: _caller, callerLabel: _callerLabel),
          TokenManagementTab(tokenManager: _tokenManager),
          AdvancedFeaturesTab(caller: _caller, callerLabel: _callerLabel),
        ],
      ),
    );
  }
}
