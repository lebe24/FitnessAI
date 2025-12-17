import 'package:mockito/annotations.dart';
import 'package:fitness/app/api/domain/repositories/exercise_repository.dart';
import 'package:fitness/app/api/domain/repositories/youtube_repository.dart';
import 'package:fitness/app/chat/domain/repositories/chat_repository.dart';
import 'package:fitness/app/storage/domain/repositories/storage_repository.dart';
import 'package:fitness/app/ui/auth/domain/repositories/auth_repository.dart';
import 'package:fitness/app/ui/fitness/domain/repositories/user_data_repository.dart';
import 'package:fitness/app/ui/home/domain/repository/home_repository.dart';
import 'package:fitness/app/ui/nutrition/domain/repositories/nutrition_repository.dart';
import 'package:fitness/app/ui/profile/domain/repositories/profile_repository.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([
  AuthRepository,
  ExerciseRepository,
  YouTubeRepository,
  ChatRepository,
  StorageRepository,
  UserDataRepository,
  HomeRepository,
  NutritionRepository,
  ProfileRepository,
])
void main() {}

