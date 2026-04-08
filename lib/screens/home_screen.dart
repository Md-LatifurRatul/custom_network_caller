import 'package:adapti_flow/adapti_flow.dart';
import 'package:flutter/material.dart';
import 'package:network_call/screens/api_operations_tab.dart';
import 'package:network_call/screens/error_tests_tab.dart';
import 'package:network_call/screens/token_management_tab.dart';
import 'package:network_call/services/network/dio_network_caller.dart';
import 'package:network_call/services/network/http_network_caller.dart';
import 'package:network_call/services/network/network_interface.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Callers
  final HttpNetworkCaller _httpCaller = HttpNetworkCaller();
  final DioNetworkCaller _dioCaller = DioNetworkCaller();

  // Current selection
  bool _useDio = false;
  NetworkInterface get _caller => _useDio ? _dioCaller : _httpCaller;
  String get _callerLabel => _useDio ? 'Dio' : 'HTTP';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          tabs: const [
            Tab(icon: Icon(Icons.api), text: 'API Ops'),
            Tab(icon: Icon(Icons.error_outline), text: 'Error Tests'),
            Tab(icon: Icon(Icons.key), text: 'Token Mgmt'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ApiOperationsTab(caller: _caller, callerLabel: _callerLabel),
          ErrorTestsTab(caller: _caller, callerLabel: _callerLabel),
          const TokenManagementTab(),
        ],
      ),
    );
  }
}
