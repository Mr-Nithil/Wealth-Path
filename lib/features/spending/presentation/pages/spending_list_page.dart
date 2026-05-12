import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wealthpath/features/spending/presentation/cubit/spending_cubit.dart';
import 'package:wealthpath/features/spending/presentation/widgets/add_spending_modal.dart';
import 'package:wealthpath/features/spending/presentation/widgets/spending_header_widget.dart';
import 'package:wealthpath/features/spending/presentation/widgets/spending_item_widget.dart';

class SpendingListPage extends StatefulWidget {
  const SpendingListPage({super.key});

  @override
  State<SpendingListPage> createState() => _SpendingListPageState();
}

class _SpendingListPageState extends State<SpendingListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SpendingCubit>().loadMore();
    }
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SpendingCubit>(),
        child: const AddSpendingModal(),
      ),
    );
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
        title: const Text('My Spending'),
        actions: [
          TextButton.icon(
            onPressed: _showAddModal,
            icon: const Icon(Icons.add, color: Color(0xFF238636)),
            label: const Text(
              'Add',
              style: TextStyle(color: Color(0xFF238636)),
            ),
          ),
        ],
      ),
      body: BlocConsumer<SpendingCubit, SpendingState>(
        listenWhen: (previous, current) =>
            current is SpendingError && previous != current,
        listener: (context, state) {
          if (state is SpendingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFDA3633),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SpendingLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF238636)),
            );
          }

          if (state is SpendingError && state.previousItems == null) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<SpendingCubit>().loadSpending(),
            );
          }

          final items = state is SpendingLoaded
              ? state.items
              : (state as SpendingError).previousItems ?? [];
          final total = state is SpendingLoaded
              ? state.total
              : (state as SpendingError).previousTotal ?? 0.0;
          final hasMore = state is SpendingLoaded ? state.hasMore : false;
          final isLoadingMore = state is SpendingLoaded
              ? state.isLoadingMore
              : false;

          if (items.isEmpty) {
            return const _EmptyState();
          }

          return Column(
            children: [
              SpendingHeaderWidget(total: total, count: items.length),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF238636),
                  onRefresh: () => context.read<SpendingCubit>().loadSpending(),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = items[index];
                          final isOptimistic = item.id.startsWith('temp_');
                          return SpendingItemWidget(
                            spending: item,
                            isOptimistic: isOptimistic,
                          );
                        }, childCount: items.length),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: isLoadingMore
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF238636),
                                    strokeWidth: 2,
                                  ),
                                )
                              : hasMore
                              ? TextButton(
                                  onPressed: () =>
                                      context.read<SpendingCubit>().loadMore(),
                                  child: const Text(
                                    'Load more',
                                    style: TextStyle(color: Color(0xFF238636)),
                                  ),
                                )
                              : const Text(
                                  'All records loaded',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF8B949E)),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFDA3633)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8B949E)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size(100, 20)),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFF8B949E)),
          SizedBox(height: 16),
          Text(
            'No spending records yet',
            style: TextStyle(color: Color(0xFF8B949E), fontSize: 16),
          ),
        ],
      ),
    );
  }
}
