import 'package:adapti_flow/adapti_flow.dart';
import 'package:flutter/material.dart';
import 'package:network_call/widgets/token_row.dart';
import 'package:network_caller_http/network_caller_http.dart';

class TokenManagementTab extends StatefulWidget {
  final TokenManager tokenManager;

  const TokenManagementTab({super.key, required this.tokenManager});

  @override
  State<TokenManagementTab> createState() => _TokenManagementTabState();
}

class _TokenManagementTabState extends State<TokenManagementTab> {
  String _accessToken = '';
  String _refreshToken = '';
  String _status = 'No action performed yet';
  Color _statusColor = Colors.grey;

  Future<void> _saveTokens() async {
    await widget.tokenManager.saveTokens(
      accessToken: 'demo_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken:
          'demo_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
    );
    await _readTokens();
    setState(() {
      _status = 'Tokens saved successfully';
      _statusColor = Colors.green;
    });
  }

  Future<void> _readTokens() async {
    final access = await widget.tokenManager.getAccessToken();
    final refresh = await widget.tokenManager.getRefreshToken();
    setState(() {
      _accessToken = access ?? '(null)';
      _refreshToken = refresh ?? '(null)';
      _status = 'Tokens read successfully';
      _statusColor = Colors.blue;
    });
  }

  Future<void> _clearTokens() async {
    await widget.tokenManager.clearTokens();
    setState(() {
      _accessToken = '(null)';
      _refreshToken = '(null)';
      _status = 'Tokens cleared successfully';
      _statusColor = Colors.orange;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeResponsiveLayout(
      padding: EdgeInsets.all(context.adaptivePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _statusColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: context.fontSize(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Spacers.s24,

          // Token display card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stored Tokens',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: context.fontSize(16),
                      color: cs.onSurface,
                    ),
                  ),
                  Spacers.s16,
                  TokenRow(label: 'Access Token', value: _accessToken),
                  const Divider(height: 24),
                  TokenRow(label: 'Refresh Token', value: _refreshToken),
                ],
              ),
            ),
          ),
          Spacers.s24,

          // Action buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _saveTokens,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save Tokens'),
              ),
              FilledButton.tonalIcon(
                onPressed: _readTokens,
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Read Tokens'),
              ),
              OutlinedButton.icon(
                onPressed: _clearTokens,
                icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                label: Text('Clear Tokens', style: TextStyle(color: cs.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
