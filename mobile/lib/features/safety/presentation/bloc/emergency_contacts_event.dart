import 'package:equatable/equatable.dart';

abstract class EmergencyContactsEvent extends Equatable {
  const EmergencyContactsEvent();

  @override
  List<Object?> get props => [];
}

class EmergencyContactsLoadRequested extends EmergencyContactsEvent {
  const EmergencyContactsLoadRequested();
}

class EmergencyContactsRefreshRequested extends EmergencyContactsEvent {
  const EmergencyContactsRefreshRequested();
}

class EmergencyContactCreateRequested extends EmergencyContactsEvent {
  final String name;
  final String phone;
  final String? relationship;
  final bool isPrimary;

  const EmergencyContactCreateRequested({
    required this.name,
    required this.phone,
    this.relationship,
    this.isPrimary = false,
  });

  @override
  List<Object?> get props => [name, phone, relationship, isPrimary];
}

class EmergencyContactUpdateRequested extends EmergencyContactsEvent {
  final String contactId;
  final String? name;
  final String? phone;
  final String? relationship;
  final bool? isPrimary;

  const EmergencyContactUpdateRequested({
    required this.contactId,
    this.name,
    this.phone,
    this.relationship,
    this.isPrimary,
  });

  @override
  List<Object?> get props => [contactId, name, phone, relationship, isPrimary];
}

class EmergencyContactDeleteRequested extends EmergencyContactsEvent {
  final String contactId;

  const EmergencyContactDeleteRequested(this.contactId);

  @override
  List<Object?> get props => [contactId];
}
