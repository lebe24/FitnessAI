# Unit Tests for Fitness AI Application

This directory contains comprehensive unit tests for the entire Fitness AI application.

## Test Structure

```
test/
├── helpers/
│   ├── test_helpers.dart          # Test fixtures and helper functions
│   ├── mock_repositories.dart      # Mock repository classes
│   └── mock_datasources.dart       # Mock data source classes
├── usecases/
│   ├── api/                        # API use case tests
│   ├── auth/                       # Authentication use case tests
│   ├── chat/                       # Chat use case tests
│   ├── storage/                    # Storage use case tests
│   └── nutrition/                 # Nutrition use case tests
├── bloc/                           # BLoC tests
│   ├── auth_bloc_test.dart
│   ├── chat_bloc_test.dart
│   ├── fitness_bloc_test.dart
│   └── nutrition_bloc_test.dart
├── repositories/                   # Repository implementation tests
│   ├── storage_repository_impl_test.dart
│   └── exercise_repository_impl_test.dart
└── main_test.dart                  # Main app widget test
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/usecases/auth/sign_in_google_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
```

### Generate coverage report
```bash
genhtml coverage/lcov.info -o coverage/html
```

## Test Coverage

### Use Cases (24 total)
- ✅ Authentication: SignInWithGoogle, SignInWithGmail, SignOut, GetCurrentUser, DeleteAccount
- ✅ Storage: SaveFitnessPlan, GetAllFitnessPlans, GetFitnessPlanById, DeleteFitnessPlan, UpdateSyncStatus, GetUnsyncedPlans
- ✅ API: SearchExercises, GetExerciseById, SearchYouTubeVideos
- ✅ Chat: ConnectChat, DisconnectChat, SendMessage
- ⏳ Nutrition: AnalyzeFood, SaveNutritionAnalysis, GetAllNutritionAnalyses, GetNutritionAnalysisById, DeleteNutritionAnalysis
- ⏳ Fitness: GetUserStreak, UpdateWorkoutCompletion, GetCompletedDates, GetUserData
- ⏳ Home: UploadImage, GetBaseInfo
- ⏳ Profile: GetProfile

### BLoCs (7 total)
- ✅ AuthBloc
- ✅ FitnessBloc
- ✅ NutritionBloc
- ⏳ ChatBloc
- ⏳ UploadBloc
- ⏳ ProfileBloc
- ⏳ OnboardingBloc

### Repositories (9 total)
- ✅ StorageRepositoryImpl
- ✅ ExerciseRepositoryImpl
- ⏳ YouTubeRepositoryImpl
- ⏳ ChatRepositoryImpl
- ⏳ AuthRepositoryImpl
- ⏳ UserDataRepositoryImpl
- ⏳ HomeRepositoryImpl
- ⏳ NutritionRepositoryImpl
- ⏳ ProfileRepositoryImpl

## Test Dependencies

The following packages are used for testing:

- `flutter_test` - Core Flutter testing framework
- `mockito` - Mocking framework for creating test doubles
- `bloc_test` - Testing utilities for BLoC pattern
- `build_runner` - Code generation for mocks

## Generating Mocks

To generate mock classes, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Writing New Tests

### Use Case Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/.../usecase.dart';
import 'package:fitness/app/.../repository.dart';
import '../../helpers/test_helpers.dart';

class MockRepository extends Mock implements Repository {}

void main() {
  late UseCase usecase;
  late MockRepository mockRepository;

  setUp(() {
    mockRepository = MockRepository();
    usecase = UseCase(mockRepository);
  });

  test('should perform action successfully', () async {
    // arrange
    when(mockRepository.method()).thenAnswer((_) async => result);

    // act
    final result = await usecase();

    // assert
    expect(result, equals(expected));
    verify(mockRepository.method()).called(1);
  });
}
```

### BLoC Test Template

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/.../bloc.dart';

void main() {
  late Bloc bloc;
  late MockUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockUseCase();
    bloc = Bloc(useCase: mockUseCase);
  });

  tearDown(() {
    bloc.close();
  });

  blocTest<Bloc, State>(
    'emits [Loading, Loaded] when event succeeds',
    build: () {
      when(mockUseCase()).thenAnswer((_) async => result);
      return bloc;
    },
    act: (bloc) => bloc.add(Event()),
    expect: () => [
      Loading(),
      Loaded(result),
    ],
  );
}
```

## Best Practices

1. **Arrange-Act-Assert Pattern**: Always structure tests with clear arrange, act, and assert sections
2. **Test Isolation**: Each test should be independent and not rely on other tests
3. **Mock External Dependencies**: Always mock repositories, data sources, and external services
4. **Test Edge Cases**: Include tests for null values, empty lists, and error scenarios
5. **Meaningful Test Names**: Use descriptive test names that explain what is being tested
6. **Verify Interactions**: Use `verify()` to ensure methods are called with correct parameters
7. **Clean Up**: Always close BLoCs in `tearDown()` to prevent memory leaks

## Notes

- Tests marked with ⏳ are pending implementation
- Tests marked with ✅ are completed
- Some tests may require additional setup (e.g., Hive initialization for storage tests)
- Integration tests should be added separately for end-to-end testing

