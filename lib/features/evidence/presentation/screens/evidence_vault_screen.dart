import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/features/evidence/domain/entities/audio_evidence.dart';
import 'package:saferide/features/evidence/presentation/providers/evidence_provider.dart';

class EvidenceVaultScreen extends ConsumerStatefulWidget {
  final String rideId;

  const EvidenceVaultScreen({
    super.key,
    this.rideId = '',
  });

  @override
  ConsumerState<EvidenceVaultScreen> createState() =>
      _EvidenceVaultScreenState();
}

class _EvidenceVaultScreenState
    extends ConsumerState<EvidenceVaultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(evidenceNotifierProvider.notifier)
          .loadEvidence(widget.rideId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(evidenceNotifierProvider);

    ref.listen<EvidenceState>(
      evidenceNotifierProvider,
      (previous, next) {
        if (next.status == EvidenceStatus.error &&
            next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.danger,
            ),
          );
          ref
              .read(evidenceNotifierProvider.notifier)
              .clearError();
        }
        if (next.downloadedFilePath != null &&
            previous?.downloadedFilePath !=
                next.downloadedFilePath) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Downloaded to: '
                '${next.downloadedFilePath}',
              ),
              backgroundColor: AppColors.safe,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidence Vault'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        actions: [
          IconButton(
            onPressed: () {
              ref
                  .read(
                    evidenceNotifierProvider.notifier,
                  )
                  .cleanupExpiredEvidence();
            },
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Clean expired evidence',
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(EvidenceState state) {
    if (state.status == EvidenceStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (state.evidenceList.isEmpty &&
        state.status == EvidenceStatus.loaded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(
            AppDimensions.paddingXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                size: AppDimensions.iconXL * 2,
                color: AppColors.disabled,
              ),
              const SizedBox(
                height: AppDimensions.paddingMD,
              ),
              Text(
                'No evidence recorded',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(
                height: AppDimensions.paddingSM,
              ),
              Text(
                'Audio evidence will appear here '
                'when an emergency is triggered '
                'during a ride.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref
          .read(evidenceNotifierProvider.notifier)
          .loadEvidence(widget.rideId),
      child: ListView.builder(
        padding: const EdgeInsets.all(
          AppDimensions.paddingMD,
        ),
        itemCount: state.evidenceList.length,
        itemBuilder: (context, index) {
          final evidence = state.evidenceList[index];
          return _EvidenceCard(
            evidence: evidence,
            isProcessing:
                state.status == EvidenceStatus.deleting ||
                    state.status ==
                        EvidenceStatus.downloading,
            onSave: () => ref
                .read(
                  evidenceNotifierProvider.notifier,
                )
                .markAsSaved(evidence.id),
            onDelete: () =>
                _confirmDelete(context, evidence),
            onDownload: () => ref
                .read(
                  evidenceNotifierProvider.notifier,
                )
                .downloadEvidence(evidence.id),
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AudioEvidence evidence,
  ) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Evidence'),
        content: const Text(
          'Are you sure you want to permanently '
          'delete this evidence? This action '
          'cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              ref
                  .read(
                    evidenceNotifierProvider.notifier,
                  )
                  .deleteEvidence(evidence.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final AudioEvidence evidence;
  final bool isProcessing;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const _EvidenceCard({
    required this.evidence,
    required this.isProcessing,
    required this.onSave,
    required this.onDelete,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = evidence.isExpired;
    final remaining = evidence.remainingTime;

    return Card(
      margin: const EdgeInsets.only(
        bottom: AppDimensions.paddingSM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusMD,
        ),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(
          AppDimensions.paddingMD,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(
                    AppDimensions.paddingSM,
                  ),
                  decoration: BoxDecoration(
                    color: evidence.isSaved
                        ? AppColors.safe.withOpacity(0.1)
                        : isExpired
                            ? AppColors.danger
                                .withOpacity(0.1)
                            : AppColors.primary
                                .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMD,
                    ),
                  ),
                  child: Icon(
                    evidence.isSaved
                        ? Icons.bookmark
                        : Icons.mic,
                    color: evidence.isSaved
                        ? AppColors.safe
                        : isExpired
                            ? AppColors.danger
                            : AppColors.primary,
                    size: AppDimensions.iconMD,
                  ),
                ),
                const SizedBox(
                  width: AppDimensions.paddingSM,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audio Evidence',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(evidence.createdAt),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                          color:
                              AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (evidence.isSaved)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          AppDimensions.paddingSM,
                      vertical:
                          AppDimensions.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.safe
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(
                        AppDimensions.radiusSM,
                      ),
                    ),
                    child: Text(
                      'Saved',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(
                        color: AppColors.safeDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(
              height: AppDimensions.paddingSM,
            ),
            const Divider(height: 1),
            const SizedBox(
              height: AppDimensions.paddingSM,
            ),

            // Info rows
            _InfoRow(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: _formatDuration(
                evidence.durationSeconds,
              ),
            ),
            const SizedBox(
              height: AppDimensions.paddingXS,
            ),
            _InfoRow(
              icon: Icons.route_outlined,
              label: 'Ride',
              value: evidence.rideId.length > 12
                  ? '${evidence.rideId.substring(0, 12)}...'
                  : evidence.rideId,
            ),
            const SizedBox(
              height: AppDimensions.paddingXS,
            ),
            _InfoRow(
              icon: isExpired
                  ? Icons.warning_amber
                  : Icons.schedule,
              label: isExpired
                  ? 'Expired'
                  : 'Expires in',
              value: isExpired
                  ? 'Expired'
                  : _formatRemaining(remaining),
              valueColor: isExpired
                  ? AppColors.danger
                  : remaining.inDays < 7
                      ? AppColors.warning
                      : null,
            ),
            if (evidence.alertId != null) ...[
              const SizedBox(
                height: AppDimensions.paddingXS,
              ),
              _InfoRow(
                icon: Icons.notifications_active,
                label: 'Alert',
                value:
                    evidence.alertId!.length > 12
                        ? '${evidence.alertId!.substring(0, 12)}...'
                        : evidence.alertId!,
                valueColor: AppColors.danger,
              ),
            ],

            const SizedBox(
              height: AppDimensions.paddingMD,
            ),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!evidence.isSaved)
                  _ActionButton(
                    icon: Icons.bookmark_border,
                    label: 'Save',
                    color: AppColors.safe,
                    onPressed:
                        isProcessing ? null : onSave,
                  ),
                const SizedBox(
                  width: AppDimensions.paddingSM,
                ),
                _ActionButton(
                  icon: Icons.download,
                  label: 'Download',
                  color: AppColors.primary,
                  onPressed:
                      isProcessing ? null : onDownload,
                ),
                const SizedBox(
                  width: AppDimensions.paddingSM,
                ),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppColors.danger,
                  onPressed:
                      isProcessing ? null : onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year at $hour:$minute';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remaining}s';
    }
    return '${remaining}s';
  }

  String _formatRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} days';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours} hours';
    }
    return '${duration.inMinutes} minutes';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconSM,
          color: AppColors.textSecondary,
        ),
        const SizedBox(
          width: AppDimensions.paddingSM,
        ),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: AppDimensions.iconSM),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSM,
          vertical: AppDimensions.paddingXS,
        ),
      ),
    );
  }
}
