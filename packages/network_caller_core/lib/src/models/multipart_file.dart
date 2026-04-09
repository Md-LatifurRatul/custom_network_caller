import 'dart:typed_data';

/// Platform-agnostic file representation for multipart uploads.
///
/// This decouples the core interface from `http.MultipartFile` and
/// `dio.MultipartFile` — each implementation converts this to its own type.
///
/// Uses raw bytes only (no `dart:io`) so it works on **all platforms**
/// including Web, iOS, Android, macOS, Windows, and Linux.
///
/// ```dart
/// final file = NetworkMultipartFile(
///   field: 'avatar',
///   bytes: imageBytes,
///   filename: 'photo.jpg',
///   contentType: 'image/jpeg',
/// );
/// ```
class NetworkMultipartFile {
  /// The form field name (e.g., `'file'`, `'avatar'`, `'document'`).
  final String field;

  /// Raw file bytes.
  final Uint8List bytes;

  /// The filename sent to the server.
  final String filename;

  /// MIME type (e.g., `'image/jpeg'`, `'application/pdf'`).
  /// If null, the server will try to detect it.
  final String? contentType;

  /// Creates a multipart file from raw bytes.
  ///
  /// For file-path based creation, use the platform-specific helpers
  /// in `network_caller_http` or `network_caller_dio` packages.
  const NetworkMultipartFile({
    required this.field,
    required this.bytes,
    required this.filename,
    this.contentType,
  });

  /// File size in bytes.
  int get size => bytes.length;

  @override
  String toString() =>
      'NetworkMultipartFile(field: $field, filename: $filename, '
      'size: $size bytes, contentType: $contentType)';
}
