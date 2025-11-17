import 'package:fitness/app/ui/onboarding/bloc/onboarding_event.dart';
import 'package:fitness/app/ui/onboarding/bloc/onboarding_state.dart';
import 'package:fitness/app/ui/onboarding/model/onboarding_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Export event and state for convenience
export 'onboarding_event.dart';
export 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc()
      : super(const OnboardingState(
          data: OnboardingData(),
          step: OnboardingStep.gender,
        )) {
    on<SelectWorkoutDays>((event, emit) {
      emit(state.copyWith(
          data: state.data.copyWith(workoutDays: event.days)));
    });

    on<SelectGender>((event, emit) {
      emit(state.copyWith(data: state.data.copyWith(gender: event.gender)));
    });

    on<SelectGoal>((event, emit) {
      emit(state.copyWith(data: state.data.copyWith(goal: event.goal)));
    });

    on<SelectHeight>((event, emit) {
      emit(state.copyWith(
          data: state.data.copyWith(height: event.height,
      )));
    });

    on<SelectWeight>((event, emit) {
      emit(state.copyWith(
          data: state.data.copyWith(weight: event.weight,
          )));
    });

    on<ToggleUnitSystem>((event, emit) {
      emit(state.copyWith(isMetric: event.isMetric));
    });

    on<SelectHeightFt>((event, emit) {
      emit(state.copyWith(
        selectedFeet: event.feet,
        selectedInches: event.inches,
      ));
    });

    on<SelectHeightMeters>((event, emit) {
      emit(state.copyWith(
        selectedMeters: event.meters,
      ));
    });

    on<SelectWeightWt>((event, emit) {
      emit(state.copyWith(
        selectedKg: event.kg ?? state.selectedKg,
        selectedLbs: event.lbs ?? state.selectedLbs,
      ));
    });

    on<SelectDob>((event, emit) {
      emit(state.copyWith(data: state.data.copyWith(dob: event.dob)));
    });

    on<NextStep>((event, emit) {
      final nextStep = _next(state.step);
      emit(state.copyWith(step: nextStep));
    });

    on<PreviousStep>((event, emit) {
      final prevStep = _prev(state.step);
      emit(state.copyWith(step: prevStep));
    });
  }

  OnboardingStep _next(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.gender:
        return OnboardingStep.workoutDays;
      case OnboardingStep.goal:
        return OnboardingStep.heightAndWeight;
      case OnboardingStep.workoutDays:
        return OnboardingStep.goal;
      case OnboardingStep.heightAndWeight:
        return OnboardingStep.dob;
      case OnboardingStep.dob:
        return OnboardingStep.signup;
      case OnboardingStep.signup:
        return OnboardingStep.summary;
      case OnboardingStep.summary:
        return OnboardingStep.summary;
    }
  }

  OnboardingStep _prev(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.summary:
        return OnboardingStep.signup;
      case OnboardingStep.signup:
        return OnboardingStep.dob;
      case OnboardingStep.dob:
        return OnboardingStep.heightAndWeight;
      case OnboardingStep.heightAndWeight:
        return OnboardingStep.goal;
      case OnboardingStep.goal:
        return OnboardingStep.workoutDays;
      case OnboardingStep.workoutDays:
        return OnboardingStep.gender;
      case OnboardingStep.gender:
        return OnboardingStep.gender;
    }
  }
}
