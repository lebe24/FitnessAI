import 'dart:async';
import 'dart:io';

import 'package:fitness/app/core/common/common_lib.dart';
import 'package:fitness/app/core/common/widget/appWidget.dart';
import 'package:fitness/app/core/di.dart' as di;
import 'package:fitness/app/core/routes/app_router.dart';
import 'package:fitness/app/storage/domain/usecases/save_fitness_plan_usecase.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import 'package:fitness/app/ui/onboarding/model/onboarding_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ModalState {
  init,
  input,
  generating,
  success,
  cancel,
}

class ResultModalPage extends StatefulWidget {
  const ResultModalPage({
    super.key,
    required this.image,
    required this.userData
  });

  final File image;
  final OnboardingData userData;

  @override
  State<ResultModalPage> createState() => _ResultModalPageState();
}

class _ResultModalPageState extends State<ResultModalPage> {
  ModalState _currentState = ModalState.init;
  String? _resultMessage;
  TextSpan? _formattedMessage;
  WorkoutPlanEntity? _workoutPlan;
  double _progress = 0.0;
  Timer? _progressTimer;

  final TextEditingController _textController = TextEditingController();

  void _generatePlan({String? extraInfo}) {
    setState(() {
      _currentState = ModalState.generating;
      _progress = 0.0;
    });
    
    // Start progress simulation
    _startProgressSimulation();

    // Extract required parameters from userData
    final goal = widget.userData.goal ?? 'Build Muscle';
    final workoutDays = widget.userData.workoutDays ?? 2;
    final trainingSplit = '$workoutDays days/week';
    final duration = '12 weeks'; 
    final gender = widget.userData.gender ?? 'Male';
    final height = widget.userData.height ?? '5.10';
    final weight = widget.userData.weight ?? '120kg';
    final experience = widget.userData.experience ?? 'Experienced';
    final extraInfo = _textController.text.isNotEmpty ? _textController.text : null;

    // Trigger the upload
    context.read<UploadBloc>().add(
          UploadImageToServer(
            image: widget.image,
            goal: goal,
            duration: duration,
            trainingSplit: trainingSplit,
            gender: gender,
            height: height,
            weight: weight,
            experience: experience,
            extraInfo: extraInfo,
          ));
    
  }

  void _startProgressSimulation() {
    _progressTimer?.cancel();
    _progress = 0.0;
    
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          // Simulate progress: slow at start, faster in middle, slow at end
          if (_progress < 0.9) {
            // Increase progress gradually, slowing down as it approaches 90%
            _progress += (0.9 - _progress) * 0.05;
          } else if (_progress < 0.95) {
            // Very slow near completion
            _progress += 0.01;
          }
          // Don't go to 100% until actual success
        });
      }
    });
  }

  void _stopProgressSimulation() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  // Helper function to extract plain text from TextSpan
  String _textSpanToPlainText(TextSpan span) {
    final buffer = StringBuffer();
    buffer.write(span.text ?? '');
    if (span.children != null) {
      for (var child in span.children!) {
        buffer.write(_textSpanToPlainText(child as TextSpan));
      }
    }
    return buffer.toString();
  }

  TextSpan _formatWorkoutPlanMessage(WorkoutPlanEntity plan) {
    final data = plan.plan;
    final List<TextSpan> spans = [];
    
    // Helper function to add styled text
    void addBold(String text) {
      spans.add(TextSpan(
        text: text,
        style: const TextStyle(
          color:Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ));
    }
    
    void addNormal(String text) {
      spans.add(TextSpan(text: text));
    }

    void addTip(String text) {
      spans.add(TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF09670C),
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      ));
    }
    
    void addNewLine() {
      spans.add(const TextSpan(text: '\n'));
    }
    
    // Analysis Summary
    addBold('📊 Analysis Summary:\n');
    addNormal(data.analysisSummary);
    addNewLine();
    
    // Physique Rating
    addNewLine();
    addBold('⭐ Physique Rating: ');
    addNormal('${data.physiqueRating}/100');
    addNewLine();
    
    // Goal
    addNewLine();
    addBold('🎯 Goal: ');
    addNormal(data.goal);
    addNewLine();
    
    // Focus
    addBold('💪 Focus: ');
    addNormal(data.focus);
    addNewLine();
    
    // Training Split
    addBold('📅 Training Split: ');
    addNormal(data.trainingSplit);
    addNewLine();
    
    // Equipment Needed
    addNewLine();
    addBold('🏋️ Equipment Needed:\n');
    for (var equipment in data.equipment) {
      addNormal('  • $equipment\n');
    }
    
    // Weekly Workout Plan
    addNewLine();
    addBold('📋 Weekly Workout Plan:\n');
    for (var day in data.weeklySplit.days) {
      addNewLine();
      addBold('${day.day} - ${day.focus}\n');
      for (var exercise in day.exercises) {
        addNormal('  • ${exercise.name}: ${exercise.sets} sets x ${exercise.reps}\n');
        if (exercise.notes != null) {
          addTip('    - Note: ${exercise.notes}\n');
        }
      }
      if (day.tip != null) {
        addNormal('  💡 Tip: ${day.tip}\n');
      }
    }
    
    // Training Guidelines
    addNewLine();
    addBold('📖 Training Guidelines:\n');
    addNormal('  • Rest between sets: ${data.trainingGuidelines.restBetweenSets}\n');
    addNormal('  • Progressive overload: ${data.trainingGuidelines.progressiveOverload}\n');
    addNormal('  • Duration: ${data.trainingGuidelines.durationWeeks}\n');
    
    // Nutrition Guidelines
    addNewLine();
    addBold('🥗 Nutrition Guidelines:\n');
    addNormal('  • Protein: ${data.nutritionGuidelines.proteinPerKg}\n');
    addNormal('  • Calorie surplus: ${data.nutritionGuidelines.calorieSurplus}\n');
    addNormal('  • Hydration: ${data.nutritionGuidelines.hydration}\n');
    addNormal('  • Sleep: ${data.nutritionGuidelines.sleep}\n');
    if (data.nutritionGuidelines.additionalNotes != null) {
      addNormal('  • Additional notes: ${data.nutritionGuidelines.additionalNotes}\n');
    }
    
    // Extra Tips
    if (data.extraTips.isNotEmpty) {
      addNewLine();
      addBold('💡 Extra Tips:\n');
      for (var tip in data.extraTips) {
        addNormal('  • $tip\n');
      }
    }
    
    return TextSpan(
      children: spans,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        height: 1.5,
      ),
    );
  }

  double _getHeight() {
    switch (_currentState) {
      case ModalState.init:
        return 250;
      case ModalState.input:
        return 400;
      case ModalState.generating:
        return 400;
      case ModalState.success:
        return 700;
      case ModalState.cancel:
        return 200;
    }
  }

  Widget _buildHeader() {
    switch (_currentState) {
      case ModalState.init:
        return const Text(
          "Options",
          style: TextStyle(
            fontSize: 20,
            letterSpacing: 0,
            fontWeight: FontWeight.w500,
          ),
        );
      case ModalState.input:
        return const Icon(
          Icons.info,
          size: 32,
      );
      case ModalState.generating:
        return const Icon(
          Icons.auto_awesome,
          size: 32,
        );
      case ModalState.success:
        return const Icon(
          Icons.check_circle,
          size: 32,
          color: Colors.green,
        );
      case ModalState.cancel:
        return Container();
    }
  }

  Widget _buildContent() {
    switch (_currentState) {
      case ModalState.init:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentState = ModalState.input;
                  });
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Icon(
                          Icons.info,
                          size: 30,
                          color: Color(0xFF000000),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Do you want to add any extra information",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => _generatePlan(extraInfo: null),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 30,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20.0),
                          child: Text(
                            "Generate Your Plan",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: ElevatedButton.icon(
            //     onPressed: () => _generatePlan(extraInfo: null),
            //     icon: const Icon(
            //       Icons.auto_awesome,
            //       size: 30,
            //       color: Colors.white,
            //     ),
            //     label: const Text(
            //       "Generate your Plan",
            //       style: TextStyle(
            //         fontSize: 20,
            //         color: Colors.white,
            //       ),
            //     ),
            //     style: ButtonStyle(
            //       backgroundColor: WidgetStateProperty.all<Color>(
            //         const Color.fromARGB(255, 18, 221, 65),
            //       ),
            //       minimumSize: WidgetStateProperty.all<Size>(
            //         const Size(50, 50),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        );
      case ModalState.input:
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Enter extra information for personalized plan',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                      
                      labelStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 18, 221, 65),
                          width: 2,
                        ),
                      ),
                      // filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.done,
                    maxLines: null,
                    expands: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                          style: ButtonStyle(
                              padding: WidgetStateProperty.all<EdgeInsets>(const EdgeInsets.all(10)),
                              backgroundColor: WidgetStateProperty.all<Color>(Colors.grey),
                            ),
                            onPressed: () {
                              setState(() {
                                _currentState = ModalState.init;
                              });
                            },
                            child: const Text("Cancel",style: TextStyle(color:Colors.black,fontSize: 15)),),
                    )),
                  Expanded(child:Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all<EdgeInsets>(const EdgeInsets.all(10)),
                              backgroundColor: WidgetStateProperty.all<Color>(const Color(0xFF000000)),
                            ),
                            onPressed: () {
                              // Generate plan with extra info
                              final extraInfo = _textController.text.trim();
                              _generatePlan(extraInfo: extraInfo.isEmpty ? null : extraInfo);
                            }, 
                            label: const Text("Generate",style: TextStyle(color:Colors.white,fontSize: 15)),
                            icon: const Icon(Icons.auto_awesome, size: 20,color: Colors.white,),),
                  ))
                ],
              )
            ],
          ),
        );
      case ModalState.cancel:
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Operation cancelled.",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
      );
      case ModalState.generating:
        return BlocListener<UploadBloc, UploadState>(
          listener: (context, state) async {
            if (state is UploadSeverSuccess && state.workoutPlan != null) {
              // Stop progress simulation
              _stopProgressSimulation();
              
              // Set progress to 100% before showing success
              setState(() {
                _progress = 1.0;
              });
              
              // Save the plan and image to storage
              try {
                final saveFitnessPlanUsecase = di.sl<SaveFitnessPlanUsecase>();
                await saveFitnessPlanUsecase(
                  workoutPlan: state.workoutPlan!,
                  imageFilePath: widget.image.path,
                );
                debugPrint('Fitness plan and image saved successfully');
              } catch (e) {
                debugPrint('Error saving fitness plan: $e');
                // Still show success even if storage fails
              }

              setState(() {
                _currentState = ModalState.success;
                _workoutPlan = state.workoutPlan;
                _formattedMessage = _formatWorkoutPlanMessage(state.workoutPlan!);
                _resultMessage = _textSpanToPlainText(_formattedMessage!);
              });
            } else if (state is UploadFailure) {
              // Stop progress on failure
              _stopProgressSimulation();
            }
          },
          child: BlocBuilder<UploadBloc, UploadState>(
            builder: (context, state) {
              if (state is UploadSeverSuccess) {
                // Success - listener will change state, show 100% progress
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "100%",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: 1.0,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Processing your plan...",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is UploadFailure) {
                debugPrint(state.message);
                // Show error with retry option
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Text("Problem in generating your Workout plan. Please try again. If the problem persists, please check your internet connection.",                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _currentState = ModalState.init;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              child: const Text("Go Back"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Retry with the same parameters
                                final extraInfo = _textController.text.trim();
                                _generatePlan(
                                  extraInfo: extraInfo.isEmpty ? null : extraInfo,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF010101),
                              ),
                              child: const Text(
                                "Retry",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                // Loading state with percentage progress
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${(_progress * 100).toInt()}%",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Generating your personalized workout plan...",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _progress < 0.3
                              ? "Uploading image..."
                              : _progress < 0.6
                                  ? "Analyzing your physique..."
                                  : _progress < 0.9
                                      ? "Creating your workout plan..."
                                      : "Finalizing details...",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        );
      case ModalState.success:
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: _formattedMessage != null
                    ? Text.rich(
                        _formattedMessage!,
                      )
                    : Text(
                        _resultMessage ?? 'Plan generated successfully!',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width:double.infinity,
              child: AppWidgets.roundbtnText(
                onPressed: () {
                   context.go(ScreenPaths.home);
                },
                text: "Save Plan",
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        height: _getHeight(),
        width: double.infinity * 0.95,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _buildHeader(),
                ),
                IconButton(
                  onPressed: () {
                    if (_currentState == ModalState.generating) {
                      _stopProgressSimulation();
                      setState(() {
                        _currentState = ModalState.cancel;
                      });
                    } else {
                      _stopProgressSimulation();
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.cancel),
                  color:Colors.red,
                  iconSize: 30,
                ),
              ],
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}