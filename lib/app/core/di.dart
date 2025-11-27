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
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_bloc.dart';
import 'package:fitness/app/chat/data/datasources/chat_remote_datasource.dart';
import 'package:fitness/app/chat/data/repositories/chat_repository_impl.dart';
import 'package:fitness/app/chat/domain/repositories/chat_repository.dart';
import 'package:fitness/app/chat/domain/usecases/connect_chat_usecase.dart';
import 'package:fitness/app/chat/domain/usecases/disconnect_chat_usecase.dart';
import 'package:fitness/app/chat/domain/usecases/send_message_usecase.dart';
import 'package:fitness/app/chat/presentation/bloc/chat_bloc.dart';
import 'package:fitness/app/api/data/datasources/exercise_remote_datasource.dart';
import 'package:fitness/app/api/data/datasources/youtube_remote_datasource.dart';
import 'package:fitness/app/api/data/repositories/exercise_repository_impl.dart';
import 'package:fitness/app/api/data/repositories/youtube_repository_impl.dart';
import 'package:fitness/app/api/domain/repositories/exercise_repository.dart';
import 'package:fitness/app/api/domain/repositories/youtube_repository.dart';
import 'package:fitness/app/api/domain/usecases/search_exercises_usecase.dart';
import 'package:fitness/app/api/domain/usecases/get_exercise_by_id_usecase.dart';
import 'package:fitness/app/api/domain/usecases/search_youtube_videos_usecase.dart';
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

  // --- Fitness Bloc ---
  sl.registerFactory(
    () => FitnessBloc(
      getAllFitnessPlansUsecase: sl(),
    ),
  );

  // --- Chat Data source ---
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(),
  );

  // --- Chat Repository ---
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl()),
  );

  // --- Chat Use cases ---
  sl.registerLazySingleton(() => ConnectChatUsecase(sl()));
  sl.registerLazySingleton(() => DisconnectChatUsecase(sl()));
  sl.registerLazySingleton(() => SendMessageUsecase(sl()));

  // --- Chat Bloc ---
  sl.registerFactory(
    () => ChatBloc(
      connectChatUsecase: sl(),
      disconnectChatUsecase: sl(),
      sendMessageUsecase: sl(),
      chatRepository: sl(),
    ),
  );

  // --- Exercise API Data sources ---
  sl.registerLazySingleton<ExerciseRemoteDataSource>(
    () => ExerciseRemoteDataSourceImpl(),
  );

  // --- Exercise API Repository ---
  sl.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepositoryImpl(remoteDataSource: sl()),
  );

  // --- Exercise API Use cases ---
  sl.registerLazySingleton(() => SearchExercisesUsecase(sl()));
  sl.registerLazySingleton(() => GetExerciseByIdUsecase(sl()));

  // --- YouTube API Data sources ---
  sl.registerLazySingleton<YouTubeRemoteDataSource>(
    () => YouTubeRemoteDataSourceImpl(),
  );

  // --- YouTube API Repository ---
  sl.registerLazySingleton<YouTubeRepository>(
    () => YouTubeRepositoryImpl(remoteDataSource: sl()),
  );

  // --- YouTube API Use cases ---
  sl.registerLazySingleton(() => SearchYouTubeVideosUsecase(sl()));
}
