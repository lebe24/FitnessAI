import 'package:mockito/annotations.dart';
import 'package:fitness/app/storage/data/datasources/file_storage_datasource.dart';
import 'package:fitness/app/storage/data/datasources/local_storage_datasource.dart';
import 'package:fitness/app/ui/nutrition/data/datasources/nutrition_local_datasource.dart';
import 'package:fitness/app/ui/nutrition/data/datasources/nutrition_remote_datasource.dart';
import 'package:fitness/app/ui/profile/data/datasources/profile_local_datasource.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([
  LocalStorageDataSource,
  FileStorageDataSource,
  NutritionLocalDataSource,
  NutritionRemoteDataSource,
  ProfileLocalDataSource,
])
void main() {}

