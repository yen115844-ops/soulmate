import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../data/models/kyc_model.dart';

enum KycPageStatus { initial, loading, loaded, uploading, submitting, success, error }

class KycState extends Equatable {
  final KycPageStatus status;
  final KycStatusModel? kycStatus;
  final int currentStep;
  final File? frontImage;
  final File? backImage;
  final File? selfieImage;
  final String? frontImageUrl;
  final String? backImageUrl;
  final String? selfieImageUrl;
  final String? errorMessage;
  final String? successMessage;

  const KycState({
    this.status = KycPageStatus.initial,
    this.kycStatus,
    this.currentStep = 0,
    this.frontImage,
    this.backImage,
    this.selfieImage,
    this.frontImageUrl,
    this.backImageUrl,
    this.selfieImageUrl,
    this.errorMessage,
    this.successMessage,
  });

  KycState copyWith({
    KycPageStatus? status,
    KycStatusModel? kycStatus,
    int? currentStep,
    File? frontImage,
    File? backImage,
    File? selfieImage,
    String? frontImageUrl,
    String? backImageUrl,
    String? selfieImageUrl,
    String? errorMessage,
    String? successMessage,
  }) {
    return KycState(
      status: status ?? this.status,
      kycStatus: kycStatus ?? this.kycStatus,
      currentStep: currentStep ?? this.currentStep,
      frontImage: frontImage ?? this.frontImage,
      backImage: backImage ?? this.backImage,
      selfieImage: selfieImage ?? this.selfieImage,
      frontImageUrl: frontImageUrl ?? this.frontImageUrl,
      backImageUrl: backImageUrl ?? this.backImageUrl,
      selfieImageUrl: selfieImageUrl ?? this.selfieImageUrl,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  bool get canProceedStep0 => frontImage != null;
  bool get canProceedStep1 => backImage != null;
  bool get canProceedStep2 => selfieImage != null;
  bool get canSubmit => frontImageUrl != null && backImageUrl != null && selfieImageUrl != null;

  @override
  List<Object?> get props => [
    status, 
    kycStatus, 
    currentStep, 
    frontImage?.path, 
    backImage?.path, 
    selfieImage?.path,
    frontImageUrl,
    backImageUrl,
    selfieImageUrl,
    errorMessage,
    successMessage,
  ];
}
