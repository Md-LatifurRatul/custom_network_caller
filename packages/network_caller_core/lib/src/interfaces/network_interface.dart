import 'package:network_caller_core/src/config/network_config.dart';
import 'package:network_caller_core/src/enums/response_type.dart';
import 'package:network_caller_core/src/interfaces/cancel_token.dart';
import 'package:network_caller_core/src/models/multipart_file.dart';
import 'package:network_caller_core/src/models/network_response.dart';

/// Abstract contract that both HTTP and Dio callers implement.
///
/// All methods return [NetworkResponse<T>] — never throws. Errors are
/// captured in the response's [error] and [exception] fields.
abstract class NetworkInterface {
  /// The config this caller was initialized with.
  NetworkConfig get config;

  /// GET request.
  Future<NetworkResponse<T>> get<T>({
    required String url,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    Duration? timeout,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  });

  /// POST request.
  Future<NetworkResponse<T>> post<T>({
    required String url,
    dynamic body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    Duration? timeout,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  });

  /// PUT request (full update).
  Future<NetworkResponse<T>> put<T>({
    required String url,
    dynamic body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    Duration? timeout,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  });

  /// PATCH request (partial update).
  Future<NetworkResponse<T>> patch<T>({
    required String url,
    dynamic body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    Duration? timeout,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  });

  /// DELETE request.
  Future<NetworkResponse<T>> delete<T>({
    required String url,
    dynamic body,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    Duration? timeout,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  });

  /// Multipart file upload with optional progress callback.
  Future<NetworkResponse<T>> upload<T>({
    required String url,
    required List<NetworkMultipartFile> files,
    Map<String, String>? fields,
    Map<String, String>? headers,
    bool withToken = false,
    T Function(dynamic json)? parser,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  });

  /// Releases underlying resources (closes HTTP client / Dio instance).
  ///
  /// After calling [dispose], the caller should not be used again.
  void dispose();
}
