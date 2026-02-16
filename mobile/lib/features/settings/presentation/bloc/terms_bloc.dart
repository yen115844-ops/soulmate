import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/terms_repository.dart';
import 'terms_event.dart';
import 'terms_state.dart';

/// BLoC for loading terms content from the backend API
class TermsBloc extends Bloc<TermsEvent, TermsState> {
  final TermsRepository _repository;

  TermsBloc({required TermsRepository repository})
      : _repository = repository,
        super(const TermsInitial()) {
    on<LoadTermsOfService>(_onLoadTermsOfService);
    on<LoadTermsAndConditions>(_onLoadTermsAndConditions);
  }

  Future<void> _onLoadTermsOfService(
    LoadTermsOfService event,
    Emitter<TermsState> emit,
  ) async {
    emit(const TermsLoading());
    try {
      final content = await _repository.getTermsOfService();
      emit(TermsLoaded(content: content));
    } catch (e) {
      emit(TermsError(
        message: 'Không thể tải điều khoản sử dụng. Vui lòng thử lại.',
      ));
    }
  }

  Future<void> _onLoadTermsAndConditions(
    LoadTermsAndConditions event,
    Emitter<TermsState> emit,
  ) async {
    emit(const TermsLoading());
    try {
      final content = await _repository.getTermsAndConditions();
      emit(TermsLoaded(content: content));
    } catch (e) {
      emit(TermsError(
        message: 'Không thể tải điều kiện sử dụng. Vui lòng thử lại.',
      ));
    }
  }
}
