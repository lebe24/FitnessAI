import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/core/constant/constant.dart';
import 'package:fitness/app/storage/data/datasources/file_storage_datasource.dart';
import 'package:fitness/app/storage/data/datasources/local_storage_datasource.dart';
import 'package:fitness/app/storage/data/datasources/storage_init.dart';
import 'package:fitness/app/storage/data/repositories/storage_repository_impl.dart';
import 'package:fitness/app/storage/domain/repositories/storage_repository.dart';
import 'package:fitness/app/storage/domain/usecases/delete_fitness_plan_usecase.dart';
import 'package:fitness/app/storage/domain/usecases/get_all_fitness_plans_usecase.dart';
import 'package:fitness/app/storage/domain/usecases/get_fitness_plan_by_id_usecase.dart';
import 'package:fitness/app/storage/domain/usecases/get_unsynced_plans_usecase.dart';
import 'package:fitness/app/storage/domain/usecases/save_fitness_plan_usecase.dart';
import 'package:fitness/app/storage/domain/usecases/update_sync_status_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // --- Storage initialization ---
  await initializeStorage();

  // --- Supabase setup ---
  await Supabase.initialize(url: Constant.supabaseUrl.toString(), anonKey: Constant.supabaseAnonKey.toString() );

  sl.registerLazySingleton(() => Supabase.instance.client);

  // --- Auth Data source ---
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(),
  );

  // --- Auth Repository ---
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // --- Auth Use cases ---
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));

  // --- Auth Bloc ---
  sl.registerFactory(() => AuthBloc(
        signInWithGoogle: sl(),
        signOut: sl(),
        getCurrentUser: sl(),
      ));

  // --- Home Data source ---
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSource(),
  );

  // --- Home Repository ---
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(sl()),
  );

  // --- Home Use cases ---
  sl.registerLazySingleton(() => UploadImageUseCase(sl()));
  sl.registerLazySingleton(() => GetBaseInfoUseCase(sl()));

  // --- Upload Bloc ---
  sl.registerFactory(
    () => UploadBloc(
      uploadImageUseCase: sl(),
      getBaseInfoUseCase: sl(),
    ),
  );

  // --- Storage Data sources ---
  sl.registerLazySingleton<LocalStorageDataSource>(
    () => LocalStorageDataSourceImpl(),
  );
  sl.registerLazySingleton<FileStorageDataSource>(
    () => FileStorageDataSourceImpl(),
  );

  // --- Storage Repository ---
  sl.registerLazySingleton<StorageRepository>(
    () => StorageRepositoryImpl(
      localDataSource: sl(),
      fileDataSource: sl(),
    ),
  );

  // --- Storage Use cases ---
  sl.registerLazySingleton(() => SaveFitnessPlanUsecase(sl()));
  sl.registerLazySingleton(() => GetAllFitnessPlansUsecase(sl()));
  sl.registerLazySingleton(() => GetFitnessPlanByIdUsecase(sl()));
  sl.registerLazySingleton(() => DeleteFitnessPlanUsecase(sl()));
  sl.registerLazySingleton(() => UpdateSyncStatusUsecase(sl()));
  sl.registerLazySingleton(() => GetUnsyncedPlansUsecase(sl()));
}
