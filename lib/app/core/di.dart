import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/core/constant/constant.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sl = GetIt.instance;

Future<void> initDI() async {

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
}
