import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/core/extensions/context_extensions.dart';
import 'package:saferide/core/providers/firebase_providers.dart';
import 'package:saferide/features/emergency_contacts/domain/entities/emergency_contact.dart';
import 'package:saferide/features/emergency_contacts/presentation/providers/contacts_provider.dart';
import 'package:saferide/features/emergency_contacts/presentation/widgets/add_contact_dialog.dart';
import 'package:saferide/features/emergency_contacts/presentation/widgets/contact_card.dart';

class ManageContactsScreen extends ConsumerStatefulWidget {
  const ManageContactsScreen({super.key});

  @override
  ConsumerState<ManageContactsScreen> createState() =>
      _ManageContactsScreenState();
}

class _ManageContactsScreenState
    extends ConsumerState<ManageContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContacts();
    });
  }

  void _loadContacts() {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      ref.read(contactsProvider.notifier).loadContacts(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.emergencyContacts),
      ),
      body: _buildBody(state),
      floatingActionButton: _buildFab(state),
    );
  }

  Widget _buildBody(ContactsState state) {
    if (state.isLoading && state.contacts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.contacts.isEmpty) {
      return _buildError(state.errorMessage!);
    }

    if (state.contacts.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      children: [
        _buildStatusBanner(state.contacts.length),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingSM,
            ),
            itemCount: state.contacts.length,
            itemBuilder: (context, index) {
              final contact = state.contacts[index];
              return ContactCard(
                contact: contact,
                onDelete: () => _removeContact(contact.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(int count) {
    final isMinMet = count >= AppDimensions.minContacts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      color: isMinMet
          ? AppColors.safe.withOpacity(0.1)
          : AppColors.warning.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            isMinMet ? Icons.check_circle : Icons.info_outline,
            size: AppDimensions.iconMD,
            color: isMinMet ? AppColors.safe : AppColors.warning,
          ),
          const SizedBox(width: AppDimensions.paddingSM),
          Expanded(
            child: Text(
              isMinMet
                  ? '$count of ${AppDimensions.maxContacts} '
                      'contacts added'
                  : '${AppDimensions.minContacts - count} '
                      'more contact(s) needed',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(
                color: isMinMet
                    ? AppColors.safeDark
                    : AppColors.warningDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.contacts_outlined,
              size: 64,
              color: AppColors.disabled,
            ),
            const SizedBox(height: AppDimensions.paddingMD),
            Text(
              AppStrings.minContactsRequired,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingSM),
            Text(
              'Your emergency contacts will be notified '
              'when you trigger an alert.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: AppDimensions.paddingMD),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingMD),
            TextButton.icon(
              onPressed: _loadContacts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFab(ContactsState state) {
    if (state.contacts.length >= AppDimensions.maxContacts) {
      return null;
    }

    return FloatingActionButton.extended(
      onPressed: _showAddContactDialog,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      icon: const Icon(Icons.person_add),
      label: const Text(AppStrings.addContact),
    );
  }

  Future<void> _showAddContactDialog() async {
    final state = ref.read(contactsProvider);

    if (state.contacts.length >= AppDimensions.maxContacts) {
      context.showErrorSnackBar(AppStrings.maxContactsReached);
      return;
    }

    final contact = await showDialog<EmergencyContact>(
      context: context,
      builder: (_) => const AddContactDialog(),
    );

    if (contact == null || !mounted) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    final success = await ref
        .read(contactsProvider.notifier)
        .addContact(user.uid, contact);

    if (!mounted) return;

    if (success) {
      context.showSuccessSnackBar(
        '${contact.name} added successfully',
      );
    } else {
      final error = ref.read(contactsProvider).errorMessage;
      context.showErrorSnackBar(
        error ?? AppStrings.genericError,
      );
    }
  }

  Future<void> _removeContact(String contactId) async {
    final state = ref.read(contactsProvider);

    if (state.contacts.length <= AppDimensions.minContacts) {
      context.showErrorSnackBar(AppStrings.minContactsRequired);
      return;
    }

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    final success = await ref
        .read(contactsProvider.notifier)
        .removeContact(user.uid, contactId);

    if (!mounted) return;

    if (success) {
      context.showSuccessSnackBar('Contact removed');
    } else {
      final error = ref.read(contactsProvider).errorMessage;
      context.showErrorSnackBar(
        error ?? AppStrings.genericError,
      );
    }
  }
}
