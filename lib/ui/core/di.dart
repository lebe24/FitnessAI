import 'package:fitness/data/repositories/auth_repository_impl.dart';
import 'package:fitness/data/repositories/workout_log_repository_impl.dart';
import 'package:fitness/data/services/workout_log/workout_log_remote_service.dart';
import 'package:fitness/domain/repositories/workout_log_repository.dart';
import 'package:fitness/ui/features/fitness/view_models/workout_log_view_model.dart';
import 'package:fitness/data/repositories/chat_repository_impl.dart';
import 'package:fitness/data/repositories/exercise_repository_impl.dart';
import 'package:fitness/data/repositories/home_repository_impl.dart';
import 'package:fitness/data/repositories/nutrition_repository_impl.dart';
import 'package:fitness/data/repositories/profile_repository_impl.dart';
import 'package:fitness/data/repositories/storage_repository_impl.dart';
import 'package:fitness/data/repositories/user_data_repository_impl.dart';
import 'package:fitness/data/repositories/youtube_repository_impl.dart';
import 'package:fitness/data/services/api/agent_remote_service.dart';
import 'package:fitness/data/services/api/exercise_remote_service.dart';
import 'package:fitness/data/services/api/supabase_remote_service.dart';
import 'package:fitness/data/services/api/youtube_remote_service.dart';
import 'package:fitness/data/services/auth/auth_remote_service.dart';
import 'package:fitness/data/services/chat/agent_ws_service.dart';
import 'package:fitness/data/services/chat/chat_remote_service.dart';
import 'package:fitness/data/services/workout_plan/workout_plan_remote_service.dart';
import 'package:fitness/data/services/nutrition/nutrition_local_service.dart';
import 'package:fitness/data/services/nutrition/nutrition_remote_service.dart';
import 'package:fitness/data/services/profile/profile_local_service.dart';
import 'package:fitness/data/services/profile/profile_remote_service.dart';
import 'package:fitness/data/services/storage/file_storage_service.dart';
import 'package:fitness/data/services/storage/local_storage_service.dart';
import 'package:fitness/data/services/storage/storage_init.dart';
import 'package:fitness/data/services/storage/workout_plan_sync_service.dart';
import 'package:fitness/ui/core/locale/locale_provider.dart';
import 'package:fitness/domain/repositories/auth_repository.dart';
import 'package:fitness/domain/repositories/exercise_repository.dart';
import 'package:fitness/domain/repositories/home_repository.dart';
import 'package:fitness/domain/repositories/nutrition_repository.dart';
import 'package:fitness/domain/repositories/profile_repository.dart';
import 'package:fitness/domain/repositories/storage_repository.dart';
import 'package:fitness/domain/repositories/user_data_repository.dart';
import 'package:fitness/domain/repositories/youtube_repository.dart';
import 'package:fitness/domain/use_cases/auth/delete_account.dart';
import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/domain/use_cases/auth/sign_in_gmail.dart';
import 'package:fitness/domain/use_cases/auth/sign_in_google.dart';
import 'package:fitness/domain/use_cases/auth/sign_out.dart';
import 'package:fitness/domain/use_cases/chat/connect_chat_usecase.dart';
import 'package:fitness/domain/use_cases/chat/disconnect_chat_usecase.dart';
import 'package:fitness/domain/use_cases/chat/send_message_usecase.dart';
import 'package:fitness/domain/use_cases/exercise/get_exercise_by_id_usecase.dart';
import 'package:fitness/domain/use_cases/exercise/search_exercises_usecase.dart';
import 'package:fitness/domain/use_cases/exercise/search_youtube_videos_usecase.dart';
import 'package:fitness/domain/use_cases/fitness/get_completed_dates_usecase.dart';
import 'package:fitness/domain/use_cases/fitness/get_user_data_usecase.dart';
import 'package:fitness/domain/use_cases/fitness/get_user_streak_usecase.dart';
import 'package:fitness/domain/use_cases/fitness/update_workout_completion_usecase.dart';
import 'package:fitness/domain/use_cases/home/get_base_info_usecase.dart';
import 'package:fitness/domain/use_cases/home/upload_image_usecase.dart';
import 'package:fitness/domain/use_cases/nutrition/analyze_food_usecase.dart';
import 'package:fitness/domain/use_cases/nutrition/delete_nutrition_analysis_usecase.dart';
import 'package:fitness/domain/use_cases/nutrition/get_all_nutrition_analyses_usecase.dart';
import 'package:fitness/domain/use_cases/nutrition/get_nutrition_analysis_by_id_usecase.dart';
import 'package:fitness/domain/use_cases/nutrition/save_nutrition_analysis_usecase.dart';
import 'package:fitness/domain/use_cases/profile/get_profile_usecase.dart';
import 'package:fitness/domain/use_cases/storage/delete_fitness_plan_usecase.dart';
import 'package:fitness/domain/use_cases/storage/get_all_fitness_plans_usecase.dart';
import 'package:fitness/domain/use_cases/storage/get_fitness_plan_by_id_usecase.dart';
import 'package:fitness/domain/use_cases/storage/get_unsynced_plans_usecase.dart';
import 'package:fitness/domain/use_cases/storage/save_fitness_plan_usecase.dart';
import 'package:fitness/domain/use_cases/storage/update_fitness_plan_usecase.dart';
import 'package:fitness/domain/use_cases/storage/update_sync_status_usecase.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:fitness/ui/features/auth/view_models/auth_view_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fitness/ui/features/chat/view_models/chat_view_model.dart';
import 'package:fitness/ui/features/fitness/view_models/fitness_view_model.dart';
import 'package:fitness/data/services/billing/subscription_service.dart';
import 'package:fitness/ui/features/home/view_models/upload_view_model.dart';
import 'package:fitness/ui/features/nutrition/view_models/nutrition_view_model.dart';
import 'package:fitness/ui/features/profile/view_models/profile_view_model.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  await initializeStorage();

  // ── Localization ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<LocaleProvider>(() => LocaleProvider());
  await sl<LocaleProvider>().loadSaved();

  // ── Billing (RevenueCat) ──────────────────────────────────────────────────
  // Configured lazily from the billing page with the signed-in user's id;
  // no-ops gracefully when REVENUECAT_IOS_API_KEY is absent from .env.
  sl.registerLazySingleton<SubscriptionService>(() => SubscriptionService());

  // Generate a one-time nonce for Google Sign-In → Supabase ID-token exchange.
  // GIDSignIn 9.x embeds the nonce hash in the ID token; Supabase verifies by
  // re-hashing the raw nonce we pass to signInWithIdToken().
  final rawNonce = List.generate(
    32,
    (_) => '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'[
        Random.secure().nextInt(62)],
  ).join();
  final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

  sl.registerLazySingleton<String>(() => rawNonce, instanceName: 'googleNonce');

  await GoogleSignIn.instance.initialize(
    clientId: Platform.isAndroid ? Constant.oauthAndroidClient : Constant.iosClient,
    serverClientId: Constant.oauthWebClient,
    nonce: hashedNonce,
  );

  await Supabase.initialize(
    url: Constant.supabaseUrl.toString(),
    anonKey: Constant.supabaseAnonKey.toString(),
  );

  sl.registerLazySingleton(() => Supabase.instance.client);

  // ── Auth ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl(), sl()),
  );
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignInWithGmail(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => DeleteAccount(sl()));
  sl.registerFactory(() => AuthViewModel(
        signInWithGoogle: sl(),
        signInWithGmail: sl(),
        signOut: sl(),
        getCurrentUser: sl(),
        deleteAccount: sl(),
      ));

  // ── Home ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<WorkoutPlanRemoteDataSource>(
    () => WorkoutPlanRemoteDataSource(),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => UploadImageUseCase(sl()));
  sl.registerLazySingleton(() => GetBaseInfoUseCase(sl()));
  sl.registerFactory(() => UploadViewModel(
        uploadImageUseCase: sl(),
        getBaseInfoUseCase: sl(),
      ));

  // ── Storage ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<LocalStorageDataSource>(
    () => LocalStorageDataSourceImpl(),
  );
  sl.registerLazySingleton<FileStorageDataSource>(
    () => FileStorageDataSourceImpl(),
  );
  sl.registerLazySingleton<WorkoutPlanSyncDataSource>(
    () => WorkoutPlanSyncDataSourceImpl(),
  );
  sl.registerLazySingleton<StorageRepository>(
    () => StorageRepositoryImpl(
      localDataSource: sl(),
      fileDataSource: sl(),
      syncDataSource: sl(),
    ),
  );
  sl.registerLazySingleton(() => SaveFitnessPlanUsecase(sl()));
  sl.registerLazySingleton(() => GetAllFitnessPlansUsecase(sl()));
  sl.registerLazySingleton(() => GetFitnessPlanByIdUsecase(sl()));
  sl.registerLazySingleton(() => DeleteFitnessPlanUsecase(sl()));
  sl.registerLazySingleton(() => UpdateFitnessPlanUsecase(sl()));
  sl.registerLazySingleton(() => UpdateSyncStatusUsecase(sl()));
  sl.registerLazySingleton(() => GetUnsyncedPlansUsecase(sl()));

  // ── Fitness user data ─────────────────────────────────────────────────────
  // Redirected to use WorkoutLogRemoteDataSource — the old `user_data`
  // Supabase table does not exist; session data lives in workout_sessions.
  sl.registerLazySingleton<UserDataRepository>(
    () => UserDataRepositoryImpl(sl<WorkoutLogRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => GetUserStreakUsecase(sl()));
  sl.registerLazySingleton(() => UpdateWorkoutCompletionUsecase(sl()));
  sl.registerLazySingleton(() => GetCompletedDatesUsecase(sl()));
  sl.registerLazySingleton(() => GetUserDataUsecase(sl()));
  sl.registerFactory(() => FitnessViewModel(
        getAllFitnessPlansUsecase: sl(),
        planSyncDataSource: sl(),
      ));

  // ── Chat ──────────────────────────────────────────────────────────────────
  // Each chat context gets its own WebSocket connection + repository.
  // 'onboarding' — goal-setting / plan-building chat (decide.dart → /chat route)
  // 'workout'    — in-session coach chat (fitness page modal, has workout plan)
  // 'agent'      — personalised agent using /ws/agent (loads user data from DB)

  ChatViewModel makeChatViewModel(String context) {
    final repo = ChatRepositoryImpl(remoteDataSource: ChatRemoteDataSourceImpl());
    return ChatViewModel(
      connectChatUsecase:    ConnectChatUsecase(repo),
      disconnectChatUsecase: DisconnectChatUsecase(repo),
      sendMessageUsecase:    SendMessageUsecase(repo),
      chatRepository:        repo,
      chatContext:           context,
    );
  }

  ChatViewModel makeAgentViewModel() {
    final repo = ChatRepositoryImpl(remoteDataSource: AgentWsDataSource());
    return ChatViewModel(
      connectChatUsecase:    ConnectChatUsecase(repo),
      disconnectChatUsecase: DisconnectChatUsecase(repo),
      sendMessageUsecase:    SendMessageUsecase(repo),
      chatRepository:        repo,
      chatContext:           'agent',
    );
  }

  sl.registerFactory<ChatViewModel>(
    () => makeChatViewModel('onboarding'),
    instanceName: 'onboarding',
  );
  sl.registerFactory<ChatViewModel>(
    () => makeChatViewModel('workout'),
    instanceName: 'workout',
  );
  sl.registerFactory<ChatViewModel>(
    () => makeAgentViewModel(),
    instanceName: 'agent',
  );

  // ── Exercise API ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseRemoteDataSource>(
    () => SupabaseRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<AgentRemoteDataSource>(
    () => AgentRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<ExerciseRemoteDataSource>(
    () => ExerciseRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => SearchExercisesUsecase(sl()));
  sl.registerLazySingleton(() => GetExerciseByIdUsecase(sl()));

  // ── YouTube API ───────────────────────────────────────────────────────────
  sl.registerLazySingleton<YouTubeRemoteDataSource>(
    () => YouTubeRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<YouTubeRepository>(
    () => YouTubeRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => SearchYouTubeVideosUsecase(sl()));

  // ── Nutrition ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<NutritionRemoteDataSource>(
    () => NutritionRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<NutritionLocalDataSource>(
    () => NutritionLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<NutritionRepository>(
    () => NutritionRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );
  sl.registerLazySingleton(() => AnalyzeFoodUseCase(sl()));
  sl.registerLazySingleton(() => SaveNutritionAnalysisUseCase(sl()));
  sl.registerLazySingleton(() => GetAllNutritionAnalysesUseCase(sl()));
  sl.registerLazySingleton(() => GetNutritionAnalysisByIdUseCase(sl()));
  sl.registerLazySingleton(() => DeleteNutritionAnalysisUseCase(sl()));
  sl.registerFactory(() => NutritionViewModel(
        analyzeFoodUseCase: sl(),
        saveNutritionAnalysisUseCase: sl(),
        getAllNutritionAnalysesUseCase: sl(),
        getNutritionAnalysisByIdUseCase: sl(),
        deleteNutritionAnalysisUseCase: sl(),
      ));

  // ── Workout Logs ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<WorkoutLogRemoteDataSource>(
    () => WorkoutLogRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<WorkoutLogRepository>(
    () => WorkoutLogRepositoryImpl(sl()),
  );
  sl.registerFactory(() => WorkoutLogViewModel(sl()));

  // ── Profile ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      getCurrentUser: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerFactory(() => ProfileViewModel(
        getProfileUseCase: sl(),
      ));
}
