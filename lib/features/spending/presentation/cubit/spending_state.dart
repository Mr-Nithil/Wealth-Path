part of 'spending_cubit.dart';

sealed class SpendingState extends Equatable {
  const SpendingState();

  @override
  List<Object?> get props => [];
}

final class SpendingInitial extends SpendingState {}

class SpendingLoading extends SpendingState {
  const SpendingLoading();
}

class SpendingLoaded extends SpendingState {
  final List<Spending> items;
  final double total;
  final bool hasMore;
  final bool isLoadingMore;

  const SpendingLoaded({
    required this.items,
    required this.total,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  SpendingLoaded copyWith({
    List<Spending>? items,
    double? total,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SpendingLoaded(
      items: items ?? this.items,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [items, total, hasMore, isLoadingMore];
}

class SpendingError extends SpendingState {
  final String message;
  final List<Spending>? previousItems;
  final double? previousTotal;

  const SpendingError({
    required this.message,
    this.previousItems,
    this.previousTotal,
  });

  @override
  List<Object?> get props => [message, previousItems, previousTotal];
}
