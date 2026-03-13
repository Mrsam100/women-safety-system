import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/features/safety/presentation/providers/panic_provider.dart';

/// Full-screen emergency state shown after a panic alert
/// has been triggered.
///
/// Displays:
/// - Alert confirmation header
/// - List of notified contacts
/// - Cancel / "I'm safe" option
/// - Live tracking status
class PanicScreen extends ConsumerWidget {
  const PanicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panicState = ref.watch(panicNotifierProvider);
    final alert = panicState.alert;
    final contacts = alert?.notifiedContacts ?? [];

    return Scaffold(
      backgroundColor: AppColors.danger,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(
            AppDimensions.paddingLG,
          ),
          child: Column(
            children: [
              const Spacer(),

              // Emergency icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      Colors.white.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                height: AppDimensions.paddingLG,
              ),

              // Title
              const Text(
                AppStrings.alertTriggered,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: AppDimensions.paddingSM,
              ),

              // Subtitle
              Text(
                'Your emergency contacts have been '
                'notified and your location is being '
                'shared.',
                style: TextStyle(
                  color:
                      Colors.white.withValues(alpha: 0.85),
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(
                height: AppDimensions.paddingXL,
              ),

              // Notified contacts
              if (contacts.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Contacts Notified '
                    '(${contacts.length})',
                    style: TextStyle(
                      color: Colors.white
                          .withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(
                  height: AppDimensions.paddingSM,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: contacts.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return _ContactTile(
                        phoneNumber: contacts[index],
                      );
                    },
                  ),
                ),
              ] else
                const Spacer(),

              // Status indicators
              _StatusRow(
                icon: Icons.location_on,
                text: 'Live location sharing active',
              ),
              const SizedBox(
                height: AppDimensions.paddingSM,
              ),
              _StatusRow(
                icon: Icons.sms,
                text: 'Emergency SMS sent',
              ),
              const SizedBox(
                height: AppDimensions.paddingSM,
              ),
              if (alert?.details['audioEvidencePath']
                      != null)
                _StatusRow(
                  icon: Icons.mic,
                  text: 'Audio evidence saved',
                ),

              const Spacer(),

              // Cancel / I'm safe button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(
                    context,
                    ref,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLG,
                      ),
                    ),
                  ),
                  child: const Text(
                    "I'M SAFE — Cancel Alert",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: AppDimensions.paddingMD,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Emergency?'),
        content: const Text(
          'Are you sure you are safe? '
          'Your contacts will be notified that the '
          'alert has been resolved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Active'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(panicNotifierProvider.notifier)
                  .resolve();
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.safe,
            ),
            child: const Text("Yes, I'm Safe"),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final String phoneNumber;

  const _ContactTile({required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: AppDimensions.paddingXS,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusMD,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person,
            color: Colors.white70,
            size: AppDimensions.iconMD,
          ),
          const SizedBox(
            width: AppDimensions.paddingSM,
          ),
          Expanded(
            child: Text(
              phoneNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: Colors.white70,
            size: AppDimensions.iconSM,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StatusRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: AppDimensions.iconSM,
        ),
        const SizedBox(width: AppDimensions.paddingSM),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
