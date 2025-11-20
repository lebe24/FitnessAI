import 'package:equatable/equatable.dart';

abstract class FitnessEvent extends Equatable {
  const FitnessEvent();

  @override
  List<Object?> get props => [];
}

class LoadFitnessPlans extends FitnessEvent {
  const LoadFitnessPlans();
}

class DateSelected extends FitnessEvent {
  final DateTime date;

  const DateSelected(this.date);

  @override
  List<Object?> get props => [date];
}

