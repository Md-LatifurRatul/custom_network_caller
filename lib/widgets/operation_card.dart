import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:network_caller_http/network_caller_http.dart';

class OperationCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String method;
  final String callerLabel;
  final bool isError;
  final Future<NetworkResponse> Function() onExecute;

  const OperationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.method,
    required this.callerLabel,
    this.isError = false,
    required this.onExecute,
  });

  @override
  State<OperationCard> createState() => _OperationCardState();
}

enum _CardStatus { idle, loading, success, error }

class _OperationCardState extends State<OperationCard> {
  _CardStatus _status = _CardStatus.idle;
  NetworkResponse? _result;

  Future<void> _execute() async {
    setState(() => _status = _CardStatus.loading);
    try {
      final result = await widget.onExecute();
      if (!mounted) return;
      setState(() {
        _result = result;
        _status = result.isSuccess ? _CardStatus.success : _CardStatus.error;
      });
      if (mounted) _showResultSheet(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = NetworkResponse(isSuccess: false, message: e.toString());
        _status = _CardStatus.error;
      });
      if (mounted) _showResultSheet(context);
    }
  }

  Color _methodColor(String method) {
    return switch (method) {
      'GET' => const Color(0xFF4CAF50),
      'POST' => const Color(0xFF2196F3),
      'PUT' => const Color(0xFFFF9800),
      'PATCH' => const Color(0xFFFFC107),
      'DELETE' => const Color(0xFFF44336),
      _ => Colors.grey,
    };
  }

  IconData _statusIcon() {
    return switch (_status) {
      _CardStatus.idle => Icons.play_arrow_rounded,
      _CardStatus.loading => Icons.hourglass_top_rounded,
      _CardStatus.success => Icons.check_circle_rounded,
      _CardStatus.error => Icons.error_rounded,
    };
  }

  Color _statusColor() {
    return switch (_status) {
      _CardStatus.idle => Colors.grey,
      _CardStatus.loading => Colors.blue,
      _CardStatus.success => const Color(0xFF4CAF50),
      _CardStatus.error => const Color(0xFFF44336),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mColor = _methodColor(widget.method);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _status == _CardStatus.loading ? null : _execute,
        onLongPress: _result != null ? () => _showResultSheet(context) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Method badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: mColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.method,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: mColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
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

              // Status indicator
              const SizedBox(width: 8),
              if (_status == _CardStatus.loading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                )
              else
                Icon(_statusIcon(), color: _statusColor(), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Result bottom sheet
  // ---------------------------------------------------------------------------

  void _showResultSheet(BuildContext context) {
    final result = _result;
    if (result == null) return;

    final cs = Theme.of(context).colorScheme;
    final isSuccess = result.isSuccess;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: isSuccess
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFF44336),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              '${widget.method} \u2022 Status ${result.statusCode ?? 'N/A'} \u2022 ${widget.callerLabel}',
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Message
                  if (result.message != null) ...[
                    ResultSection(title: 'Message', content: result.message!),
                    const SizedBox(height: 16),
                  ],

                  // Data
                  ResultSection(
                    title: isSuccess ? 'Response Data' : 'Error Details',
                    content: _formatData(
                        isSuccess ? result.data : result.error?.details),
                  ),
                  const SizedBox(height: 16),

                  // Error info
                  if (result.error != null)
                    ResultSection(
                      title: 'Error Object',
                      content: result.error.toString(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatData(dynamic data) {
    if (data == null) return '(empty / null)';
    if (data is List) {
      if (data.isEmpty) return '[]';
      final preview = data.take(3).map((e) => e.toString()).join('\n');
      return '$preview\n... (${data.length} items total)';
    }
    if (data is Map) {
      try {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(data);
      } catch (_) {
        return data.toString();
      }
    }
    return data.toString();
  }
}

// ---------------------------------------------------------------------------
// Result section — used inside the result bottom sheet
// ---------------------------------------------------------------------------

class ResultSection extends StatelessWidget {
  final String title;
  final String content;

  const ResultSection({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            content,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: cs.onSurface,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
