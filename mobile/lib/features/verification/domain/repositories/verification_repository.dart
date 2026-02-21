import 'dart:io';

import '../entities/verification_entity.dart';

/// Verification repository interface - Domain layer
abstract class VerificationRepository {
  /// Submit selfie for verification
  Future<VerificationEntity> submitSelfie(File selfieFile, {String? deviceInfo});

  /// Get current verification status
  Future<VerificationEntity> getStatus();
}
