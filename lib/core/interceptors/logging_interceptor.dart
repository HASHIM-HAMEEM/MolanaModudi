import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

/// A Dio interceptor for logging requests, responses, and errors.
class LoggingInterceptor extends Interceptor {
  final _log = Logger('Dio');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.fine('REQUEST[${options.method}] => PATH: ${options.path} => PARAMS: ${options.queryParameters}');
    // You can add header logging here if needed:
    // _log.finer('HEADERS: ${options.headers}');
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log.fine(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    // Log response data only in finer levels if needed, as it can be large
    // _log.finer('DATA: ${response.data}'); 
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.severe(
      'ERROR[${err.response?.statusCode ?? ''}] => PATH: ${err.requestOptions.path}',
      err,
      StackTrace.current, // Include stack trace
    );
     _log.severe('Error Message: ${err.message}');
    if (err.response != null) {
       _log.severe('Error Response Data: ${err.response?.data}');
    }
    return super.onError(err, handler);
  }
} 