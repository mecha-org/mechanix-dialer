import 'package:dialer/core/utils/app_logger.dart';
import 'package:dialer/core/utils/enums.dart';
import 'package:dialer/features/contacts/data/repositories/contacts_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final ContactsRepository repository;

  ContactsBloc(this.repository) : super(const ContactsState()) {
    on<LoadContacts>(_onLoad);
    on<SaveContact>(_onSave);
    on<DeleteContact>(_onDelete);
    on<SearchContacts>(_onSearch);
  }

  Future<void> _onLoad(LoadContacts event, Emitter<ContactsState> emit) async {
    emit(state.copyWith(status: ContactsStatus.loading));
    try {
      final contacts = await repository.getAll();
      emit(state.copyWith(status: ContactsStatus.loaded, contacts: contacts));
    } catch (e) {
      AppLogger.e('Failed to load contacts: $e');
      emit(state.copyWith(status: ContactsStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSave(SaveContact event, Emitter<ContactsState> emit) async {
    emit(state.copyWith(status: ContactsStatus.loading));
    try {
      await repository.save(event.contact, event.phoneNumbers, event.emails);
      final contacts = await repository.getAll();
      emit(state.copyWith(status: ContactsStatus.loaded, contacts: contacts));
    } catch (e) {
      AppLogger.e('Failed to save contact: $e');
      emit(state.copyWith(status: ContactsStatus.error, error: e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteContact event,
    Emitter<ContactsState> emit,
  ) async {
    emit(state.copyWith(status: ContactsStatus.loading));
    try {
      await repository.delete(event.id);
      final contacts = await repository.getAll();
      emit(state.copyWith(status: ContactsStatus.loaded, contacts: contacts));
    } catch (e) {
      AppLogger.e('Failed to delete contact: $e');
      emit(state.copyWith(status: ContactsStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSearch(
    SearchContacts event,
    Emitter<ContactsState> emit,
  ) async {
    emit(state.copyWith(status: ContactsStatus.loading));
    try {
      final results = await repository.search(event.query);
      emit(state.copyWith(status: ContactsStatus.loaded, contacts: results));
    } catch (e) {
      AppLogger.e('Failed to search contacts: $e');
      emit(state.copyWith(status: ContactsStatus.error, error: e.toString()));
    }
  }
}
