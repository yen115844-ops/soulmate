import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exceptions.dart';
import 'package:mobile/core/utils/error_utils.dart';

void main() {
  group('getErrorMessage', () {
    test('returns message for ApiException', () {
      final e = ApiException(message: 'Lỗi tùy chỉnh');
      expect(getErrorMessage(e), 'Lỗi tùy chỉnh');
    });

    test('returns message for NetworkException', () {
      final e = NetworkException();
      expect(getErrorMessage(e), isNotEmpty);
      expect(getErrorMessage(e), contains('mạng'));
    });

    test('returns Vietnamese message for SocketException-like string', () {
      expect(
        getErrorMessage(Exception('SocketException: Failed host lookup')),
        contains('kết nối mạng'),
      );
    });

    test('returns Vietnamese message for TimeoutException-like string', () {
      expect(
        getErrorMessage(Exception('TimeoutException after 0:00:30')),
        contains('quá chậm'),
      );
    });

    test('returns Vietnamese message for FormatException-like string', () {
      expect(
        getErrorMessage(Exception('FormatException: Invalid JSON')),
        contains('không hợp lệ'),
      );
    });

    test('returns generic message for unknown error', () {
      expect(
        getErrorMessage(Exception('Some unknown error')),
        'Đã có lỗi xảy ra. Vui lòng thử lại.',
      );
    });
  });
}
