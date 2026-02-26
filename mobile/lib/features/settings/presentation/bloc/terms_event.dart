import 'package:equatable/equatable.dart';

/// Events for the Terms BLoC
abstract class TermsEvent extends Equatable {
  const TermsEvent();

  @override
  List<Object?> get props => [];
}

/// Load terms of service content
class LoadTermsOfService extends TermsEvent {
  const LoadTermsOfService();
}

/// Load terms and conditions content
class LoadTermsAndConditions extends TermsEvent {
  const LoadTermsAndConditions();
}

/// Load privacy policy content
class LoadPrivacyPolicy extends TermsEvent {
  const LoadPrivacyPolicy();
}
