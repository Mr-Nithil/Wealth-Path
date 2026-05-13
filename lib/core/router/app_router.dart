import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wealthpath/core/injection/injection_container.dart';
import 'package:wealthpath/core/widgets/home_page.dart';
import 'package:wealthpath/features/budget/presentation/pages/budget_overview_page.dart';
import 'package:wealthpath/features/spending/presentation/cubit/spending_cubit.dart';
import 'package:wealthpath/features/spending/presentation/pages/spending_list_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/spending',
        name: 'spending',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => sl<SpendingCubit>()..loadSpending(),
            child: const SpendingListPage(),
          );
        },
      ),
      GoRoute(
        path: '/budget',
        name: 'budget',
        builder: (context, state) => const BudgetOverviewPage(),
      ),
    ],
  );
}
