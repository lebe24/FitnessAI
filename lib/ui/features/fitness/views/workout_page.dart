import 'dart:io';
import 'package:fitness/data/models/equipment_scan_model.dart';
import 'package:fitness/data/services/fitness/equipment_scan_service.dart';
import 'package:fitness/data/services/fitness/exercise_advisor_service.dart';
import 'package:fitness/data/services/fitness/workout_session_analysis_service.dart';
import 'package:fitness/data/services/workout_log/workout_log_remote_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/ui/features/chat/view_models/chat_view_model.dart';
import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/ui/features/fitness/view_models/fitness_view_model.dart';
import 'package:fitness/ui/features/fitness/views/fitness_page_method.dart';
import 'package:provider/provider.dart';
import 'package:fitness/ui/features/fitness/views/exercise_hero_page.dart';
import 'package:fitness/domain/models/workout_plan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kLime      = Color(0xFFCCFF00);
const _kCard      = Color(0xFF111318);
const _kBorder    = Color(0xFF1E2330);
const _kDimWhite  = Color(0x80FFFFFF);
const _kGreen     = Color(0xFF4CAF50);

enum AiChat { none, active }

class WorkoutPage extends StatefulWidget {
  final WorkoutDay? workoutDay;
  final DateTime?   date;

  const WorkoutPage({super.key, this.workoutDay, this.date});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  // ─── State ────────────────────────────────────────────────────────────────────
  AiChat _aiChatState = AiChat.none;
  final Set<int> _completedExercises = {};
  int _currentExerciseIndex = 0;
  late List<Exercise> _localExercises;

  // Rest-time tracking: timestamps when each exercise is marked complete.
  final List<DateTime> _completionTimestamps = [];

  final TextEditingController _messageController    = TextEditingController();
  final TextEditingController _durationController   = TextEditingController();
  final ScrollController      _chatScrollController = ScrollController();
  late final ChatViewModel    _chatViewModel;

  final _workoutLog     = sl<WorkoutLogRemoteDataSource>();
  final _getCurrentUser = sl<GetCurrentUser>();

  // ─── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _localExercises = List.of(widget.workoutDay?.exercises ?? []);
    _chatViewModel = sl<ChatViewModel>(instanceName: 'workout');
    if (_localExercises.isEmpty) {
      _currentExerciseIndex = -1;
    }
  }

  @override
  void dispose() {
    _chatViewModel.disconnect();
    _messageController.dispose();
    _durationController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────
  List<Exercise> get _exercises => _localExercises;

  bool _isActive(int i) =>
      _currentExerciseIndex == i && !_completedExercises.contains(i);

  bool _isDone(int i) => _completedExercises.contains(i);

  String get _formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = widget.date ?? DateTime.now();
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ─── Chat ─────────────────────────────────────────────────────────────────────
  void _scrollChatToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendChatMessage(String text, {String? imagePath}) {
    final userId = _getCurrentUser()?.id ?? '';
    if (userId.isEmpty) return;
    _chatViewModel.sendMessage(text, userId, imagePath: imagePath);
    _scrollChatToBottom();
  }

  void _toggleAiChat() {
    if (_aiChatState == AiChat.none) {
      setState(() => _aiChatState = AiChat.active);
      _showChatModal();
    } else {
      setState(() => _aiChatState = AiChat.none);
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
  }

  void _showChatModal() {
    final user   = _getCurrentUser();
    final userId = user?.id ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to use chat')),
      );
      setState(() => _aiChatState = AiChat.none);
      return;
    }

    Map<String, dynamic>? planData;
    if (_exercises.isNotEmpty) {
      planData = {
        'exercises': _exercises.map((e) => {
          'name': e.name, 'sets': e.sets, 'reps': e.reps,
          if (e.notes != null) 'notes': e.notes,
        }).toList(),
        if (widget.workoutDay != null) 'day':   widget.workoutDay!.day,
        if (widget.workoutDay != null) 'focus': widget.workoutDay!.focus,
        if (widget.workoutDay?.tip != null) 'tip': widget.workoutDay!.tip,
        if (widget.date != null) 'date': widget.date!.toIso8601String(),
      };
    }

    _chatViewModel.connect(userId, user?.name ?? 'Guest', workoutPlan: planData);

    chatModal(
      context: context,
      chatViewModel: _chatViewModel,
      userId: userId,
      onClose: () => setState(() => _aiChatState = AiChat.none),
      onSendMessage: _sendChatMessage,
      scrollController: _chatScrollController,
      messageController: _messageController,
      scrollToBottom: _scrollChatToBottom,
    ).then((_) {
      if (_aiChatState == AiChat.active) {
        setState(() => _aiChatState = AiChat.none);
      }
    });
  }

  // ─── Reordering ─────────────────────────────────────────────────────────────
  // The active ("NOW") exercise is always the first one not yet completed. So a
  // reorder just needs to preserve which exercises are done (tracked by index)
  // and then recompute the active pointer — dragging a card above the current
  // active card hands the NOW status to the card now sitting first among the
  // remaining exercises. We capture the completed exercises by identity, move
  // the list, then rebuild the done indices and the active pointer.
  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;

      final completedRefs = {
        for (final i in _completedExercises) _localExercises[i],
      };

      final moved = _localExercises.removeAt(oldIndex);
      _localExercises.insert(newIndex, moved);

      _completedExercises
        ..clear()
        ..addAll([
          for (int i = 0; i < _localExercises.length; i++)
            if (completedRefs.contains(_localExercises[i])) i,
        ]);
      _currentExerciseIndex = _firstIncompleteIndex();
    });
  }

  /// First exercise not yet completed — the active ("NOW") card — or -1 if all
  /// exercises are done.
  int _firstIncompleteIndex() {
    for (int i = 0; i < _localExercises.length; i++) {
      if (!_completedExercises.contains(i)) return i;
    }
    return -1;
  }

  // ─── Exercise completion ──────────────────────────────────────────────────────
  void _completeExercise(int index) {
    _completionTimestamps.add(DateTime.now());
    setState(() {
      _completedExercises.add(index);
      if (_currentExerciseIndex == index &&
          index < _exercises.length - 1) {
        _currentExerciseIndex = index + 1;
      }
    });
    if (_completedExercises.length == _exercises.length &&
        _exercises.isNotEmpty) {
      _showDurationDialog();
    }
  }

  int _avgRestSecs() {
    if (_completionTimestamps.length < 2) return 0;
    int totalSecs = 0;
    for (int i = 1; i < _completionTimestamps.length; i++) {
      totalSecs += _completionTimestamps[i]
          .difference(_completionTimestamps[i - 1])
          .inSeconds;
    }
    return totalSecs ~/ (_completionTimestamps.length - 1);
  }

  void _openHeroPage(int index) {
    if (!_isActive(index)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete the previous exercise first.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: _kCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExerciseHeroPage(
        exercise: _exercises[index],
        exerciseIndex: index,
        onComplete: () {
          Navigator.of(context).pop();
          // Wait for the pop animation to finish before completing so
          // _showDurationDialog() runs on the visible WorkoutPage context.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _completeExercise(index);
          });
        },
      ),
    ));
  }

  // ─── Duration dialog ─────────────────────────────────────────────────────────
  void _showDurationDialog() {
    _durationController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DurationDialog(
        controller: _durationController,
        onSave: (duration) async {
          Navigator.of(context).pop();
          await _saveWorkout(duration);
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _saveWorkout(double duration) async {
    try {
      final user = _getCurrentUser();
      if (user?.id == null) {
        _showSnack('Please sign in to save workout data', isError: true);
        return;
      }
      final workoutDate = widget.date ?? DateTime.now();
      final session = await _workoutLog.saveCompleteSession(
        sessionDate: workoutDate,
        exercises: _localExercises,
        dayLabel: widget.workoutDay?.day,
        durationMins: duration.round(),
      );
      if (mounted) {
        _showSnack('Workout saved!');
        _showRestTimeDialog(duration, workoutDate, sessionId: session.id);
      }
    } catch (e) {
      if (mounted) _showSnack('Error saving workout: $e', isError: true);
    }
  }

  void _showRestTimeDialog(double duration, DateTime workoutDate, {String? sessionId}) {
    final avgRest = _avgRestSecs();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RestTimeDialog(
        prefilledSecs: avgRest > 0 ? avgRest : null,
        onContinue: (restSecs) {
          Navigator.of(context).pop();
          _runWorkoutAnalysis(duration, restSecs, workoutDate, sessionId: sessionId);
        },
        onSkip: () {
          Navigator.of(context).pop();
          _markStreakComplete(workoutDate, duration.round());
        },
      ),
    );
  }

  void _runWorkoutAnalysis(double duration, int avgRestSecs, DateTime workoutDate, {String? sessionId}) {
    final exercises = _localExercises.map((e) => {
      'name': e.name,
      'sets': e.sets,
      'reps': e.reps,
      if (e.notes != null) 'notes': e.notes!,
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkoutAnalysisSheet(
        exercises: exercises,
        durationMins: duration.round(),
        avgRestSecs: avgRestSecs,
        workoutDay: widget.workoutDay?.day,
        focus: widget.workoutDay?.focus,
        sessionId: sessionId,
        onDone: () {
          Navigator.of(context).pop();
          _markStreakComplete(workoutDate, duration.round());
        },
      ),
    );
  }

  void _markStreakComplete(DateTime workoutDate, int durationMins) {
    if (!mounted) return;
    context.read<FitnessViewModel>().completeWorkout(
      workoutDate,
      durationMins: durationMins,
    );
    _showSnack('Keep the streak alive 🔥');
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
      backgroundColor: isError ? Colors.redAccent : _kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final done  = _completedExercises.length;
    final total = _exercises.length;

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: _AiCoachFab(
        isActive: _aiChatState == AiChat.active,
        onTap: _toggleAiChat,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Color(0xFF111111),
              Color(0xFF1C1C1E),
              Color(0xFF2A2A2A),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Main content ─────────────────────────────────────────────
              Column(
                children: [
                  // ── Header ─────────────────────────────────────────────
                  _WorkoutHeader(
                    dayName: widget.workoutDay?.day ?? 'Today',
                    date: _formattedDate,
                    focus: widget.workoutDay?.focus,
                    done: done,
                    total: total,
                  ),
                  // ── Progress bar ───────────────────────────────────────
                  _LinearProgress(done: done, total: total),
                  // ── Exercise list ──────────────────────────────────────
                  Expanded(
                    child: _exercises.isEmpty
                        ? _EmptyState()
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _exercises.length,
                            onReorder: _reorderExercises,
                            // Drag via the explicit handle, not the whole tile,
                            // so it doesn't fight with tap / double-tap gestures.
                            buildDefaultDragHandles: false,
                            // The default proxy wraps the lifted item in an opaque
                            // white Material — make it transparent so only the
                            // card itself shows while dragging.
                            proxyDecorator: (child, index, animation) =>
                                Material(
                              type: MaterialType.transparency,
                              child: child,
                            ),
                            itemBuilder: (_, i) => _ExerciseItem(
                              key: ObjectKey(_exercises[i]),
                              exercise: _exercises[i],
                              index: i,
                              total: total,
                              isActive: _isActive(i),
                              isDone: _isDone(i),
                              onComplete: () => _completeExercise(i),
                              onDoubleTap: () => _openHeroPage(i),
                            ),
                          ),
                  ),
                ],
              ),
              // ── Plus button — bottom-left ────────────────────────────────
              Positioned(
                bottom: 24,
                left: 20,
                child: _PlusFab(
                  onScanEquipment: () => _showScanEquipmentDialog(context),
                  onAddExercise: () => _showAddExerciseSheet(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddExerciseSheet(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final added = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddExerciseSheet(
        workoutFocus: widget.workoutDay?.focus ?? '',
        workoutDay: widget.workoutDay?.day ?? '',
        existingExercises: _localExercises.map((e) => e.name).toList(),
      ),
    );
    if (added != null && mounted) {
      setState(() {
        _localExercises = [..._localExercises, added];
        if (_currentExerciseIndex == -1) _currentExerciseIndex = 0;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '"${added.name}" added to your workout',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF1A2A00),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showScanEquipmentDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final added = await showDialog<List<Exercise>>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _ScanEquipmentDialog(
        workoutDay: widget.workoutDay?.day ?? '',
        workoutFocus: widget.workoutDay?.focus ?? '',
        exercises: _exercises
            .map((e) => {
                  'name': e.name,
                  'sets': e.sets,
                  'reps': e.reps,
                  if (e.notes != null) 'notes': e.notes,
                })
            .toList(),
      ),
    );
    if (added != null && added.isNotEmpty && mounted) {
      setState(() {
        _localExercises = [..._localExercises, ...added];
        if (_currentExerciseIndex == -1) _currentExerciseIndex = 0;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${added.length} exercise${added.length > 1 ? 's' : ''} added to your workout',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF1A2A00),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _WorkoutHeader extends StatelessWidget {
  final String  dayName;
  final String  date;
  final String? focus;
  final int     done;
  final int     total;

  const _WorkoutHeader({
    required this.dayName,
    required this.date,
    required this.done,
    required this.total,
    this.focus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        dayName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                    if (focus != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kLime.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _kLime.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Text(
                          focus!,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kLime,
                          ),
                        ),
                      ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: _kDimWhite),
                ),
              ],
            ),
          ),
          // Done counter
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                  children: [
                    TextSpan(text: '$done'),
                    TextSpan(
                      text: '/$total',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kDimWhite,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'exercises',
                style: GoogleFonts.inter(fontSize: 10, color: _kDimWhite),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Linear progress bar ──────────────────────────────────────────────────────

class _LinearProgress extends StatelessWidget {
  final int done;
  final int total;
  const _LinearProgress({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                // Track
                Container(
                  height: 4,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
                // Fill
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  widthFactor: progress,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF99CC00), _kLime],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Exercise item (rail dot + card) ─────────────────────────────────────────

class _ExerciseItem extends StatelessWidget {
  final Exercise  exercise;
  final int       index;
  final int       total;
  final bool      isActive;
  final bool      isDone;
  final VoidCallback onComplete;
  final VoidCallback onDoubleTap;

  const _ExerciseItem({
    super.key,
    required this.exercise,
    required this.index,
    required this.total,
    required this.isActive,
    required this.isDone,
    required this.onComplete,
    required this.onDoubleTap,
  });

  bool get _isLast => index == total - 1;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Rail ─────────────────────────────────────────────────────────
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? _kLime
                        : isActive
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.07),
                    border: Border.all(
                      color: isDone
                          ? _kLime
                          : isActive
                              ? _kLime
                              : Colors.white.withValues(alpha: 0.15),
                      width: isActive ? 2 : 0,
                    ),
                    boxShadow: isDone || isActive
                        ? [
                            BoxShadow(
                              color: _kLime.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          color: Colors.black, size: 12)
                      : isActive
                          ? Center(
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _kLime,
                                ),
                              ),
                            )
                          : null,
                ),
                // Connecting line
                if (!_isLast)
                  Expanded(
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 2,
                        color: isDone
                            ? _kLime.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Card ─────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: _isLast ? 0 : 12),
              child: GestureDetector(
                onDoubleTap: onDoubleTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.white.withValues(alpha: 0.03)
                        : isActive
                            ? _kCard
                            : _kCard.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDone
                          ? Colors.white.withValues(alpha: 0.06)
                          : isActive
                              ? _kLime.withValues(alpha: 0.35)
                              : _kBorder,
                      width: 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: _kLime.withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: isDone
                      ? _DoneCard(exercise: exercise, index: index)
                      : isActive
                          ? _ActiveCard(
                              exercise: exercise,
                              index: index,
                              onComplete: onComplete,
                            )
                          : _PendingCard(exercise: exercise, index: index),
                ),
              ),
            ),
          ),
          // ── Drag handle ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(bottom: _isLast ? 0 : 12, left: 4),
            child: ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 32,
                alignment: Alignment.center,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active card ───────────────────────────────────────────────────────────────

class _ActiveCard extends StatelessWidget {
  final Exercise exercise;
  final int index;
  final VoidCallback onComplete;
  const _ActiveCard({
    required this.exercise,
    required this.index,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _kLime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'NOW',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: _kLime,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Sets × reps
          Row(
            children: [
              _StatPill(
                icon: Icons.repeat_rounded,
                label: '${exercise.sets} sets',
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.fitness_center_rounded,
                label: exercise.reps,
              ),
            ],
          ),
          if (exercise.notes != null) ...[
            const SizedBox(height: 10),
            Text(
              exercise.notes!,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
          const SizedBox(height: 6),
          // Double-tap hint
          Row(
            children: [
              Icon(Icons.touch_app_rounded,
                  size: 12, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(width: 4),
              Text(
                'Double tap to view demo',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Complete button
          GestureDetector(
            onTap: onComplete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _kLime.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, color: Colors.black, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Mark Complete',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending card ──────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final Exercise exercise;
  final int index;
  const _PendingCard({required this.exercise, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.sets} sets · ${exercise.reps}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

// ── Done card ─────────────────────────────────────────────────────────────────

class _DoneCard extends StatelessWidget {
  final Exercise exercise;
  final int index;
  const _DoneCard({required this.exercise, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              exercise.name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.3),
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded, size: 11, color: _kLime),
                const SizedBox(width: 4),
                Text(
                  'Done',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kLime,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white54),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          'No exercises scheduled.',
          style: GoogleFonts.inter(
              fontSize: 15, color: Colors.white.withValues(alpha: 0.35)),
        ),
      );
}

// ─── AI Coach FAB ─────────────────────────────────────────────────────────────

class _AiCoachFab extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  const _AiCoachFab({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? _kLime : _kCard,
            border: Border.all(
              color: isActive
                  ? _kLime
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isActive ? _kLime : Colors.black)
                    .withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            isActive
                ? Icons.close_rounded
                : Icons.smart_toy_rounded,
            color: isActive ? Colors.black : Colors.white,
            size: 22,
          ),
        ),
      );
}

// ─── Duration dialog ─────────────────────────────────────────────────────────

class _DurationDialog extends StatelessWidget {
  final TextEditingController controller;
  final void Function(double) onSave;
  final VoidCallback onCancel;

  const _DurationDialog({
    required this.controller,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trophy icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _kLime.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: _kLime,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Workout Complete!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'How long did your session take?',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _kDimWhite,
              ),
            ),
            const SizedBox(height: 20),
            // Duration input
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Minutes (e.g. 45)',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                suffixText: 'min',
                suffixStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kLime, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Actions
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final text = controller.text.trim();
                      final value = double.tryParse(text);
                      if (value == null || value <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Enter a valid duration',
                              style: GoogleFonts.inter(fontSize: 13)),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                        return;
                      }
                      onSave(value);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _kLime,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _kLime.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Plus FAB ─────────────────────────────────────────────────────────────────

class _PlusFab extends StatefulWidget {
  final VoidCallback onScanEquipment;
  final VoidCallback onAddExercise;

  const _PlusFab({
    required this.onScanEquipment,
    required this.onAddExercise,
  });

  @override
  State<_PlusFab> createState() => _PlusFabState();
}

class _PlusFabState extends State<_PlusFab>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  void _handleOption(VoidCallback action) {
    _toggle();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Option bubbles ───────────────────────────────────────────────
        FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            alignment: Alignment.bottomLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _OptionBubble(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan Equipment',
                  onTap: () => _handleOption(widget.onScanEquipment),
                ),
                const SizedBox(height: 10),
                _OptionBubble(
                  icon: Icons.fitness_center_rounded,
                  label: 'Add Exercise',
                  onTap: () => _handleOption(widget.onAddExercise),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        // ── Main + button ────────────────────────────────────────────────
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _open ? _kLime.withValues(alpha: 0.15) : _kCard,
              border: Border.all(
                color: _open
                    ? _kLime.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AnimatedRotation(
              turns: _open ? 0.125 : 0.0, // 45° when open
              duration: const Duration(milliseconds: 220),
              child: Icon(
                Icons.add_rounded,
                color: _open ? _kLime : _kLime,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionBubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionBubble({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF111318),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _kLime.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _kLime, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Scan equipment dialog ─────────────────────────────────────────────────────

enum _ScanState { idle, scanning, result, error }

class _ScanEquipmentDialog extends StatefulWidget {
  final String workoutDay;
  final String workoutFocus;
  final List<Map<String, dynamic>> exercises;

  const _ScanEquipmentDialog({
    required this.workoutDay,
    required this.workoutFocus,
    required this.exercises,
  });

  @override
  State<_ScanEquipmentDialog> createState() => _ScanEquipmentDialogState();
}

class _ScanEquipmentDialogState extends State<_ScanEquipmentDialog> {
  final _service = EquipmentScanService();
  final _picker = ImagePicker();

  _ScanState _state = _ScanState.idle;
  File? _capturedImage;
  EquipmentScanResult? _result;
  String _errorMsg = '';
  final Set<int> _selectedSuggestions = {};

  Future<void> _openCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _capturedImage = File(picked.path);
      _state = _ScanState.scanning;
    });

    try {
      final result = await _service.scanEquipment(
        image: _capturedImage!,
        workoutDay: widget.workoutDay,
        workoutFocus: widget.workoutFocus,
        exercises: widget.exercises,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _state = _ScanState.result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString().replaceFirst('DioException', '').trim();
        _state = _ScanState.error;
      });
    }
  }

  void _reset() => setState(() {
        _state = _ScanState.idle;
        _capturedImage = null;
        _result = null;
        _errorMsg = '';
        _selectedSuggestions.clear();
      });

  void _addSelectedToWorkout() {
    final r = _result!;
    final picked = _selectedSuggestions
        .map((i) => r.suggestedExercises[i])
        .map((ex) => Exercise(
              name: ex.name,
              sets: ex.sets,
              reps: ex.reps,
              notes: ex.why,
            ))
        .toList();
    Navigator.of(context).pop(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: switch (_state) {
            _ScanState.idle    => _buildIdle(),
            _ScanState.scanning => _buildScanning(),
            _ScanState.result  => _buildResult(),
            _ScanState.error   => _buildError(),
          },
        ),
      ),
    );
  }

  // ── Idle — prompt to open camera ──────────────────────────────────────────

  Widget _buildIdle() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _kLime.withValues(alpha: 0.25), width: 1.5),
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: _kLime, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan Gym Equipment',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Point your camera at any gym machine or equipment to identify it and check if it matches your ${widget.workoutFocus.isNotEmpty ? widget.workoutFocus : 'session'}.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, height: 1.55, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 28),
          _PrimaryButton(label: 'Open Camera', icon: Icons.camera_alt_rounded, onTap: _openCamera),
          const SizedBox(height: 12),
          _CancelText(onTap: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  // ── Scanning ──────────────────────────────────────────────────────────────

  Widget _buildScanning() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_capturedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_capturedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(color: _kLime, strokeWidth: 2.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Identifying equipment…',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Checking your ${widget.workoutFocus.isNotEmpty ? widget.workoutFocus : 'session'} plan',
            style: GoogleFonts.inter(fontSize: 12, color: _kDimWhite),
          ),
        ],
      ),
    );
  }

  // ── Result ────────────────────────────────────────────────────────────────

  Widget _buildResult() {
    final r = _result!;
    final aligned = r.alignsWithSession;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Equipment identity header
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (aligned ? _kLime : _kAmber).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: aligned ? _kLime : _kAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.equipmentName,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      r.primaryMuscleGroups.join(' · '),
                      style: GoogleFonts.inter(fontSize: 11, color: _kDimWhite),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Alignment banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (aligned ? _kLime : _kAmber).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (aligned ? _kLime : _kAmber).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  aligned ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                  color: aligned ? _kLime : _kAmber,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.alignmentReason,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.4,
                      color: aligned ? _kLime : _kAmber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Session exercises (when aligned and some match)
          if (aligned && r.matchedSessionExercises.isNotEmpty) ...[
            _SectionLabel(label: 'Matched Session Exercises', icon: Icons.list_alt_rounded, color: _kLime),
            const SizedBox(height: 10),
            ...r.matchedSessionExercises.map((ex) => _ExerciseRow(
              name: ex.name,
              sets: ex.sets,
              reps: ex.reps,
              subtitle: ex.notes,
              accentColor: _kLime,
            )),
            const SizedBox(height: 20),
          ],

          // Suggested / bonus exercises — selectable
          if (r.suggestedExercises.isNotEmpty) ...[
            _SectionLabel(
              label: aligned ? 'Bonus Exercises' : 'Suggested Alternatives',
              icon: aligned ? Icons.add_circle_outline_rounded : Icons.swap_horiz_rounded,
              color: aligned ? _kLime : _kAmber,
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to select exercises you want to add',
              style: GoogleFonts.inter(fontSize: 11, color: _kDimWhite),
            ),
            const SizedBox(height: 10),
            ...r.suggestedExercises.asMap().entries.map((entry) {
              final i = entry.key;
              final ex = entry.value;
              final selected = _selectedSuggestions.contains(i);
              final accentColor = aligned ? _kLime : _kAmber;
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selectedSuggestions.remove(i);
                  } else {
                    _selectedSuggestions.add(i);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? accentColor.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? accentColor.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.07),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? accentColor : Colors.transparent,
                          border: Border.all(
                            color: selected ? accentColor : Colors.white24,
                            width: 1.5,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded, color: Colors.black, size: 13)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ex.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (ex.why.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  ex.why,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: _kDimWhite,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${ex.sets} sets',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                          Text(
                            ex.reps,
                            style: GoogleFonts.inter(fontSize: 11, color: _kDimWhite),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 20),

          // Add to Workout button — only shown when something is selected
          if (_selectedSuggestions.isNotEmpty) ...[
            GestureDetector(
              onTap: _addSelectedToWorkout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _kLime,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _kLime.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Add ${_selectedSuggestions.length} Exercise${_selectedSuggestions.length > 1 ? 's' : ''} to Workout',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.add_rounded, color: Colors.black, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CancelText(label: 'Done', onTap: () => Navigator.of(context).pop()),
              GestureDetector(
                onTap: () { _reset(); _openCamera(); },
                child: Row(
                  children: [
                    const Icon(Icons.camera_alt_rounded, size: 14, color: _kDimWhite),
                    const SizedBox(width: 4),
                    Text(
                      'Scan Again',
                      style: GoogleFonts.inter(fontSize: 12, color: _kDimWhite),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
          ),
          const SizedBox(height: 16),
          Text('Scan Failed', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            _errorMsg.isNotEmpty ? _errorMsg : 'Could not identify the equipment. Please try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: _kDimWhite, height: 1.5),
          ),
          const SizedBox(height: 24),
          _PrimaryButton(label: 'Try Again', icon: Icons.refresh_rounded, onTap: () { _reset(); _openCamera(); }),
          const SizedBox(height: 12),
          _CancelText(onTap: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ────────────────────────────────────────────────────────

const _kAmber = Color(0xFFFFAA00);

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionLabel({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3),
        ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final String name;
  final int sets;
  final String reps;
  final String? subtitle;
  final Color accentColor;
  const _ExerciseRow({required this.name, required this.sets, required this.reps, this.subtitle, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(subtitle!, style: GoogleFonts.inter(fontSize: 11, color: _kDimWhite, height: 1.4)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$sets sets', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor)),
              Text(reps, style: GoogleFonts.inter(fontSize: 11, color: _kDimWhite)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _kLime,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _kLime.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.black, size: 17),
          ],
        ),
      ),
    );
  }
}

class _CancelText extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _CancelText({required this.onTap, this.label = 'Cancel'});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.4)),
      ),
    );
  }
}

// ─── Add exercise bottom sheet ────────────────────────────────────────────────

enum _AdvisorState { idle, loading, approved, warning, error }

class _AddExerciseSheet extends StatefulWidget {
  final String workoutFocus;
  final String workoutDay;
  final List<String> existingExercises;

  const _AddExerciseSheet({
    required this.workoutFocus,
    required this.workoutDay,
    required this.existingExercises,
  });

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  final _nameCtl  = TextEditingController();
  final _setsCtl  = TextEditingController();
  final _repsCtl  = TextEditingController();
  final _notesCtl = TextEditingController();
  final _advisor  = ExerciseAdvisorService();

  _AdvisorState _advisorState = _AdvisorState.idle;
  String _advisorMessage = '';
  bool _checkedOnce = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _setsCtl.dispose();
    _repsCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  Future<void> _checkWithAi() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _advisorState = _AdvisorState.loading;
      _checkedOnce  = true;
    });

    try {
      final advice = await _advisor.advise(
        exerciseName:      name,
        sets:              int.tryParse(_setsCtl.text.trim()),
        reps:              _repsCtl.text.trim().isNotEmpty ? _repsCtl.text.trim() : null,
        workoutDay:        widget.workoutDay,
        workoutFocus:      widget.workoutFocus,
        existingExercises: widget.existingExercises,
      );
      if (!mounted) return;
      setState(() {
        _advisorMessage = advice.message;
        _advisorState   = advice.verdict == ExerciseVerdict.approved
            ? _AdvisorState.approved
            : _AdvisorState.warning;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _advisorState   = _AdvisorState.error;
        _advisorMessage = 'Could not reach AI advisor. You can still add the exercise.';
      });
    }
  }

  void _addToWorkout() {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an exercise name', style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final sets = int.tryParse(_setsCtl.text.trim()) ?? 3;
    final reps = _repsCtl.text.trim().isNotEmpty ? _repsCtl.text.trim() : '8-12';
    final notes = _notesCtl.text.trim().isNotEmpty ? _notesCtl.text.trim() : null;

    Navigator.of(context).pop(
      Exercise(name: name, sets: sets, reps: reps, notes: notes),
    );
  }

  InputDecoration _fieldDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.28),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kLime, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ───────────────────────────────────────────
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // ── Header ────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _kLime.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.fitness_center_rounded, color: _kLime, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Exercise',
                          style: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white,
                          ),
                        ),
                        if (widget.workoutFocus.isNotEmpty)
                          Text(
                            widget.workoutFocus,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _kLime.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ── Exercise name ─────────────────────────────────────────
              Text('Exercise Name', style: _labelStyle()),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtl,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                decoration: _fieldDecor('e.g. Romanian Deadlift'),
                onChanged: (_) {
                  if (_checkedOnce) {
                    setState(() => _advisorState = _AdvisorState.idle);
                  }
                },
              ),
              const SizedBox(height: 14),
              // ── Sets & Reps row ───────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sets', style: _labelStyle()),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _setsCtl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                          decoration: _fieldDecor('4'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reps', style: _labelStyle()),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _repsCtl,
                          keyboardType: TextInputType.text,
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                          decoration: _fieldDecor('8–12'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ── Notes ─────────────────────────────────────────────────
              Text('Notes (optional)', style: _labelStyle()),
              const SizedBox(height: 6),
              TextField(
                controller: _notesCtl,
                maxLines: 2,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                decoration: _fieldDecor('e.g. Slow eccentric, keep core tight'),
              ),
              const SizedBox(height: 20),
              // ── AI Advisor ────────────────────────────────────────────
              _AiAdvisorCard(
                state: _advisorState,
                message: _advisorMessage,
                onCheck: _checkWithAi,
                exerciseName: _nameCtl.text.trim(),
              ),
              const SizedBox(height: 20),
              // ── Actions ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _addToWorkout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _kLime,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _kLime.withValues(alpha: 0.25),
                              blurRadius: 14, offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Add to Workout',
                              style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.add_rounded, color: Colors.black, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.45),
        letterSpacing: 0.4,
      );
}

// ─── AI Advisor card ──────────────────────────────────────────────────────────

class _AiAdvisorCard extends StatelessWidget {
  final _AdvisorState state;
  final String message;
  final VoidCallback onCheck;
  final String exerciseName;

  const _AiAdvisorCard({
    required this.state,
    required this.message,
    required this.onCheck,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _bgColor(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor(), width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: _body(context),
      ),
    );
  }

  Color _bgColor() {
    return switch (state) {
      _AdvisorState.approved => const Color(0xFF0A1A06),
      _AdvisorState.warning  => const Color(0xFF1A1206),
      _AdvisorState.error    => const Color(0xFF1A0A06),
      _                      => const Color(0xFF0F1119),
    };
  }

  Color _borderColor() {
    return switch (state) {
      _AdvisorState.approved => const Color(0xFF4CAF50).withValues(alpha: 0.3),
      _AdvisorState.warning  => const Color(0xFFFFAA00).withValues(alpha: 0.3),
      _AdvisorState.error    => Colors.red.withValues(alpha: 0.25),
      _                      => Colors.white.withValues(alpha: 0.08),
    };
  }

  Widget _body(BuildContext context) {
    return switch (state) {
      _AdvisorState.idle    => _idleBody(),
      _AdvisorState.loading => _loadingBody(),
      _AdvisorState.approved || _AdvisorState.warning || _AdvisorState.error =>
        _resultBody(),
    };
  }

  Widget _idleBody() {
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _kLime.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.smart_toy_rounded, color: _kLime, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Check with AI Advisor',
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ),
        GestureDetector(
          onTap: exerciseName.isNotEmpty ? onCheck : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: exerciseName.isNotEmpty
                  ? _kLime.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: exerciseName.isNotEmpty
                    ? _kLime.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              'Check',
              style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: exerciseName.isNotEmpty
                    ? _kLime
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _loadingBody() {
    return Row(
      children: [
        const SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_kLime),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'Analysing with AI…',
          style: GoogleFonts.inter(
            fontSize: 13, color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _resultBody() {
    final (icon, iconColor) = switch (state) {
      _AdvisorState.approved => (Icons.check_circle_rounded,    const Color(0xFF4CAF50)),
      _AdvisorState.warning  => (Icons.warning_amber_rounded,   const Color(0xFFFFAA00)),
      _                      => (Icons.error_outline_rounded,   Colors.redAccent),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13, height: 1.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onCheck,
                child: Text(
                  'Re-check',
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.4),
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Add-note bottom sheet ────────────────────────────────────────────────────

class _AddNoteSheet extends StatefulWidget {
  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kLime.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                      Icons.edit_note_rounded, color: _kLime, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Add a note',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 4,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'How\'s the session feeling? Log anything here…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kLime, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Center(
                        child: Text(
                          'Discard',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _kLime,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _kLime.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Save Note',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rest-time confirmation dialog ────────────────────────────────────────────

class _RestTimeDialog extends StatefulWidget {
  final int? prefilledSecs;
  final void Function(int) onContinue;
  final VoidCallback onSkip;

  const _RestTimeDialog({
    required this.onContinue,
    required this.onSkip,
    this.prefilledSecs,
  });

  @override
  State<_RestTimeDialog> createState() => _RestTimeDialogState();
}

class _RestTimeDialogState extends State<_RestTimeDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.prefilledSecs != null ? '${widget.prefilledSecs}' : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _kLime.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.timer_rounded, color: _kLime, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              'Average Rest Time',
              style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.prefilledSecs != null
                  ? 'We tracked ~${widget.prefilledSecs}s avg between exercises. Adjust if needed.'
                  : 'How many seconds did you rest between exercises on average?',
              style: GoogleFonts.inter(fontSize: 13, color: _kDimWhite, height: 1.5),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Seconds (e.g. 60)',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14, color: Colors.white.withValues(alpha: 0.3),
                ),
                suffixText: 'sec',
                suffixStyle: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kLime, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onSkip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Center(
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final v = int.tryParse(_ctrl.text.trim());
                      widget.onContinue(v != null && v > 0 ? v : 60);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _kLime,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _kLime.withValues(alpha: 0.25),
                            blurRadius: 16, offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Analyse',
                          style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Workout analysis bottom sheet ────────────────────────────────────────────

class _WorkoutAnalysisSheet extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;
  final int durationMins;
  final int avgRestSecs;
  final String? workoutDay;
  final String? focus;
  final String? sessionId;
  final VoidCallback? onDone;

  const _WorkoutAnalysisSheet({
    required this.exercises,
    required this.durationMins,
    required this.avgRestSecs,
    this.workoutDay,
    this.focus,
    this.sessionId,
    this.onDone,
  });

  @override
  State<_WorkoutAnalysisSheet> createState() => _WorkoutAnalysisSheetState();
}

class _WorkoutAnalysisSheetState extends State<_WorkoutAnalysisSheet> {
  final _service    = WorkoutSessionAnalysisService();
  final _workoutLog = sl<WorkoutLogRemoteDataSource>();
  WorkoutSessionAnalysis? _result;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    try {
      final result = await _service.analyse(
        exercises: widget.exercises,
        durationMins: widget.durationMins,
        avgRestSecs: widget.avgRestSecs,
        workoutDay: widget.workoutDay,
        focus: widget.focus,
      );
      if (mounted) setState(() { _result = result; _loading = false; });

      // Persist feedback to the session row in the background.
      if (widget.sessionId != null) {
        _workoutLog.saveFeedback(
          sessionId: widget.sessionId!,
          feedback: {
            'session_analysis':       result.sessionAnalysis,
            'performance_highlights': result.performanceHighlights,
            'areas_to_improve':       result.areasToImprove,
            'rest_feedback':          result.restFeedback,
            'next_session_tip':       result.nextSessionTip,
            'nutrition_advice': {
              'immediate':        result.nutrition.immediate,
              'protein_target_g': result.nutrition.proteinTargetG,
              'meal_suggestions': result.nutrition.mealSuggestions,
              'hydration':        result.nutrition.hydration,
              'timing_tip':       result.nutrition.timingTip,
            },
          },
        ).catchError((_) {}); // fire-and-forget; don't block the UI
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _kLime.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.auto_graph_rounded, color: _kLime, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Analysis',
                            style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
                            ),
                          ),
                          Text(
                            '${widget.durationMins} min · ${widget.exercises.length} exercises · ${widget.avgRestSecs}s avg rest',
                            style: GoogleFonts.inter(fontSize: 12, color: _kDimWhite),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close_rounded, color: Colors.white38, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
              ],
            ),
          ),
          Flexible(
            child: _loading
                ? _buildLoading()
                : _error != null
                    ? _buildError()
                    : _buildContent(_result!),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36, height: 36,
              child: CircularProgressIndicator(color: _kLime, strokeWidth: 2.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Analysing your session…',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
          const SizedBox(height: 16),
          Text(
            'Could not load analysis',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: _kDimWhite, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(WorkoutSessionAnalysis r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnalysisCard(
            icon: Icons.assessment_rounded,
            color: _kLime,
            title: 'Session Overview',
            content: r.sessionAnalysis,
          ),
          const SizedBox(height: 14),
          if (r.restFeedback.isNotEmpty) ...[
            _AnalysisCard(
              icon: Icons.timer_rounded,
              color: const Color(0xFF64B5F6),
              title: 'Rest Strategy',
              content: r.restFeedback,
            ),
            const SizedBox(height: 14),
          ],
          if (r.performanceHighlights.isNotEmpty) ...[
            _BulletSection(
              icon: Icons.star_rounded,
              color: const Color(0xFF4CAF50),
              title: 'Performance Highlights',
              items: r.performanceHighlights,
            ),
            const SizedBox(height: 14),
          ],
          if (r.areasToImprove.isNotEmpty) ...[
            _BulletSection(
              icon: Icons.trending_up_rounded,
              color: _kAmber,
              title: 'Areas to Improve',
              items: r.areasToImprove,
            ),
            const SizedBox(height: 14),
          ],
          _NutritionSection(nutrition: r.nutrition),
          const SizedBox(height: 14),
          if (r.nextSessionTip.isNotEmpty) ...[
            _AnalysisCard(
              icon: Icons.tips_and_updates_rounded,
              color: _kLime,
              title: 'Next Session Tip',
              content: r.nextSessionTip,
            ),
            const SizedBox(height: 14),
          ],

          // Done button — updates streak when user has read the analysis
          GestureDetector(
            onTap: widget.onDone,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _kLime,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _kLime.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Done · Update Streak',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String content;

  const _AnalysisCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: color, letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 13, height: 1.55, color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;

  const _BulletSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: color, letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(top: 5, right: 8),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 13, height: 1.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _NutritionSection extends StatelessWidget {
  final PostWorkoutNutrition nutrition;
  const _NutritionSection({required this.nutrition});

  static const _blue = Color(0xFF64B5F6);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_rounded, color: _blue, size: 16),
              const SizedBox(width: 6),
              Text(
                'Post-Workout Nutrition',
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: _blue, letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kLime.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${nutrition.proteinTargetG}g protein',
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _kLime,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (nutrition.immediate.isNotEmpty) ...[
            Text(
              'RIGHT NOW',
              style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.4), letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              nutrition.immediate,
              style: GoogleFonts.inter(
                fontSize: 13, height: 1.5, color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (nutrition.timingTip.isNotEmpty) ...[
            Text(
              'TIMING',
              style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.4), letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              nutrition.timingTip,
              style: GoogleFonts.inter(
                fontSize: 13, height: 1.5, color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (nutrition.mealSuggestions.isNotEmpty) ...[
            Text(
              'MEAL IDEAS',
              style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.4), letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            ...nutrition.mealSuggestions.map((meal) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 8),
                    decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(
                      meal,
                      style: GoogleFonts.inter(
                        fontSize: 13, height: 1.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          if (nutrition.hydration.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.water_drop_rounded, color: _blue, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    nutrition.hydration,
                    style: GoogleFonts.inter(
                      fontSize: 12, height: 1.4,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
