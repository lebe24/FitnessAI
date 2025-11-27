import 'package:equatable/equatable.dart';

/// Entity representing an exercise from ExerciseDB API
class ExerciseEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final String? equipment;
  final String? bodyPart;
  final String? gifUrl;
  final String? imageUrl;

  const ExerciseEntity({
    required this.id,
    required this.name,
    this.description,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.instructions,
    this.equipment,
    this.bodyPart,
    this.gifUrl,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        primaryMuscles,
        secondaryMuscles,
        instructions,
        equipment,
        bodyPart,
        gifUrl,
        imageUrl,
      ];
}

/// Entity representing a search result from ExerciseDB API
class ExerciseSearchResultEntity extends Equatable {
  final String id;
  final String name;
  final String? bodyPart;
  final String? equipment;
  final String? gifUrl;

  const ExerciseSearchResultEntity({
    required this.id,
    required this.name,
    this.bodyPart,
    this.equipment,
    this.gifUrl,
  });

  @override
  List<Object?> get props => [id, name, bodyPart, equipment, gifUrl];
}

