import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/emergency_contacts_repository.dart';
import '../../data/models/emergency_contact_model.dart';
import 'emergency_contacts_event.dart';
import 'emergency_contacts_state.dart';

class EmergencyContactsBloc extends Bloc<EmergencyContactsEvent, EmergencyContactsState> {
  final EmergencyContactsRepository _repository;

  EmergencyContactsBloc(this._repository) : super(const EmergencyContactsState()) {
    on<EmergencyContactsLoadRequested>(_onLoadRequested);
    on<EmergencyContactsRefreshRequested>(_onRefreshRequested);
    on<EmergencyContactCreateRequested>(_onCreateRequested);
    on<EmergencyContactUpdateRequested>(_onUpdateRequested);
    on<EmergencyContactDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    EmergencyContactsLoadRequested event,
    Emitter<EmergencyContactsState> emit,
  ) async {
    emit(state.copyWith(status: EmergencyContactsStatus.loading));

    try {
      final contacts = await _repository.getContacts();
      emit(state.copyWith(
        status: EmergencyContactsStatus.loaded,
        contacts: contacts,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: EmergencyContactsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshRequested(
    EmergencyContactsRefreshRequested event,
    Emitter<EmergencyContactsState> emit,
  ) async {
    add(const EmergencyContactsLoadRequested());
  }

  Future<void> _onCreateRequested(
    EmergencyContactCreateRequested event,
    Emitter<EmergencyContactsState> emit,
  ) async {
    emit(state.copyWith(status: EmergencyContactsStatus.saving));

    try {
      final newContact = await _repository.createContact(
        CreateEmergencyContactRequest(
          name: event.name,
          phone: event.phone,
          relationship: event.relationship,
          isPrimary: event.isPrimary,
        ),
      );

      final updatedContacts = [...state.contacts, newContact];
      emit(state.copyWith(
        status: EmergencyContactsStatus.loaded,
        contacts: updatedContacts,
        successMessage: 'Thêm liên hệ khẩn cấp thành công',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: EmergencyContactsStatus.loaded,
        errorMessage: 'Không thể thêm liên hệ: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateRequested(
    EmergencyContactUpdateRequested event,
    Emitter<EmergencyContactsState> emit,
  ) async {
    emit(state.copyWith(status: EmergencyContactsStatus.saving));

    try {
      final updatedContact = await _repository.updateContact(
        event.contactId,
        UpdateEmergencyContactRequest(
          name: event.name,
          phone: event.phone,
          relationship: event.relationship,
          isPrimary: event.isPrimary,
        ),
      );

      final updatedContacts = state.contacts.map((c) {
        return c.id == event.contactId ? updatedContact : c;
      }).toList();

      emit(state.copyWith(
        status: EmergencyContactsStatus.loaded,
        contacts: updatedContacts,
        successMessage: 'Cập nhật liên hệ thành công',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: EmergencyContactsStatus.loaded,
        errorMessage: 'Không thể cập nhật liên hệ: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteRequested(
    EmergencyContactDeleteRequested event,
    Emitter<EmergencyContactsState> emit,
  ) async {
    try {
      // Optimistically remove
      final updatedContacts = state.contacts
          .where((c) => c.id != event.contactId)
          .toList();
      emit(state.copyWith(contacts: updatedContacts));

      await _repository.deleteContact(event.contactId);
      emit(state.copyWith(
        successMessage: 'Xóa liên hệ khẩn cấp thành công',
      ));
    } catch (e) {
      // Refresh on error
      add(const EmergencyContactsRefreshRequested());
      emit(state.copyWith(
        errorMessage: 'Không thể xóa liên hệ: ${e.toString()}',
      ));
    }
  }
}
