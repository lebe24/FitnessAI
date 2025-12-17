import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_bloc.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_event.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_state.dart';
import 'package:fitness/app/ui/nutrition/domain/usecases/analyze_food_usecase.dart';
import 'package:fitness/app/ui/nutrition/domain/usecases/save_nutrition_analysis_usecase.dart';
import 'package:fitness/app/ui/nutrition/domain/usecases/get_all_nutrition_analyses_usecase.dart';
import 'package:fitness/app/ui/nutrition/domain/usecases/get_nutrition_analysis_by_id_usecase.dart';
import 'package:fitness/app/ui/nutrition/domain/usecases/delete_nutrition_analysis_usecase.dart';
import 'package:fitness/app/ui/nutrition/domain/entities/nutrition_analysis_entity.dart';

class MockAnalyzeFoodUseCase extends Mock implements AnalyzeFoodUseCase {}
class MockSaveNutritionAnalysisUseCase extends Mock implements SaveNutritionAnalysisUseCase {}
class MockGetAllNutritionAnalysesUseCase extends Mock implements GetAllNutritionAnalysesUseCase {}
class MockGetNutritionAnalysisByIdUseCase extends Mock implements GetNutritionAnalysisByIdUseCase {}
class MockDeleteNutritionAnalysisUseCase extends Mock implements DeleteNutritionAnalysisUseCase {}

void main() {
  late NutritionBloc nutritionBloc;
  late MockAnalyzeFoodUseCase mockAnalyzeFoodUseCase;
  late MockSaveNutritionAnalysisUseCase mockSaveNutritionAnalysisUseCase;
  late MockGetAllNutritionAnalysesUseCase mockGetAllNutritionAnalysesUseCase;
  late MockGetNutritionAnalysisByIdUseCase mockGetNutritionAnalysisByIdUseCase;
  late MockDeleteNutritionAnalysisUseCase mockDeleteNutritionAnalysisUseCase;

  setUp(() {
    mockAnalyzeFoodUseCase = MockAnalyzeFoodUseCase();
    mockSaveNutritionAnalysisUseCase = MockSaveNutritionAnalysisUseCase();
    mockGetAllNutritionAnalysesUseCase = MockGetAllNutritionAnalysesUseCase();
    mockGetNutritionAnalysisByIdUseCase = MockGetNutritionAnalysisByIdUseCase();
    mockDeleteNutritionAnalysisUseCase = MockDeleteNutritionAnalysisUseCase();

    nutritionBloc = NutritionBloc(
      analyzeFoodUseCase: mockAnalyzeFoodUseCase,
      saveNutritionAnalysisUseCase: mockSaveNutritionAnalysisUseCase,
      getAllNutritionAnalysesUseCase: mockGetAllNutritionAnalysesUseCase,
      getNutritionAnalysisByIdUseCase: mockGetNutritionAnalysisByIdUseCase,
      deleteNutritionAnalysisUseCase: mockDeleteNutritionAnalysisUseCase,
    );
  });

  tearDown(() {
    nutritionBloc.close();
  });

  test('initial state should be NutritionInitial', () {
    expect(nutritionBloc.state, equals(NutritionInitial()));
  });

  blocTest<NutritionBloc, NutritionState>(
    'emits [NutritionLoading, NutritionAnalysisLoaded] when AnalyzeFoodRequested succeeds',
    build: () {
      final testAnalysis = NutritionAnalysisEntity(
        dishName: 'Apple',
        identifiedIngredients: ['apple'],
        portionEstimates: const PortionEstimates(),
        estimatedNutrition: EstimatedNutrition(
          caloriesKcal: 95,
          macros: Macros(
            proteinG: 0.5,
            carbsG: 25.0,
            fatG: 0.3,
            fiberG: 4.0,
          ),
        ),
        macroEstimates: MacroEstimates(
          protein: MacroDetail(grams: 0.5, percentage: 2.0, calories: 2.0),
          carbohydrates: MacroDetail(grams: 25.0, percentage: 95.0, calories: 100.0),
          fats: Fats(grams: 0.3, percentage: 3.0, calories: 3.0),
          fiber: Fiber(grams: 4.0, percentage: 16.0),
        ),
        micronutrientsEstimate: MicronutrientsEstimate(
          vitamins: const Vitamins(),
          minerals: const Minerals(),
          antioxidants: [],
        ),
        dietarySafetyConstraints: DietarySafetyConstraints(
          allergens: [],
          dietaryRestrictions: const DietaryRestrictions(
            glutenFree: true,
            vegan: true,
            vegetarian: true,
            halal: true,
            kosher: true,
            dairyFree: true,
            nutFree: true,
          ),
          safetyConcerns: [],
          foodSafety: FoodSafety(
            temperatureConcern: false,
            crossContaminationRisk: 'low',
            storageAdvice: 'Store in cool place',
          ),
        ),
        nutrientHighlights: NutrientHighlights(
          positive: [],
          moderate: [],
          allergens: [],
        ),
        workoutContext: WorkoutContext(
          postWorkoutRecommended: true,
          why: ['Good carbs'],
          bestTimingHoursAfterWorkout: '1-2 hours',
          ifNoWorkout: IfNoWorkout(suggestions: ['Eat in moderation']),
        ),
        healthinessScore: 8.5,
        overallRating: 'Good',
        notes: ['Healthy snack'],
        imageUrl: '/path/to/image.jpg',
      );
      when(mockAnalyzeFoodUseCase(
        image: anyNamed('image'),
        goal: anyNamed('goal'),
        gender: anyNamed('gender'),
        height: anyNamed('height'),
        weight: anyNamed('weight'),
        experience: anyNamed('experience'),
        extraInfo: anyNamed('extraInfo'),
      )).thenAnswer((_) async => testAnalysis);
      return nutritionBloc;
    },
    act: (bloc) => bloc.add(AnalyzeFoodRequested(
      image: File('/test/image.jpg'),
      goal: 'weight loss',
      gender: 'male',
      height: '180',
      weight: '75',
      experience: 'beginner',
      extraInfo: 'test',
    )),
    expect: () => [
      NutritionLoading(),
      isA<NutritionAnalysisLoaded>(),
    ],
  );

  blocTest<NutritionBloc, NutritionState>(
    'emits NutritionError when AnalyzeFoodRequested fails',
    build: () {
      when(mockAnalyzeFoodUseCase(
        image: anyNamed('image'),
        goal: anyNamed('goal'),
        gender: anyNamed('gender'),
        height: anyNamed('height'),
        weight: anyNamed('weight'),
        experience: anyNamed('experience'),
        extraInfo: anyNamed('extraInfo'),
      )).thenThrow(Exception('Analysis failed'));
      return nutritionBloc;
    },
    act: (bloc) => bloc.add(AnalyzeFoodRequested(
      image: File('/test/image.jpg'),
    )),
    expect: () => [
      NutritionLoading(),
      NutritionError('Exception: Analysis failed'),
    ],
  );

  blocTest<NutritionBloc, NutritionState>(
    'emits NutritionAnalysisSaved when SaveNutritionAnalysisRequested succeeds',
    build: () {
      final testAnalysis = NutritionAnalysisEntity(
        id: 'analysis-1',
        foodName: 'Apple',
        calories: 95,
        protein: 0.5,
        carbs: 25.0,
        fat: 0.3,
        fiber: 4.0,
        sugar: 19.0,
        imagePath: '/path/to/image.jpg',
        analyzedAt: DateTime.now(),
      );
      when(mockSaveNutritionAnalysisUseCase(any))
          .thenAnswer((_) async => {});
      return nutritionBloc;
    },
    act: (bloc) {
      final testAnalysis = NutritionAnalysisEntity(
        dishName: 'Apple',
        identifiedIngredients: ['apple'],
        portionEstimates: const PortionEstimates(),
        estimatedNutrition: EstimatedNutrition(
          caloriesKcal: 95,
          macros: Macros(
            proteinG: 0.5,
            carbsG: 25.0,
            fatG: 0.3,
            fiberG: 4.0,
          ),
        ),
        macroEstimates: MacroEstimates(
          protein: MacroDetail(grams: 0.5, percentage: 2.0, calories: 2.0),
          carbohydrates: MacroDetail(grams: 25.0, percentage: 95.0, calories: 100.0),
          fats: Fats(grams: 0.3, percentage: 3.0, calories: 3.0),
          fiber: Fiber(grams: 4.0, percentage: 16.0),
        ),
        micronutrientsEstimate: MicronutrientsEstimate(
          vitamins: const Vitamins(),
          minerals: const Minerals(),
          antioxidants: [],
        ),
        dietarySafetyConstraints: DietarySafetyConstraints(
          allergens: [],
          dietaryRestrictions: const DietaryRestrictions(
            glutenFree: true,
            vegan: true,
            vegetarian: true,
            halal: true,
            kosher: true,
            dairyFree: true,
            nutFree: true,
          ),
          safetyConcerns: [],
          foodSafety: FoodSafety(
            temperatureConcern: false,
            crossContaminationRisk: 'low',
            storageAdvice: 'Store in cool place',
          ),
        ),
        nutrientHighlights: NutrientHighlights(
          positive: [],
          moderate: [],
          allergens: [],
        ),
        workoutContext: WorkoutContext(
          postWorkoutRecommended: true,
          why: ['Good carbs'],
          bestTimingHoursAfterWorkout: '1-2 hours',
          ifNoWorkout: IfNoWorkout(suggestions: ['Eat in moderation']),
        ),
        healthinessScore: 8.5,
        overallRating: 'Good',
        notes: ['Healthy snack'],
        imageUrl: '/path/to/image.jpg',
      );
      bloc.add(SaveNutritionAnalysisRequested(testAnalysis));
    },
    expect: () => [
      const NutritionAnalysisSaved(),
    ],
  );

  blocTest<NutritionBloc, NutritionState>(
    'emits AllNutritionAnalysesLoaded when GetAllNutritionAnalysesRequested succeeds',
    build: () {
      when(mockGetAllNutritionAnalysesUseCase())
          .thenAnswer((_) async => []);
      return nutritionBloc;
    },
    act: (bloc) => bloc.add(GetAllNutritionAnalysesRequested()),
    expect: () => [
      isA<AllNutritionAnalysesLoaded>(),
    ],
  );
}

