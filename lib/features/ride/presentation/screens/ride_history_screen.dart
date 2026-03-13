import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/core/widgets/loading_overlay.dart';
import 'package:saferide/features/ride/presentation/providers/ride_history_provider.dart';
import 'package:saferide/features/ride/presentation/screens/ride_summary_screen.dart';
import 'package:saferide/features/ride/presentation/widgets/ride_history_card.dart';

/// Displays a scrollable list of past rides with
/// pull-to-refresh and infinite scroll pagination.
class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() =>
      _RideHistoryScreenState();
}

class _RideHistoryScreenState
    extends ConsumerState<RideHistoryScreen> {
  final _scrollController = ScrollController();

  String get _userId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(rideHistoryNotifierProvider.notifier)
          .loadHistory(userId: _userId);
    });
  }

  void _onScroll() {
    if (_isBottom) {
      ref
          .read(rideHistoryNotifierProvider.notifier)
          .loadMore(userId: _userId);
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll =
        _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= maxScroll - 200;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(
      rideHistoryNotifierProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.rideHistory),
        centerTitle: true,
      ),
      body: _buildBody(historyState),
    );
  }

  Widget _buildBody(RideHistoryState state) {
    switch (state.status) {
      case RideHistoryStatus.initial:
      case RideHistoryStatus.loading:
        return const Center(
          child: CircularProgressIndicator(),
        );

      case RideHistoryStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: AppDimensions.iconXL,
                color: AppColors.danger,
              ),
              const SizedBox(
                height: AppDimensions.paddingMD,
              ),
              Text(
                state.errorMessage ??
                    AppStrings.genericError,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(
                height: AppDimensions.paddingMD,
              ),
              TextButton(
                onPressed: () => ref
                    .read(
                      rideHistoryNotifierProvider
                          .notifier,
                    )
                    .refresh(userId: _userId),
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case RideHistoryStatus.loaded:
      case RideHistoryStatus.loadingMore:
        if (state.rides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: AppDimensions.iconXL,
                  color: AppColors.disabled,
                ),
                const SizedBox(
                  height: AppDimensions.paddingMD,
                ),
                const Text(
                  'No rides yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref
              .read(
                rideHistoryNotifierProvider.notifier,
              )
              .refresh(userId: _userId),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingSM,
            ),
            itemCount: state.rides.length +
                (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.rides.length) {
                return const Padding(
                  padding: EdgeInsets.all(
                    AppDimensions.paddingMD,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final ride = state.rides[index];
              return RideHistoryCard(
                ride: ride,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RideSummaryScreen(
                      rideId: ride.id,
                    ),
                  ),
                ),
              );
            },
          ),
        );
    }
  }
}
