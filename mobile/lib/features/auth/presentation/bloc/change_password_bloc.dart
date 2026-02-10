import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_password_repository.dart';
import 'change_password_event.dart';
import 'change_password_state.dart';

class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final AuthPasswordRepository _repository;

  ChangePasswordBloc(this._repository) : super(const ChangePasswordState()) {
    on<ChangePasswordSubmitted>(_onSubmitted);
    on<ChangePasswordReset>(_onReset);
  }

  Future<void> _onSubmitted(
    ChangePasswordSubmitted event,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(state.copyWith(status: ChangePasswordStatus.loading));

    try {
      await _repository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(state.copyWith(status: ChangePasswordStatus.success));
    } catch (e) {
      String errorMessage = 'Đổi mật khẩu thất bại. Vui lòng thử lại.';
      
      if (e.toString().contains('incorrect') || e.toString().contains('wrong')) {
        errorMessage = 'Mật khẩu hiện tại không đúng.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Lỗi kết nối. Vui lòng kiểm tra mạng.';
      }

      emit(state.copyWith(
        status: ChangePasswordStatus.error,
        errorMessage: errorMessage,
      ));
    }
  }

  void _onReset(
    ChangePasswordReset event,
    Emitter<ChangePasswordState> emit,
  ) {
    emit(const ChangePasswordState());
  }
}
