import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitness/app/ui/nutrition/domain/usecases/analyze_food_usecase.dart';
import 'package:fitness/app/ui/nutrition/domain/usecases/delete_nutrition_analysis_usecase.dart';
import 'package:fitness/app/ui/nutrition/domain/usecases/get_all_nutrition_analyses_usecase.dart';
import 'package:fitness/app/ui/nutrition/domain/usecases/get_nutrition_analysis_by_id_usecase.dart';
import 'package:fitness/app/ui/nutrition/domain/usecases/save_nutrition_analysis_usecase.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_event.dart';
import 'package:fitness/app/ui/nutrition/presentation/bloc/nutrition_state.dart';

class NutritionBloc extends Bloc<NutritionEvent, NutritionState> {
  final AnalyzeFoodUseCase analyzeFoodUseCase;
  final SaveNutritionAnalysisUseCase saveNutritionAnalysisUseCase;
  final GetAllNutritionAnalysesUseCase getAllNutritionAnalysesUseCase;
  final GetNutritionAnalysisByIdUseCase getNutritionAnalysisByIdUseCase;
  final DeleteNutritionAnalysisUseCase deleteNutritionAnalysisUseCase;

  NutritionBloc({
    required this.analyzeFoodUseCase,
    required this.saveNutritionAnalysisUseCase,
    required this.getAllNutritionAnalysesUseCase,
    required this.getNutritionAnalysisByIdUseCase,
    required this.deleteNutritionAnalysisUseCase,
  }) : super(NutritionInitial()) {
    on<AnalyzeFoodRequested>(_onAnalyzeFoodRequested);
    on<SaveNutritionAnalysisRequested>(_onSaveNutritionAnalysisRequested);
    on<GetAllNutritionAnalysesRequested>(_onGetAllNutritionAnalysesRequested);
    on<GetNutritionAnalysisByIdRequested>(_onGetNutritionAnalysisByIdRequested);
    on<DeleteNutritionAnalysisRequested>(_onDeleteNutritionAnalysisRequested);
  }

  Future<void> _onAnalyzeFoodRequested(
    AnalyzeFoodRequested event,
    Emitter<NutritionState> emit,
  ) async {
    emit(NutritionLoading());
    try {
      final analysis = await analyzeFoodUseCase(
        image: event.image,
        goal: event.goal,
        gender: event.gender,
        height: event.height,
        weight: event.weight,
        experience: event.experience,
        extraInfo: event.extraInfo,
      );
      emit(NutritionAnalysisLoaded(analysis: analysis));
    } catch (e) {
      emit(NutritionError(e.toString()));
    }
  }

  Future<void> _onSaveNutritionAnalysisRequested(
    SaveNutritionAnalysisRequested event,
    Emitter<NutritionState> emit,
  ) async {
    try {
      await saveNutritionAnalysisUseCase(event.analysis);
      emit(const NutritionAnalysisSaved());
    } catch (e) {
      emit(NutritionError(e.toString()));
    }
  }

  Future<void> _onGetAllNutritionAnalysesRequested(
    GetAllNutritionAnalysesRequested event,
    Emitter<NutritionState> emit,
  ) async {
    try {
      final analyses = await getAllNutritionAnalysesUseCase();
      emit(AllNutritionAnalysesLoaded(analyses));
    } catch (e) {
      emit(NutritionError(e.toString()));
    }
  }

  Future<void> _onGetNutritionAnalysisByIdRequested(
    GetNutritionAnalysisByIdRequested event,
    Emitter<NutritionState> emit,
  ) async {
    try {
      final analysis = await getNutritionAnalysisByIdUseCase(event.id);
      if (analysis != null) {
        emit(NutritionAnalysisLoaded(analysis: analysis.analysis, imagePath: analysis.imagePath));
      } else {
        emit(const NutritionError("Analysis not found"));
      }
    } catch (e) {
      emit(NutritionError(e.toString()));
    }
  }

  Future<void> _onDeleteNutritionAnalysisRequested(
    DeleteNutritionAnalysisRequested event,
    Emitter<NutritionState> emit,
  ) async {
    try {
      await deleteNutritionAnalysisUseCase(event.id);
      final analyses = await getAllNutritionAnalysesUseCase();
      emit(AllNutritionAnalysesLoaded(analyses));
    } catch (e) {
      emit(NutritionError(e.toString()));
    }
  }
}











































