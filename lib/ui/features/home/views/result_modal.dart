import 'dart:async';
import 'dart:io';

import 'package:fitness/ui/core/di.dart' as di;
import 'package:fitness/domain/use_cases/storage/save_fitness_plan_usecase.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/ui/features/home/view_models/upload_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ── Brand colours (dark sheet) ────────────────────────────────────────────────
const _sheetBg   = Color(0xFF0A0C12);
const _surface   = Color(0xFF1A2332);
const _surfaceEl = Color(0xFF121620);
const _border    = Color(0xFF2A2F3D);
const _lime      = Color(0xFFCCFF00);
const _textPri   = Colors.white;
const _textSub   = Color(0xFF9E9E9E);

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
  UploadViewModel? _uploadVm;

  final TextEditingController _textController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_uploadVm == null) {
      _uploadVm = context.read<UploadViewModel>();
      _uploadVm!.addListener(_onUploadChanged);
    }
  }

  void _onUploadChanged() {
    if (!mounted) return;
    final vm = _uploadVm!;
    if (vm.workoutPlan != null && !vm.isLoading) {
      _stopProgressSimulation();
      setState(() => _progress = 1.0);
      _saveAndShowSuccess(vm.workoutPlan!);
    } else if (vm.error != null && !vm.isLoading) {
      _stopProgressSimulation();
    }
  }

  Future<void> _saveAndShowSuccess(WorkoutPlanEntity plan) async {
    try {
      await di.sl<SaveFitnessPlanUsecase>()(
        workoutPlan: plan,
        imageFilePath: widget.image.path,
      );
    } catch (e) {
      debugPrint('Error saving fitness plan: $e');
    }
    if (!mounted) return;
    setState(() {
      _currentState = ModalState.success;
      _workoutPlan = plan;
      _formattedMessage = _formatWorkoutPlanMessage(plan);
      _resultMessage = _textSpanToPlainText(_formattedMessage!);
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _textController.dispose();
    _uploadVm?.removeListener(_onUploadChanged);
    super.dispose();
  }

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

    _uploadVm!.upload(
      image: widget.image,
      goal: goal,
      duration: duration,
      trainingSplit: trainingSplit,
      gender: gender,
      height: height,
      weight: weight,
      experience: experience,
      extraInfo: extraInfo,
    );
    
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
      case ModalState.init:      return 240;
      case ModalState.input:     return 420;
      case ModalState.generating:return 380;
      case ModalState.success:   return 680;
      case ModalState.cancel:    return 200;
    }
  }

  Widget _buildHeader() {
    switch (_currentState) {
      case ModalState.init:
        return Text('Generate Plan',
            style: GoogleFonts.poppins(
                color: _textPri, fontSize: 16, fontWeight: FontWeight.w600));
      case ModalState.input:
        return Text('Extra Info',
            style: GoogleFonts.poppins(
                color: _textPri, fontSize: 16, fontWeight: FontWeight.w600));
      case ModalState.generating:
        return Text('Analysing…',
            style: GoogleFonts.poppins(
                color: _lime, fontSize: 16, fontWeight: FontWeight.w600));
      case ModalState.success:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF4CAF50), size: 18),
          const SizedBox(width: 8),
          Text('Plan Ready',
              style: GoogleFonts.poppins(
                  color: _textPri,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ]);
      case ModalState.cancel:
        return const SizedBox.shrink();
    }
  }

  Widget _buildContent() {
    switch (_currentState) {
      case ModalState.init:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add extra info option
            GestureDetector(
              onTap: () => setState(() => _currentState = ModalState.input),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_note_rounded,
                        color: _textSub, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add extra info',
                            style: GoogleFonts.poppins(
                                color: _textPri,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Text('Injuries, preferences, equipment…',
                            style: GoogleFonts.inter(
                                color: _textSub, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: _textSub, size: 18),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            // Generate now
            GestureDetector(
              onTap: () => _generatePlan(extraInfo: null),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: _lime,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _lime.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: Colors.black, size: 20),
                    const SizedBox(width: 8),
                    Text('Generate My Plan',
                        style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        );
      case ModalState.input:
        return Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Theme(
                  data: ThemeData.dark(),
                  child: TextField(
                    controller: _textController,
                    cursorColor: _lime,
                    style: GoogleFonts.inter(
                        color: _textPri, fontSize: 14, height: 1.5),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. bad knees, home gym, focusing on upper body…',
                      hintStyle:
                          GoogleFonts.inter(color: _textSub, fontSize: 13),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    expands: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              GestureDetector(
                onTap: () => setState(() => _currentState = ModalState.init),
                child: Container(
                  height: 50,
                  width: 90,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Center(
                    child: Text('Back',
                        style: GoogleFonts.poppins(
                            color: _textSub,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final extra = _textController.text.trim();
                    _generatePlan(extraInfo: extra.isEmpty ? null : extra);
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _lime,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _lime.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: Colors.black, size: 18),
                        const SizedBox(width: 7),
                        Text('Generate',
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ],
        );
      case ModalState.cancel:
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cancel_rounded, color: _textSub, size: 40),
            const SizedBox(height: 12),
            Text('Generation cancelled.',
                style: GoogleFonts.inter(color: _textSub, fontSize: 14)),
          ]),
        );
      case ModalState.generating:
        return Consumer<UploadViewModel>(
          builder: (context, vm, _) {
            if (vm.error != null && !vm.isLoading) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 44, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Could not generate your plan.\nCheck your connection and try again.',
                    textAlign: TextAlign.center,
                    style:
                        GoogleFonts.inter(color: _textSub, fontSize: 13, height: 1.55),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _currentState = ModalState.init),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border),
                          ),
                          child: Text('Back',
                              style: GoogleFonts.poppins(
                                  color: _textSub,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          final extra = _textController.text.trim();
                          _generatePlan(
                              extraInfo: extra.isEmpty ? null : extra);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: _lime,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Retry',
                              style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ]),
              );
            }

            // Progress state
            final pct = (_progress * 100).toInt();
            final label = _progress < 0.3
                ? 'Uploading image…'
                : _progress < 0.6
                    ? 'Analysing your physique…'
                    : _progress < 0.9
                        ? 'Building your plan…'
                        : 'Finalising details…';

            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Lime percentage
                Text(
                  '$pct%',
                  style: GoogleFonts.poppins(
                    color: _lime,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 20),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: _surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(_lime),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Generating your personalised workout plan…',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: _textPri,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(color: _textSub, fontSize: 12),
                ),
              ]),
            );
          },
        );
      case ModalState.success:
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _formattedMessage != null
                    ? _DarkPlanView(span: _formattedMessage!)
                    : Text(
                        _resultMessage ?? 'Plan generated successfully!',
                        style: GoogleFonts.inter(
                            color: _textPri, fontSize: 14, height: 1.5),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => context.go('/home'),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: _lime,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _lime.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded,
                        color: Colors.black, size: 20),
                    const SizedBox(width: 8),
                    Text('Save & View Plan',
                        style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        height: _getHeight(),
        width: double.infinity,
        decoration: BoxDecoration(
          color: _sheetBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _buildHeader(),
                ),
                GestureDetector(
                  onTap: () {
                    if (_currentState == ModalState.generating) {
                      _stopProgressSimulation();
                      setState(() => _currentState = ModalState.cancel);
                    } else {
                      _stopProgressSimulation();
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.red.shade800.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.redAccent, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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

// ── Dark-themed plan view ─────────────────────────────────────────────────────
class _DarkPlanView extends StatelessWidget {
  final TextSpan span;
  const _DarkPlanView({required this.span});

  @override
  Widget build(BuildContext context) {
    // Re-render the TextSpan with dark-appropriate colours
    final darkSpan = _recolour(span);
    return Text.rich(
      darkSpan,
      style: GoogleFonts.inter(color: _textPri, fontSize: 13, height: 1.6),
    );
  }

  /// Walk the TextSpan tree and swap light-world colours for dark-world ones.
  TextSpan _recolour(TextSpan s) {
    final style = s.style;
    TextStyle? newStyle;
    if (style != null) {
      Color? c = style.color;
      if (c == Colors.black87 || c == const Color(0xDD000000)) c = _textPri;
      if (c == const Color(0xFF09670C)) c = _lime; // tip green → lime
      if (c == Colors.red) c = _lime;              // bold headers
      newStyle = style.copyWith(color: c);
    }
    return TextSpan(
      text: s.text,
      style: newStyle,
      children: s.children
          ?.map((c) => c is TextSpan ? _recolour(c) : c)
          .toList(),
    );
  }
}