import 'package:get_it/get_it.dart';
import 'package:wealthpath/core/network/dio_client.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  _initCore();
}

void _initCore() {
  sl.registerLazySingleton<DioClient>(() => DioClient());
}
