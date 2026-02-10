/// Custom API Exceptions for handling network errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}

/// Network connection exception
class NetworkException extends ApiException {
  NetworkException({String? message})
      : super(
          message: message ?? 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
          statusCode: null,
        );
}

/// Server error exception (5xx)
class ServerException extends ApiException {
  ServerException({String? message, int? statusCode})
      : super(
          message: message ?? 'Lỗi máy chủ. Vui lòng thử lại sau.',
          statusCode: statusCode ?? 500,
        );
}

/// Unauthorized exception (401)
class UnauthorizedException extends ApiException {
  UnauthorizedException({String? message})
      : super(
          message: message ?? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          statusCode: 401,
        );
}

/// Forbidden exception (403)
class ForbiddenException extends ApiException {
  ForbiddenException({String? message})
      : super(
          message: message ?? 'Bạn không có quyền truy cập.',
          statusCode: 403,
        );
}

/// Not found exception (404)
class NotFoundException extends ApiException {
  NotFoundException({String? message})
      : super(
          message: message ?? 'Không tìm thấy dữ liệu.',
          statusCode: 404,
        );
}

/// Bad request exception (400)
class BadRequestException extends ApiException {
  BadRequestException({String? message, dynamic errors})
      : super(
          message: message ?? 'Dữ liệu không hợp lệ.',
          statusCode: 400,
          errors: errors,
        );
}

/// Conflict exception (409)
class ConflictException extends ApiException {
  ConflictException({String? message})
      : super(
          message: message ?? 'Dữ liệu đã tồn tại.',
          statusCode: 409,
        );
}

/// Timeout exception
class TimeoutException extends ApiException {
  TimeoutException({String? message})
      : super(
          message: message ?? 'Kết nối quá thời gian. Vui lòng thử lại.',
          statusCode: null,
        );
}

/// Request cancelled exception
class CancelledException extends ApiException {
  CancelledException({String? message})
      : super(
          message: message ?? 'Yêu cầu đã bị hủy.',
          statusCode: null,
        );
}
