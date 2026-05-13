import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wealthpath/core/constants/hive_contants.dart';
import 'package:wealthpath/core/network/dio_client.dart';
import 'package:wealthpath/features/budget/data/datasources/budget_local_data_source.dart';
import 'package:wealthpath/features/budget/data/datasources/budget_remote_datasource.dart';
import 'package:wealthpath/features/budget/data/models/budget_model.dart';
import 'package:wealthpath/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:wealthpath/features/budget/domain/repositories/budget_repository.dart';
import 'package:wealthpath/features/budget/domain/usecases/cache_budgets.dart';
import 'package:wealthpath/features/budget/domain/usecases/get_budgets.dart';
import 'package:wealthpath/features/budget/domain/usecases/get_cached_bugets.dart';
import 'package:wealthpath/features/budget/domain/usecases/update_budget_limit.dart';
import 'package:wealthpath/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:wealthpath/features/spending/data/datasources/spending_remote_data_source.dart';
import 'package:wealthpath/features/spending/data/repositories/spending_repository_impl.dart';
import 'package:wealthpath/features/spending/domain/repositories/spending_repository.dart';
import 'package:wealthpath/features/spending/domain/usecases/add_spending.dart';
import 'package:wealthpath/features/spending/domain/usecases/get_spending.dart';
import 'package:wealthpath/features/spending/presentation/cubit/spending_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await _initHive();

  _initCore();
  _initSpending();
  _initBudget();
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(BudgetModelAdapter());

  final budgetBox = await Hive.openBox<BudgetModel>(HiveConstants.budgetBox);
  sl.registerSingleton<Box>(budgetBox);
}

void _initCore() {
  sl.registerLazySingleton<DioClient>(() => DioClient());
}

void _initSpending() {
  sl.registerLazySingleton<SpendingRemoteDataSource>(
    () => SpendingRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<SpendingRepository>(
    () => SpendingRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetSpending(repository: sl()));

  sl.registerLazySingleton(() => AddSpending(repository: sl()));

  sl.registerFactory(() => SpendingCubit(getSpending: sl(), addSpending: sl()));
}

void _initBudget() {
  sl.registerLazySingleton<BudgetLocalDataSource>(
    () => BudgetLocalDataSourceImpl(budgetBox: sl()),
  );

  sl.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(localDataSource: sl(), remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetBudgets(repository: sl()));
  sl.registerLazySingleton(() => UpdateBudgetLimit(repository: sl()));
  sl.registerLazySingleton(() => GetCachedBudgets(repository: sl()));
  sl.registerLazySingleton(() => CacheBudgets(repository: sl()));

  sl.registerFactory(
    () => BudgetBloc(
      getBudgets: sl(),
      updateBudgetLimit: sl(),
      getCachedBudgets: sl(),
      cacheBudgets: sl(),
    ),
  );
}
