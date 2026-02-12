import '../network/api_exceptions.dart';

/// Get user-friendly error message from exception.
/// Use this in BLoCs instead of exposing raw `e.toString()` to users.
///
/// Example:
/// ```dart
/// } catch (e) {
///   emit(SomeError(message: getErrorMessage(e)));
/// }
/// ```
String getErrorMessage(dynamic error) {
  if (error is ApiException) {
    return error.message;
  }
  final errorStr = error.toString();
  if (errorStr.contains('SocketException') || errorStr.contains('Connection')) {
    return 'Không có kết nối mạng. Vui lòng kiểm tra và thử lại.';
  }
  if (errorStr.contains('TimeoutException')) {
    return 'Kết nối quá chậm. Vui lòng thử lại.';
  }
  if (errorStr.contains('FormatException')) {
    return 'Dữ liệu không hợp lệ. Vui lòng thử lại.';
  }
  return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
}
