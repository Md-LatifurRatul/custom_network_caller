/// Controls how the HTTP response body is decoded.
///
/// - [json] — Decodes the body as JSON (default). Returns `Map` or `List`.
/// - [plain] — Returns the body as a raw `String`. Use for non-JSON text responses.
/// - [bytes] — Returns the body as `List<int>` raw bytes. Use for binary data.
enum ResponseType { json, plain, bytes }
