/// HTTP request methods supported by the network caller.
enum RequestMethod {
  get,
  post,
  put,
  patch,
  delete;

  /// Returns the uppercase HTTP method string (e.g., 'GET', 'POST').
  String get value => name.toUpperCase();
}
