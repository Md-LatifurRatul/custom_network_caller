import 'package:adapti_flow/adapti_flow.dart';
import 'package:flutter/material.dart';
import 'package:network_call/model/post.dart';
import 'package:network_call/model/user.dart';
import 'package:network_call/utils.dart/api_url.dart';
import 'package:network_call/widgets/operation_card.dart';
import 'package:network_caller_http/network_caller_http.dart';

class ApiOperationsTab extends StatelessWidget {
  final NetworkInterface caller;
  final String callerLabel;

  const ApiOperationsTab({
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
            title: 'GET Posts',
            subtitle: 'Fetch list of posts (parsed)',
            method: 'GET',
            callerLabel: callerLabel,
            onExecute: () => caller.get<List<Post>>(
              url: ApiUrl.posts,
              parser: (json) =>
                  (json as List).map((e) => Post.fromJson(e)).toList(),
            ),
          ),
          OperationCard(
            title: 'GET Single Post',
            subtitle: 'Fetch post #1 as model',
            method: 'GET',
            callerLabel: callerLabel,
            onExecute: () => caller.get<Post>(
              url: ApiUrl.postById(1),
              parser: (json) => Post.fromJson(json),
            ),
          ),
          OperationCard(
            title: 'GET Users',
            subtitle: 'Fetch all users (different model)',
            method: 'GET',
            callerLabel: callerLabel,
            onExecute: () => caller.get<List<User>>(
              url: ApiUrl.users,
              parser: (json) =>
                  (json as List).map((e) => User.fromJson(e)).toList(),
            ),
          ),
          OperationCard(
            title: 'GET Raw (no parser)',
            subtitle: 'Fetch post #2 as raw Map',
            method: 'GET',
            callerLabel: callerLabel,
            onExecute: () => caller.get(url: ApiUrl.postById(2)),
          ),
          OperationCard(
            title: 'POST Create',
            subtitle: 'Create a new post',
            method: 'POST',
            callerLabel: callerLabel,
            onExecute: () => caller.post<Post>(
              url: ApiUrl.posts,
              body: const Post(userId: 1, title: 'New Post', body: 'Hello!')
                  .toJson(),
              parser: (json) => Post.fromJson(json),
            ),
          ),
          OperationCard(
            title: 'PUT Update',
            subtitle: 'Full update post #1',
            method: 'PUT',
            callerLabel: callerLabel,
            onExecute: () => caller.put<Post>(
              url: ApiUrl.postById(1),
              body: const Post(
                userId: 1,
                title: 'Updated Title',
                body: 'Updated body content',
              ).toJson(),
              parser: (json) => Post.fromJson(json),
            ),
          ),
          OperationCard(
            title: 'PATCH Update',
            subtitle: 'Partial update post #1 title',
            method: 'PATCH',
            callerLabel: callerLabel,
            onExecute: () => caller.patch<Post>(
              url: ApiUrl.postById(1),
              body: {'title': 'Patched Title Only'},
              parser: (json) => Post.fromJson(json),
            ),
          ),
          OperationCard(
            title: 'DELETE Post',
            subtitle: 'Delete post #1',
            method: 'DELETE',
            callerLabel: callerLabel,
            onExecute: () => caller.delete(url: ApiUrl.postById(1)),
          ),
        ],
      ),
    );
  }
}
