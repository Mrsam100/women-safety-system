import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/features/ride/domain/entities/ride.dart';
import 'package:saferide/features/ride/domain/usecases/get_ride_history.dart';
import 'package:saferide/features/ride/presentation/providers/ride_provider.dart';

// ── Use case provider ──

final getRideHistoryUseCaseProvider =
    Provider<GetRideHistory>((ref) {
  return GetRideHistory(
    ref.watch(rideRepositoryProvider),
  );
});

// ── Ride history state ──

enum RideHistoryStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

class RideHistoryState {
  final RideHistoryStatus status;
  final List<Ride> rides;
  final bool hasMore;
  final String? errorMessage;

  const RideHistoryState({
    this.status = RideHistoryStatus.initial,
    this.rides = const [],
    this.hasMore = true,
    this.errorMessage,
  });

  RideHistoryState copyWith({
    RideHistoryStatus? status,
    List<Ride>? rides,
    bool? hasMore,
    String? errorMessage,
  }) {
    return RideHistoryState(
      status: status ?? this.status,
      rides: rides ?? this.rides,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class RideHistoryNotifier
    extends StateNotifier<RideHistoryState> {
  final GetRideHistory _getRideHistory;

  static const _pageSize = 20;

  RideHistoryNotifier({
    required GetRideHistory getRideHistory,
  })  : _getRideHistory = getRideHistory,
        super(const RideHistoryState());

  /// Load the first page of ride history.
  Future<void> loadHistory({
    required String userId,
  }) async {
    state = state.copyWith(
      status: RideHistoryStatus.loading,
    );

    final result = await _getRideHistory(
      userId: userId,
      limit: _pageSize,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: RideHistoryStatus.error,
        errorMessage: failure.message,
      ),
      (rides) => state = state.copyWith(
        status: RideHistoryStatus.loaded,
        rides: rides,
        hasMore: rides.length >= _pageSize,
      ),
    );
  }

  /// Load the next page of rides (pagination).
  Future<void> loadMore({
    required String userId,
  }) async {
    if (!state.hasMore ||
        state.status == RideHistoryStatus.loadingMore) {
      return;
    }

    state = state.copyWith(
      status: RideHistoryStatus.loadingMore,
    );

    final lastRide = state.rides.isNotEmpty
        ? state.rides.last
        : null;

    final result = await _getRideHistory(
      userId: userId,
      limit: _pageSize,
      startAfter: lastRide?.startedAt,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: RideHistoryStatus.error,
        errorMessage: failure.message,
      ),
      (newRides) => state = state.copyWith(
        status: RideHistoryStatus.loaded,
        rides: [...state.rides, ...newRides],
        hasMore: newRides.length >= _pageSize,
      ),
    );
  }

  /// Refresh the ride history from scratch.
  Future<void> refresh({
    required String userId,
  }) async {
    state = const RideHistoryState();
    await loadHistory(userId: userId);
  }
}

final rideHistoryNotifierProvider =
    StateNotifierProvider<RideHistoryNotifier,
        RideHistoryState>(
  (ref) {
    return RideHistoryNotifier(
      getRideHistory: ref.watch(
        getRideHistoryUseCaseProvider,
      ),
    );
  },
);
