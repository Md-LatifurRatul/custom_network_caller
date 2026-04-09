import 'package:adapti_flow/adapti_flow.dart';
import 'package:flutter/material.dart';
import 'package:network_call/utils.dart/api_url.dart';
import 'package:network_call/widgets/operation_card.dart';
import 'package:network_caller_http/network_caller_http.dart';

class AdvancedFeaturesTab extends StatelessWidget {
  final NetworkInterface caller;
  final String callerLabel;

  const AdvancedFeaturesTab({
    super.key,
    required this.caller,
    required this.callerLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeResponsiveLayout(
      padding: EdgeInsets.all(context.adaptivePadding),
      child: ResponsiveGrid(
        mobileColumns: 1,
        tabletColumns: 2,
        desktopColumns: 3,
        spacing: context.adaptiveSpacing,
        runSpacing: context.adaptiveSpacing,
        childAspectRatio: context.isMobile ? 2.8 : 2.4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // --- Query Parameters ---
          OperationCard(
            title: 'Query Parameters',
            subtitle: 'GET /posts?userId=1',
            method: 'GET',
            callerLabel: callerLabel,
            onExecute: () => caller.get(
              url: ApiUrl.posts,
              queryParameters: {'userId': '1'},
            ),
          ),

          // --- Per-Request Timeout ---
          OperationCard(
            title: 'Custom Timeout (1ms)',
            subtitle: 'Triggers timeout intentionally',
            method: 'GET',
            callerLabel: callerLabel,
            isError: true,
            onExecute: () => caller.get(
              url: ApiUrl.posts,
              timeout: const Duration(milliseconds: 1),
            ),
          ),

          // --- ResponseType.plain ---
          OperationCard(
            title: 'ResponseType.plain',
            subtitle: 'Get raw string response',
            method: 'GET',
            callerLabel: callerLabel,
            onExecute: () => caller.get<String>(
              url: ApiUrl.postById(1),
              responseType: ResponseType.plain,
            ),
          ),

          // --- ResponseType.bytes ---
          OperationCard(
            title: 'ResponseType.bytes',
            subtitle: 'Get raw bytes response',
            method: 'GET',
            callerLabel: callerLabel,
            onExecute: () => caller.get(
              url: ApiUrl.postById(1),
              responseType: ResponseType.bytes,
            ),
          ),

          // --- Request Cancellation ---
          _CancellationCard(caller: caller, callerLabel: callerLabel),

          // --- DELETE with Body ---
          OperationCard(
            title: 'DELETE with Body',
            subtitle: 'Delete with request body',
            method: 'DELETE',
            callerLabel: callerLabel,
            onExecute: () => caller.delete(
              url: ApiUrl.postById(1),
              body: {'reason': 'test deletion'},
            ),
          ),
        ],
      ),
    );
  }
}

/// Special card that demonstrates request cancellation.
class _CancellationCard extends StatefulWidget {
  final NetworkInterface caller;
  final String callerLabel;

  const _CancellationCard({
    required this.caller,
    required this.callerLabel,
  });

  @override
  State<_CancellationCard> createState() => _CancellationCardState();
}

class _CancellationCardState extends State<_CancellationCard> {
  bool _loading = false;
  String _status = 'Tap to test cancel';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _loading ? null : _execute,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'GET',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cancel Request',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_loading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                )
              else
                Icon(
                  _status.contains('Cancelled')
                      ? Icons.cancel_rounded
                      : Icons.play_arrow_rounded,
                  color: _status.contains('Cancelled')
                      ? Colors.orange
                      : Colors.grey,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _execute() async {
    setState(() {
      _loading = true;
      _status = 'Requesting... will cancel in 50ms';
    });

    final cancelToken = HttpCancelToken();

    // Cancel after 50ms
    Future.delayed(const Duration(milliseconds: 50), () {
      cancelToken.cancel('User cancelled');
    });

    final res = await widget.caller.get(
      url: ApiUrl.posts,
      cancelToken: cancelToken,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.exception is RequestCancelledException) {
        _status = 'Cancelled! ${res.exception?.message}';
      } else if (res.isSuccess) {
        _status = 'Completed before cancel (too fast)';
      } else {
        _status = 'Error: ${res.message}';
      }
    });
  }
}
