import 'dart:io';
import 'dart:typed_data';

/// Platform-agnostic file representation for multipart uploads.
///
/// This decouples the core interface from `http.MultipartFile` and
/// `dio.MultipartFile` — each implementation converts this to its own type.
///
/// ```dart
/// final file = NetworkMultipartFile(
///   field: 'avatar',
///   bytes: await File('photo.jpg').readAsBytes(),
///   filename: 'photo.jpg',
///   contentType: 'image/jpeg',
/// );
/// ```
class NetworkMultipartFile {
  /// The form field name (e.g., 'file', 'avatar', 'document').
  final String field;

  /// Raw file bytes.
  final Uint8List bytes;

  /// The filename sent to the server.
  final String filename;

  /// MIME type (e.g., 'image/jpeg', 'application/pdf').
  final String? contentType;

  const NetworkMultipartFile({
    required this.field,
    required this.bytes,
    required this.filename,
    this.contentType,
  });

  /// Creates a [NetworkMultipartFile] by reading bytes from a file path.
  static Future<NetworkMultipartFile> fromPath(
    String field,
    String path, {
    String? filename,
    String? contentType,
  }) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    return NetworkMultipartFile(
      field: field,
      bytes: bytes,
      filename: filename ?? file.uri.pathSegments.last,
      contentType: contentType,
    );
  }

  /// File size in bytes.
  int get size => bytes.length;

  @override
  String toString() =>
      'NetworkMultipartFile(field: $field, filename: $filename, size: $size bytes)';
}
