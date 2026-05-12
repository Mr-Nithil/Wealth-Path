import 'package:get_it/get_it.dart';
import 'package:wealthpath/core/network/dio_client.dart';
import 'package:wealthpath/features/spending/data/datasources/spending_remote_data_source.dart';
import 'package:wealthpath/features/spending/data/repositories/spending_repository_impl.dart';
import 'package:wealthpath/features/spending/domain/repositories/spending_repository.dart';
import 'package:wealthpath/features/spending/domain/usecases/add_spending.dart';
import 'package:wealthpath/features/spending/domain/usecases/get_spending.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  _initCore();
  _initSpending();
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
}
