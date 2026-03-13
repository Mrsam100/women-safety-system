import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/providers/firebase_providers.dart';
import 'package:saferide/features/emergency_contacts/data/datasources/contacts_remote_datasource.dart';
import 'package:saferide/features/emergency_contacts/data/repositories/contacts_repository_impl.dart';
import 'package:saferide/features/emergency_contacts/domain/entities/emergency_contact.dart';
import 'package:saferide/features/emergency_contacts/domain/repositories/contacts_repository.dart';
import 'package:saferide/features/emergency_contacts/domain/usecases/add_contact.dart';
import 'package:saferide/features/emergency_contacts/domain/usecases/get_contacts.dart';
import 'package:saferide/features/emergency_contacts/domain/usecases/remove_contact.dart';

// --------------- Dependency providers ---------------

final contactsDatasourceProvider =
    Provider<ContactsRemoteDatasource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ContactsRemoteDatasourceImpl(firestore);
});

final contactsRepositoryProvider =
    Provider<ContactsRepository>((ref) {
  final datasource = ref.watch(contactsDatasourceProvider);
  return ContactsRepositoryImpl(datasource);
});

final getContactsUseCaseProvider = Provider<GetContacts>((ref) {
  return GetContacts(ref.watch(contactsRepositoryProvider));
});

final addContactUseCaseProvider = Provider<AddContact>((ref) {
  return AddContact(ref.watch(contactsRepositoryProvider));
});

final removeContactUseCaseProvider =
    Provider<RemoveContact>((ref) {
  return RemoveContact(ref.watch(contactsRepositoryProvider));
});

// --------------- State ---------------

class ContactsState {
  final List<EmergencyContact> contacts;
  final bool isLoading;
  final String? errorMessage;

  const ContactsState({
    this.contacts = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ContactsState copyWith({
    List<EmergencyContact>? contacts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// --------------- Notifier ---------------

class ContactsNotifier extends Notifier<ContactsState> {
  @override
  ContactsState build() {
    return const ContactsState();
  }

  GetContacts get _getContacts =>
      ref.read(getContactsUseCaseProvider);

  AddContact get _addContact =>
      ref.read(addContactUseCaseProvider);

  RemoveContact get _removeContact =>
      ref.read(removeContactUseCaseProvider);

  Future<void> loadContacts(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _getContacts(userId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (contacts) => state = state.copyWith(
        isLoading: false,
        contacts: contacts,
      ),
    );
  }

  Future<bool> addContact(
    String userId,
    EmergencyContact contact,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _addContact(userId, contact);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (newContact) {
        state = state.copyWith(
          isLoading: false,
          contacts: [...state.contacts, newContact],
        );
        return true;
      },
    );
  }

  Future<bool> removeContact(
    String userId,
    String contactId,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _removeContact(userId, contactId);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          contacts: state.contacts
              .where((c) => c.id != contactId)
              .toList(),
        );
        return true;
      },
    );
  }
}

// --------------- Provider ---------------

final contactsProvider =
    NotifierProvider<ContactsNotifier, ContactsState>(
  ContactsNotifier.new,
);
