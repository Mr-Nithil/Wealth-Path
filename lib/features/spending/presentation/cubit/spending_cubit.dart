import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:wealthpath/features/spending/data/models/spending_model.dart';
import 'package:wealthpath/features/spending/domain/entities/spending.dart';
import 'package:wealthpath/features/spending/domain/usecases/add_spending.dart';
import 'package:wealthpath/features/spending/domain/usecases/get_spending.dart';

part 'spending_state.dart';

class SpendingCubit extends Cubit<SpendingState> {
  final GetSpending getSpending;
  final AddSpending addSpending;
  final _uuid = const Uuid();

  int _currentPage = 1;
  static const int _pageSize = 20;

  SpendingCubit({required this.getSpending, required this.addSpending})
    : super(SpendingInitial());

  // Initial Load
  Future<void> loadSpending() async {
    emit(const SpendingLoading());
    _currentPage = 1;
    try {
      final result = await getSpending(page: _currentPage, limit: _pageSize);
      emit(
        SpendingLoaded(
          items: result.items,
          total: result.total,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      emit(
        SpendingError(
          message:
              "Failed to load your spending right now. Please try again later.",
        ),
      );
    }
  }

  // Pagination - load next page
  Future<void> loadMore() async {
    final current = state;
    if (current is! SpendingLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      _currentPage++;
      final result = await getSpending(page: _currentPage, limit: _pageSize);

      emit(
        SpendingLoaded(
          items: [...current.items, ...result.items],
          total: result.total,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      _currentPage--;
      emit(current.copyWith(isLoadingMore: false));
      emit(
        SpendingError(
          message: "Failed to load more spending. Pull to retry.",
          previousItems: current.items,
          previousTotal: current.total,
        ),
      );
    }
  }

  // Add spending (optimistic)
  Future<void> addSpendingRecord({
    required String merchant,
    required double amount,
    required String category,
  }) async {
    final current = state;
    if (current is! SpendingLoaded) return;

    // Build a temporary optimistic record
    final tempId = 'temp_${_uuid.v4()}';
    final optimisticItem = SpendingModel.optimistic(
      tempId: tempId,
      merchant: merchant,
      amount: amount,
      category: category,
    );

    // Emit updated state immediately (optimistic)
    final optimisticItems = [optimisticItem, ...current.items];
    final optimisticTotal = current.total + amount;
    emit(current.copyWith(items: optimisticItems, total: optimisticTotal));

    try {
      // Call API in background
      final serverRecord = await addSpending(
        merchant: merchant,
        amount: amount,
        category: category,
      );

      // Replace temp item with real server record
      final updatedItems = (state as SpendingLoaded).items
          .map((item) => item.id == tempId ? serverRecord : item)
          .toList();

      emit((state as SpendingLoaded).copyWith(items: updatedItems));
    } catch (e) {
      // Rollback: remove the optimistic item, restore total
      final rolledBack = current.items
          .where((item) => item.id != tempId)
          .toList();

      emit(
        SpendingError(
          message: 'Failed to save this spending entry. Please try again.',
          previousItems: rolledBack,
          previousTotal: current.total,
        ),
      );
    }
  }
}
