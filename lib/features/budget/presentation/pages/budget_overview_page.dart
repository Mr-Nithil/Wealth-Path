import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wealthpath/core/injection/injection_container.dart';
import 'package:wealthpath/features/budget/domain/entities/budget.dart';
import 'package:wealthpath/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:wealthpath/features/budget/presentation/widgets/budget_search_bar.dart';
import 'package:wealthpath/features/budget/presentation/widgets/category_budget_card.dart';
import 'package:wealthpath/features/budget/presentation/widgets/offline_banner.dart';
import 'package:wealthpath/features/budget/presentation/widgets/update_budget_limit_modal.dart';

class BudgetOverviewPage extends StatelessWidget {
  const BudgetOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BudgetBloc>()..add(const LoadBudgets()),
      child: const _BudgetOverviewView(),
    );
  }
}

class _BudgetOverviewView extends StatefulWidget {
  const _BudgetOverviewView();

  @override
  State<_BudgetOverviewView> createState() => _BudgetOverviewViewState();
}

class _BudgetOverviewViewState extends State<_BudgetOverviewView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _showOfflineBanner = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<BudgetBloc>().add(const LoadMoreBudgets());
    }
  }

  // Debounced Search
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<BudgetBloc>().add(SearchBudgets(query));
    });
  }

  void _onSearchCleared() {
    _searchController.clear();
    _debounce?.cancel();
    context.read<BudgetBloc>().add(SearchBudgets(''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0D1117),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Budget Overview',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF1F6FEB)),
              onPressed: () {
                context.read<BudgetBloc>().add(const RefreshBudgets());
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BudgetBloc, BudgetState>(
            listenWhen: (_, current) => current is BudgetError,
            listener: (context, state) {
              if (state is BudgetError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: const Color(0xFFDA3633),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          BlocListener<BudgetBloc, BudgetState>(
            listenWhen: (previous, current) {
              if (previous is BudgetLoaded && current is BudgetLoaded) {
                return previous.isOffline != current.isOffline;
              }
              return current is BudgetLoaded;
            },
            listener: (context, state) {
              if (state is BudgetLoaded && state.isOffline) {
                setState(() => _showOfflineBanner = true);
              }
            },
          ),
        ],

        child: BlocBuilder<BudgetBloc, BudgetState>(
          builder: (context, state) {
            if (state is BudgetLoading) {
              return const Center(child: Text("Loading budgets..."));
            }

            if (state is BudgetLoaded) {
              return _LoadedBody(
                state: state,
                scrollController: _scrollController,
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onSearchCleared: _onSearchCleared,
                showOfflineBanner: _showOfflineBanner,
                onDismissOfflineBanner: () {
                  setState(() => _showOfflineBanner = false);
                },
              );
            }

            if (state is BudgetError) {
              return _ErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<BudgetBloc>().add(const LoadBudgets()),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final BudgetLoaded state;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final bool showOfflineBanner;
  final VoidCallback onDismissOfflineBanner;

  const _LoadedBody({
    required this.state,
    required this.scrollController,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.showOfflineBanner,
    required this.onDismissOfflineBanner,
  });

  void _showEditBottomSheet(BuildContext context, Budget budget) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<BudgetBloc>(),
        child: UpdateBudgetLimitModal(budget: budget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgets = state.filteredBudgets;

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<BudgetBloc>().add(const RefreshBudgets()),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          if (state.isOffline && showOfflineBanner)
            SliverToBoxAdapter(
              child: OfflineBanner(onDismiss: onDismissOfflineBanner),
            ),

          SliverToBoxAdapter(
            child: BudgetSearchBar(
              controller: searchController,
              onChanged: onSearchChanged,
              onClear: onSearchCleared,
            ),
          ),

          if (budgets.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No categories found',
                  style: TextStyle(color: Color(0xFF8B949E)),
                ),
              ),
            )
          else ...[
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final budget = budgets[index];
                return CategoryBudgetCard(
                  budget: budget,
                  onEditTap: () => _showEditBottomSheet(context, budget),
                );
              }, childCount: budgets.length),
            ),

            if (state.hasMore && state.searchQuery.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text("Loading more budgets...")),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Color(0xFF8B949E), size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8B949E)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size(100, 20)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
