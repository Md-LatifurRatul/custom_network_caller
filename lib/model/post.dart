class Post {
  final int? id;
  final int? userId;
  final String? title;
  final String? body;

  const Post({this.id, this.userId, this.title, this.body});

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as int?,
        userId: json['userId'] as int?,
        title: json['title'] as String?,
        body: json['body'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (userId != null) 'userId': userId,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
      };

  @override
  String toString() => 'Post(id: $id, userId: $userId, title: $title)';
}
