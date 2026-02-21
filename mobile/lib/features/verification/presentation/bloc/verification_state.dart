import 'package:equatable/equatable.dart';

import '../../domain/entities/verification_entity.dart';

enum VerificationStateStatus {
  initial,
  loading,
  submitting,
  success,   // Fetched status successfully
  submitted, // Submitted selfie successfully
  error,
}

class VerificationState extends Equatable {
  final VerificationStateStatus status;
  final VerificationEntity? verification;
  final String? error;

  const VerificationState({
    this.status = VerificationStateStatus.initial,
    this.verification,
    this.error,
  });

  bool get isLoading =>
      status == VerificationStateStatus.loading ||
      status == VerificationStateStatus.submitting;

  bool get isVerified => verification?.isVerified ?? false;

  VerificationState copyWith({
    VerificationStateStatus? status,
    VerificationEntity? verification,
    String? error,
  }) {
    return VerificationState(
      status: status ?? this.status,
      verification: verification ?? this.verification,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, verification, error];
}
