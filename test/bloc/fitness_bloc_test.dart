import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_bloc.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_event.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_state.dart';
import 'package:fitness/app/storage/domain/usecases/get_all_fitness_plans_usecase.dart';
import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import '../helpers/test_helpers.dart';

class MockGetAllFitnessPlansUsecase extends Mock implements GetAllFitnessPlansUsecase {}

void main() {
  late FitnessBloc fitnessBloc;
  late MockGetAllFitnessPlansUsecase mockGetAllFitnessPlansUsecase;

  setUp(() {
    mockGetAllFitnessPlansUsecase = MockGetAllFitnessPlansUsecase();
    fitnessBloc = FitnessBloc(
      getAllFitnessPlansUsecase: mockGetAllFitnessPlansUsecase,
    );
  });

  tearDown(() {
    fitnessBloc.close();
  });

  test('initial state should be FitnessInitial', () {
    expect(fitnessBloc.state, equals(FitnessInitial()));
  });

  blocTest<FitnessBloc, FitnessState>(
    'emits [FitnessLoading, FitnessLoaded] when LoadFitnessPlans succeeds',
    build: () {
      when(mockGetAllFitnessPlansUsecase())
          .thenAnswer((_) async => [TestFixtures.getTestStoredFitnessPlan()]);
      return fitnessBloc;
    },
    act: (bloc) => bloc.add(LoadFitnessPlans()),
    expect: () => [
      FitnessLoading(),
      isA<FitnessLoaded>(),
    ],
    verify: (_) {
      verify(mockGetAllFitnessPlansUsecase()).called(1);
    },
  );

  blocTest<FitnessBloc, FitnessState>(
    'emits [FitnessLoading, FitnessError] when LoadFitnessPlans fails',
    build: () {
      when(mockGetAllFitnessPlansUsecase())
          .thenThrow(Exception('Failed to load plans'));
      return fitnessBloc;
    },
    act: (bloc) => bloc.add(LoadFitnessPlans()),
    expect: () => [
      FitnessLoading(),
      FitnessError('Exception: Failed to load plans'),
    ],
  );

  blocTest<FitnessBloc, FitnessState>(
    'updates selectedDate when DateSelected is added',
    build: () {
      when(mockGetAllFitnessPlansUsecase())
          .thenAnswer((_) async => [TestFixtures.getTestStoredFitnessPlan()]);
      return fitnessBloc;
    },
    act: (bloc) {
      bloc.add(LoadFitnessPlans());
      final testDate = DateTime(2024, 1, 15);
      bloc.add(DateSelected(testDate));
    },
    expect: () => [
      FitnessLoading(),
      isA<FitnessLoaded>(),
      isA<FitnessLoaded>(),
    ],
    verify: (bloc) {
      final state = bloc.state as FitnessLoaded;
      expect(state.selectedDate, equals(DateTime(2024, 1, 15)));
    },
  );
}

