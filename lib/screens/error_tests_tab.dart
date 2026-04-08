import 'package:adapti_flow/adapti_flow.dart';
import 'package:flutter/material.dart';
import 'package:network_call/model/post.dart';
import 'package:network_call/services/network/network_interface.dart';
import 'package:network_call/utils.dart/api_url.dart';
import 'package:network_call/widgets/operation_card.dart';

class ErrorTestsTab extends StatelessWidget {
  final NetworkInterface caller;
  final String callerLabel;

  const ErrorTestsTab({
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
          OperationCard(
            title: '404 Not Found',
            subtitle: 'Request to invalid endpoint',
            method: 'GET',
            callerLabel: callerLabel,
            isError: true,
            onExecute: () => caller.getRequest(url: ApiUrl.invalid),
          ),
          OperationCard(
            title: 'Network Error',
            subtitle: 'Request to unreachable host',
            method: 'GET',
            callerLabel: callerLabel,
            isError: true,
            onExecute: () => caller.getRequest(
              url: 'https://invalid-host-that-does-not-exist.xyz/api',
            ),
          ),
          OperationCard(
            title: 'Parser Error',
            subtitle: 'Parser throws on valid response',
            method: 'GET',
            callerLabel: callerLabel,
            isError: true,
            onExecute: () => caller.getRequest<Post>(
              url: ApiUrl.posts,
              parser: (_) => throw FormatException('Intentional parse error'),
            ),
          ),
          OperationCard(
            title: '401 Unauthorized',
            subtitle: 'GET with withToken (no token saved)',
            method: 'GET',
            callerLabel: callerLabel,
            isError: true,
            onExecute: () =>
                caller.getRequest(url: ApiUrl.posts, withToken: true),
          ),
        ],
      ),
    );
  }
}
