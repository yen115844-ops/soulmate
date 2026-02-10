import 'package:equatable/equatable.dart';

import '../../data/models/emergency_contact_model.dart';

enum EmergencyContactsStatus { initial, loading, loaded, saving, error }

class EmergencyContactsState extends Equatable {
  final EmergencyContactsStatus status;
  final List<EmergencyContactModel> contacts;
  final String? errorMessage;
  final String? successMessage;

  const EmergencyContactsState({
    this.status = EmergencyContactsStatus.initial,
    this.contacts = const [],
    this.errorMessage,
    this.successMessage,
  });

  EmergencyContactsState copyWith({
    EmergencyContactsStatus? status,
    List<EmergencyContactModel>? contacts,
    String? errorMessage,
    String? successMessage,
  }) {
    return EmergencyContactsState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, contacts, errorMessage, successMessage];
}
