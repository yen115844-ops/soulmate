import 'package:equatable/equatable.dart';

enum ChangePasswordStatus { initial, loading, success, error }

class ChangePasswordState extends Equatable {
  final ChangePasswordStatus status;
  final String? errorMessage;

  const ChangePasswordState({
    this.status = ChangePasswordStatus.initial,
    this.errorMessage,
  });

  ChangePasswordState copyWith({
    ChangePasswordStatus? status,
    String? errorMessage,
  }) {
    return ChangePasswordState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
