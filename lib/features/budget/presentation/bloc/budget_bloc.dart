import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:wealthpath/features/budget/domain/entities/budget.dart';
import 'package:wealthpath/features/budget/domain/usecases/cache_budgets.dart';
import 'package:wealthpath/features/budget/domain/usecases/get_budgets.dart';
import 'package:wealthpath/features/budget/domain/usecases/get_cached_bugets.dart';
import 'package:wealthpath/features/budget/domain/usecases/update_budget_limit.dart';

part 'budget_event.dart';
part 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final GetBudgets _getBudgets;
  final UpdateBudgetLimit _updateBudgetLimit;
  final CacheBudgets _cacheBudgets;
  final GetCachedBudgets _getCachedBudgets;

  int _currentPage = 1;
  static const int _pageSize = 20;

  BudgetBloc({
    required GetBudgets getBudgets,
    required UpdateBudgetLimit updateBudgetLimit,
    required CacheBudgets cacheBudgets,
    required GetCachedBudgets getCachedBudgets,
  }) : _getBudgets = getBudgets,
       _updateBudgetLimit = updateBudgetLimit,
       _cacheBudgets = cacheBudgets,
       _getCachedBudgets = getCachedBudgets,
       super(const BudgetInitial()) {
    on<LoadBudgets>(_onLoadBudgets, transformer: restartable());
    on<LoadMoreBudgets>(_onLoadMore, transformer: droppable());
    on<RefreshBudgets>(_onRefresh, transformer: restartable());
    on<SearchBudgets>(_onSearch, transformer: sequential());
    on<ChangeBudgetLimit>(_onChangeLimit, transformer: sequential());
  }

  // Cache-first loading
  Future<void> _onLoadBudgets(
    LoadBudgets event,
    Emitter<BudgetState> emit,
  ) async {
    _currentPage = 1;
    final cached = await _getCachedBudgets();

    if (cached.isNotEmpty) {
      emit(BudgetLoaded(budgets: cached, isOffline: true));
    } else {
      emit(const BudgetLoading());
    }

    try {
      final result = await _getBudgets(page: _currentPage, limit: _pageSize);
      await _cacheBudgets(result.budgets);
      emit(
        BudgetLoaded(
          budgets: result.budgets,
          hasMore: result.hasMore,
          isOffline: false,
          currentPage: _currentPage,
        ),
      );
    } catch (e) {
      if (cached.isEmpty) {
        emit(BudgetError(e.toString()));
      }
    }
  }

  // Pagination
  Future<void> _onLoadMore(
    LoadMoreBudgets event,
    Emitter<BudgetState> emit,
  ) async {
    final current = state;
    if (current is! BudgetLoaded || !current.hasMore) return;

    try {
      _currentPage++;
      final result = await _getBudgets(page: _currentPage, limit: _pageSize);

      final merged = [...current.budgets, ...result.budgets];
      await _cacheBudgets(merged);

      emit(
        current.copyWith(
          budgets: merged,
          hasMore: result.hasMore,
          currentPage: _currentPage,
        ),
      );
    } catch (e) {
      _currentPage--;
      emit(BudgetError(e.toString()));
      emit(current);
    }
  }

  // Refresh
  Future<void> _onRefresh(
    RefreshBudgets event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      _currentPage = 1;
      final result = await _getBudgets(page: _currentPage, limit: _pageSize);
      await _cacheBudgets(result.budgets);
      emit(
        BudgetLoaded(
          budgets: result.budgets,
          hasMore: result.hasMore,
          isOffline: false,
          currentPage: _currentPage,
        ),
      );
    } catch (_) {}
  }

  // Search
  Future<void> _onSearch(SearchBudgets event, Emitter<BudgetState> emit) async {
    final current = state;
    if (current is! BudgetLoaded) return;
    emit(current.copyWith(searchQuery: event.query));
  }

  // Budget Limit Update (Optimistic)
  Future<void> _onChangeLimit(
    ChangeBudgetLimit event,
    Emitter<BudgetState> emit,
  ) async {
    final current = state;
    if (current is! BudgetLoaded) return;

    final previousBudgets = List<Budget>.from(current.budgets);

    // emit the change immediately
    final optimistic = current.budgets.map((b) {
      return b.id == event.id ? b.copyWith(limit: event.newLimit) : b;
    }).toList();

    emit(current.copyWith(budgets: optimistic));

    try {
      // Network call to update limit on server and cache
      await _updateBudgetLimit(event.id, event.newLimit);
      await _cacheBudgets(optimistic);
    } catch (e) {
      // Rollback both cache and UI state
      await _cacheBudgets(previousBudgets);
      emit(current.copyWith(budgets: previousBudgets));
      emit(BudgetError('Could not update limit: ${e.toString()}'));
      emit(current.copyWith(budgets: previousBudgets));
    }
  }
}
