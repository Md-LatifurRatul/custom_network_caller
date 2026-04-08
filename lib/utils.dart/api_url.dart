class ApiUrl {
  ApiUrl._();

  // Posts
  static const String posts = '/posts';
  static String postById(int id) => '/posts/$id';
  static String postsByUser(int userId) => '/posts?userId=$userId';

  // Users
  static const String users = '/users';
  static String userById(int id) => '/users/$id';

  // Comments
  static const String comments = '/comments';
  static String commentsByPost(int postId) => '/posts/$postId/comments';

  // Invalid endpoint (for error testing)
  static const String invalid = '/this-does-not-exist';
}
