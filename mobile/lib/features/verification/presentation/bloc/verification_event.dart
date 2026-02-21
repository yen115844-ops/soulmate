import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class VerificationEvent extends Equatable {
  const VerificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load current verification status
class VerificationStatusRequested extends VerificationEvent {
  const VerificationStatusRequested();
}

/// Submit selfie for verification
class VerificationSelfieSubmitted extends VerificationEvent {
  final File selfieFile;
  final String? deviceInfo;

  const VerificationSelfieSubmitted({
    required this.selfieFile,
    this.deviceInfo,
  });

  @override
  List<Object?> get props => [selfieFile, deviceInfo];
}

/// Reset verification state (for retry)
class VerificationReset extends VerificationEvent {
  const VerificationReset();
}
