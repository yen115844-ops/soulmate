import 'package:equatable/equatable.dart';

/// States for the Terms BLoC
abstract class TermsState extends Equatable {
  const TermsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TermsInitial extends TermsState {
  const TermsInitial();
}

/// Loading terms content
class TermsLoading extends TermsState {
  const TermsLoading();
}

/// Terms content loaded successfully
class TermsLoaded extends TermsState {
  final String content;

  const TermsLoaded({required this.content});

  @override
  List<Object?> get props => [content];
}

/// Error loading terms
class TermsError extends TermsState {
  final String message;

  const TermsError({required this.message});

  @override
  List<Object?> get props => [message];
}
