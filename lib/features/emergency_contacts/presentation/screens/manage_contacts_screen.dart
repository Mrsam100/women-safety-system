import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/core/constants/route_names.dart';
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
    final user =
        ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      ref
          .read(contactsProvider.notifier)
          .loadContacts(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactsProvider);
    final theme = Theme.of(context);
    final count = state.contacts.length;
    final isMinMet = count >= AppDimensions.minContacts;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  24, 24, 24, 0),
              child: _buildHeader(theme, count),
            ),

            const SizedBox(height: 24),

            // Content
            Expanded(
              child: _buildBody(state, theme),
            ),

            // Bottom CTA
            _buildBottomBar(
                theme, count, isMinMet, state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar (step 3 of 3)
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.3),
                  borderRadius:
                      BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Emergency Contacts',
          style:
              theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add people who will be notified '
          'in an emergency',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Count indicator
        _ContactCounter(
          current: count,
          min: AppDimensions.minContacts,
          max: AppDimensions.maxContacts,
        ),
      ],
    );
  }

  Widget _buildBody(
      ContactsState state, ThemeData theme) {
    if (state.isLoading && state.contacts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.errorMessage != null &&
        state.contacts.isEmpty) {
      return _buildError(state.errorMessage!, theme);
    }

    if (state.contacts.isEmpty) {
      return _buildEmpty(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      itemCount: state.contacts.length,
      itemBuilder: (context, index) {
        final contact = state.contacts[index];
        return ContactCard(
          contact: contact,
          onDelete: () => _removeContact(contact.id),
        );
      },
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_add_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No contacts yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add at least '
              '${AppDimensions.minContacts} trusted '
              'people who will be alerted\n'
              'during an emergency.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showAddContactDialog,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add First Contact'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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

  Widget _buildBottomBar(
    ThemeData theme,
    int count,
    bool isMinMet,
    ContactsState state,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count < AppDimensions.maxContacts)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _showAddContactDialog,
                icon: const Icon(
                    Icons.person_add_rounded),
                label: const Text('Add Contact'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          if (count < AppDimensions.maxContacts)
            const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed:
                  isMinMet ? _goToHome : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors
                    .primary
                    .withValues(alpha: 0.15),
                disabledForegroundColor: AppColors
                    .primary
                    .withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isMinMet
                    ? "Let's Go!"
                    : '${AppDimensions.minContacts - count} '
                        'more needed',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 3 of 3',
            style:
                theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _goToHome() {
    context.go(RouteNames.home);
  }

  Future<void> _showAddContactDialog() async {
    final state = ref.read(contactsProvider);

    if (state.contacts.length >=
        AppDimensions.maxContacts) {
      context.showErrorSnackBar(
          AppStrings.maxContactsReached);
      return;
    }

    final contact =
        await showDialog<EmergencyContact>(
      context: context,
      builder: (_) => const AddContactDialog(),
    );

    if (contact == null || !mounted) return;

    final user =
        ref.read(firebaseAuthProvider).currentUser;
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
      final error =
          ref.read(contactsProvider).errorMessage;
      context.showErrorSnackBar(
        error ?? AppStrings.genericError,
      );
    }
  }

  Future<void> _removeContact(
      String contactId) async {
    final state = ref.read(contactsProvider);

    if (state.contacts.length <=
        AppDimensions.minContacts) {
      context.showErrorSnackBar(
          AppStrings.minContactsRequired);
      return;
    }

    final user =
        ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    final success = await ref
        .read(contactsProvider.notifier)
        .removeContact(user.uid, contactId);

    if (!mounted) return;

    if (success) {
      context.showSuccessSnackBar('Contact removed');
    } else {
      final error =
          ref.read(contactsProvider).errorMessage;
      context.showErrorSnackBar(
        error ?? AppStrings.genericError,
      );
    }
  }
}

class _ContactCounter extends StatelessWidget {
  final int current;
  final int min;
  final int max;

  const _ContactCounter({
    required this.current,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final isMinMet = current >= min;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isMinMet
            ? AppColors.safe.withValues(alpha: 0.08)
            : AppColors.warning
                .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMinMet
              ? AppColors.safe
                  .withValues(alpha: 0.2)
              : AppColors.warning
                  .withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isMinMet
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            size: 20,
            color: isMinMet
                ? AppColors.safe
                : AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isMinMet
                  ? '$current of $max contacts added'
                  : '${min - current} more contact(s) '
                      'needed (min $min)',
              style: theme.textTheme.bodySmall
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
}
