import 'dart:io';

import 'package:fitness/data/services/fitness/progress_photo_service.dart';
import 'package:fitness/ui/core/constants/assets.dart';
import 'package:fitness/ui/core/di.dart';
import 'package:fitness/domain/use_cases/auth/get_current_user.dart';
import 'package:fitness/domain/use_cases/fitness/get_user_data_usecase.dart';
import 'package:fitness/ui/features/onboarding/views/onboarding_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Design tokens (BeFit dark brand) ─────────────────────────────────────────
const _kBg      = Color(0xFF0A0C12);
const _kCard    = Color(0xFF111318);
const _kCard2   = Color(0xFF161B26);
const _kBorder  = Color(0xFF1E2330);
const _kText    = Color(0xFFFFFFFF);
const _kSub     = Color(0x80FFFFFF);
const _kLime    = Color(0xFFCCFF00);
const _kAmber   = Color(0xFFFFAA00);
const _kBlue    = Color(0xFF4D9EFF);
const _kPurple  = Color(0xFFB47EFF);

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final GetUserDataUsecase _getUserDataUsecase = sl<GetUserDataUsecase>();
  final GetCurrentUser _getCurrentUser = sl<GetCurrentUser>();

  List<FlSpot> _dailySpots   = [];
  List<FlSpot> _monthlySpots = [];
  List<FlSpot> _yearlySpots  = [];

  double _totalDuration    = 0.0;
  double _workoutPct       = 0.0;
  int    _uniqueWorkoutDays = 0;
  bool   _isLoading        = true;
  int    _chartIndex       = 0; // 0=D 1=M 2=Y

  // Body weight — seeded from onboarding, overridable by the user
  double? _bodyWeight;          // stored in _weightUnit
  String  _weightUnit   = 'kg'; // the unit the value is stored in
  String  _displayUnit  = 'kg'; // the unit currently shown (toggled by user)

  static const _kWeightKey     = 'logged_body_weight';
  static const _kWeightUnitKey = 'logged_body_weight_unit';

  static const _kgToLbs = 2.20462;
  static const _lbsToKg = 0.453592;

  /// Value converted into the currently selected display unit.
  double? get _displayWeight {
    if (_bodyWeight == null) return null;
    if (_weightUnit == _displayUnit) return _bodyWeight;
    return _displayUnit == 'lbs'
        ? _bodyWeight! * _kgToLbs
        : _bodyWeight! * _lbsToKg;
  }

  void _toggleWeightUnit() {
    setState(() => _displayUnit = _displayUnit == 'kg' ? 'lbs' : 'kg');
  }

  // Progress photos
  final _photoService = ProgressPhotoService();
  List<ProgressPhoto> _photos = [];
  bool _photosLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadPhotos();
    _loadBodyWeight();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final user = _getCurrentUser();
      if (user?.id != null) {
        final rows = await _getUserDataUsecase(user!.id);
        if (rows.isNotEmpty) {
          final userData = rows.first;
          final List<Map<String, dynamic>> entries = [];
          if (userData['date_n_duration'] is List) {
            for (final e in userData['date_n_duration'] as List) {
              if (e is Map<String, dynamic> &&
                  e['date'] != null && e['duration'] != null) {
                entries.add(e);
              }
            }
          }
          entries.sort((a, b) {
            try { return DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])); }
            catch (_) { return 0; }
          });

          _totalDuration = entries.fold(0.0, (s, e) =>
              s + ((e['duration'] as num?)?.toDouble() ?? 0));

          final now = DateTime.now();
          final uniqueDates = <String>{};
          for (final e in entries) {
            try {
              final d = DateTime.parse(e['date']);
              uniqueDates.add('${d.year}-${d.month}-${d.day}');
            } catch (_) {}
          }
          _uniqueWorkoutDays = uniqueDates.length;
          _workoutPct = now.day > 0
              ? (_uniqueWorkoutDays / now.day * 100).clamp(0, 100)
              : 0;

          _generateSpots(entries, now);
        }
      }
    } catch (e) {
      debugPrint('StatisticsPage: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBodyWeight() async {
    try {
      // 1. Check for a manually saved weight override first
      final box = await Hive.openBox('onboarding_data');
      final saved = box.get(_kWeightKey);
      final savedUnit = box.get(_kWeightUnitKey) as String?;
      if (saved != null) {
        final v    = (saved as num).toDouble();
        final unit = savedUnit ?? 'kg';
        if (mounted) setState(() {
          _bodyWeight   = v;
          _weightUnit   = unit;
          _displayUnit  = unit;
        });
        return;
      }

      // 2. Fall back to the weight the user entered during onboarding
      final data = await OnboardingStorage.loadOnboardingData();
      if (data?.weight != null && data!.weight!.isNotEmpty) {
        final raw   = data.weight!.trim();
        // Format is "75 kg" or "165 lbs"
        final parts = raw.split(' ');
        final value = double.tryParse(parts.first);
        final unit  = parts.length > 1 ? parts.last : 'kg';
        if (value != null && mounted) {
          setState(() {
            _bodyWeight  = value;
            _weightUnit  = unit;
            _displayUnit = unit;
          });
        }
      }
    } catch (e) {
      debugPrint('StatisticsPage: weight load error: $e');
    }
  }

  void _generateSpots(List<Map<String, dynamic>> entries, DateTime now) {
    // Daily — last 7 days
    final dailyMap = <int, double>{};
    for (final e in entries) {
      try {
        final d = DateTime.parse(e['date']);
        final daysAgo = now.difference(DateTime(d.year, d.month, d.day)).inDays;
        if (daysAgo <= 6) {
          final x = 6 - daysAgo;
          dailyMap[x] = (dailyMap[x] ?? 0) + ((e['duration'] as num?)?.toDouble() ?? 0);
        }
      } catch (_) {}
    }
    _dailySpots = List.generate(7, (i) => FlSpot(i.toDouble(), dailyMap[i] ?? 0));

    // Monthly — last 12 months
    final monthMap = <int, double>{};
    for (final e in entries) {
      try {
        final d = DateTime.parse(e['date']);
        final monthsAgo = (now.year - d.year) * 12 + (now.month - d.month);
        if (monthsAgo <= 11) {
          final x = 11 - monthsAgo;
          monthMap[x] = (monthMap[x] ?? 0) + ((e['duration'] as num?)?.toDouble() ?? 0);
        }
      } catch (_) {}
    }
    _monthlySpots = List.generate(12, (i) => FlSpot(i.toDouble(), monthMap[i] ?? 0));
    _yearlySpots  = List.from(_monthlySpots);
  }

  List<FlSpot> get _currentSpots =>
      _chartIndex == 0 ? _dailySpots : _chartIndex == 1 ? _monthlySpots : _yearlySpots;

  double get _maxY {
    if (_currentSpots.isEmpty) return 60;
    final m = _currentSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return (m * 1.3).ceilToDouble().clamp(10, double.infinity);
  }

  String _avatarUrl() {
    try {
      return Supabase.instance.client.auth.currentUser
              ?.userMetadata?['avatar_url'] as String? ?? '';
    } catch (_) { return ''; }
  }

  // ── Progress photos ────────────────────────────────────────────────────────
  Future<void> _loadPhotos() async {
    if (!mounted) return;
    setState(() => _photosLoading = true);
    try {
      _photos = await _photoService.getAllPhotos();
    } catch (e) {
      debugPrint('Progress photos load error: $e');
    } finally {
      if (mounted) setState(() => _photosLoading = false);
    }
  }

  Future<void> _addProgressPhoto(ImageSource source) async {
    try {
      final xfile = await ImagePicker().pickImage(
          source: source, imageQuality: 85, maxWidth: 1080);
      if (xfile == null || !mounted) return;
      final relativePath = await _photoService.saveImageFile(File(xfile.path));
      await _photoService.addPhoto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        relativePath: relativePath,
        takenAt: DateTime.now(),
      );
      await _loadPhotos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFFF4D4D),
        ));
      }
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111318),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF1E2330))),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('Add Progress Photo', style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: Colors.white)),
          const SizedBox(height: 6),
          Text('Track your transformation over time',
              style: GoogleFonts.inter(fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 24),
          _SourceButton(
            icon: Icons.camera_alt_rounded,
            label: 'Take Photo',
            onTap: () {
              Navigator.pop(context);
              _addProgressPhoto(ImageSource.camera);
            },
          ),
          const SizedBox(height: 12),
          _SourceButton(
            icon: Icons.photo_library_rounded,
            label: 'Choose from Gallery',
            onTap: () {
              Navigator.pop(context);
              _addProgressPhoto(ImageSource.gallery);
            },
          ),
        ]),
      ),
    );
  }

  void _openPhotoViewer(int initialIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PhotoViewerPage(
        photos: _photos,
        initialIndex: initialIndex,
        onDelete: (photo) async {
          await _photoService.deletePhoto(photo);
          await _loadPhotos();
        },
      ),
    ));
  }

  // ── Body weight input ──────────────────────────────────────────────────────
  void _showWeightInput() {
    final ctrl = TextEditingController(
        text: _displayWeight != null ? _displayWeight!.toStringAsFixed(1) : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Update Body Weight', style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700, color: _kText)),
            const SizedBox(height: 4),
            Text('Onboarding: ${_bodyWeight != null ? "${_bodyWeight!.toStringAsFixed(1)} $_weightUnit" : "not set"}',
                style: GoogleFonts.inter(fontSize: 12, color: _kSub)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: _kText),
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle: GoogleFonts.poppins(fontSize: 32, color: _kSub),
                suffixText: _weightUnit,
                suffixStyle: GoogleFonts.poppins(fontSize: 20, color: _kSub),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kLime, foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                onPressed: () async {
                  final typed = double.tryParse(ctrl.text.trim());
                  if (typed != null) {
                    // Convert display value back to storage unit before saving
                    final stored = _displayUnit == _weightUnit
                        ? typed
                        : _displayUnit == 'lbs'
                            ? typed * _lbsToKg   // entered lbs, store kg
                            : typed * _kgToLbs;  // entered kg, store lbs
                    setState(() => _bodyWeight = stored);
                    try {
                      final box = await Hive.openBox('onboarding_data');
                      await box.put(_kWeightKey, stored);
                      await box.put(_kWeightUnitKey, _weightUnit);
                    } catch (_) {}
                  }
                  if (mounted) Navigator.pop(context);
                },
                child: Text('Save', style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _avatarUrl();
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  // App logo
                  Image.asset(ImagePath.appLogo, width: 52, height: 52),
                  const Spacer(),
                  // Avatar
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kLime.withValues(alpha: 0.15),
                      border: Border.all(color: _kLime.withValues(alpha: 0.3), width: 1.5),
                      image: avatarUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: avatarUrl.isEmpty
                        ? Icon(Icons.person_rounded,
                            color: _kLime.withValues(alpha: 0.8), size: 20)
                        : null,
                  ),
                ]),
              ),
            ),

            // ── Title ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Text('Analytics', style: GoogleFonts.poppins(
                    fontSize: 32, fontWeight: FontWeight.w800, color: _kText)),
              ),
            ),

            // ── 2×2 stat grid ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _StatCard(
                      label: 'Streak',
                      icon: _CircleBadge(
                        color: _kLime,
                        child: Icon(Icons.trending_up_rounded,
                            color: _kLime, size: 20),
                      ),
                      child: _isLoading
                          ? _shimmer()
                          : Text(
                              '$_uniqueWorkoutDays ${_uniqueWorkoutDays == 1 ? "day" : "days"}',
                              style: GoogleFonts.poppins(
                                  fontSize: 24, fontWeight: FontWeight.w800,
                                  color: _kText),
                            ),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(
                      label: 'Workouts',
                      icon: _CircleBadge(
                        color: _kPurple,
                        child: Icon(Icons.fitness_center_rounded,
                            color: _kPurple, size: 18),
                      ),
                      child: _isLoading
                          ? _shimmer()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$_uniqueWorkoutDays',
                                    style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: _kText)),
                                const SizedBox(height: 2),
                                Row(children: [
                                  Icon(Icons.warning_amber_rounded,
                                      size: 13, color: _kAmber),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(
                                    'This month so far',
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: _kSub),
                                    overflow: TextOverflow.ellipsis,
                                  )),
                                ]),
                              ],
                            ),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _StatCard(
                      label: 'Total Time',
                      icon: _CircleBadge(
                        color: _kAmber,
                        child: Icon(Icons.local_fire_department_rounded,
                            color: _kAmber, size: 20),
                      ),
                      child: _isLoading
                          ? _shimmer()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Mini progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: (_workoutPct / 100).clamp(0, 1),
                                    minHeight: 4,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.07),
                                    color: _kLime,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${_totalDuration.toStringAsFixed(0)} min',
                                  style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _kText),
                                ),
                                const SizedBox(height: 2),
                                Row(children: [
                                  Icon(Icons.warning_amber_rounded,
                                      size: 13, color: _kAmber),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(
                                    'Tap to improve accuracy…',
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: _kSub),
                                    overflow: TextOverflow.ellipsis,
                                  )),
                                ]),
                              ],
                            ),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(
                      label: 'Body Weight',
                      icon: _CircleBadge(
                        color: _kBlue,
                        child: Icon(Icons.accessibility_new_rounded,
                            color: _kBlue, size: 20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  _displayWeight != null
                                      ? '${_displayWeight!.toStringAsFixed(1)} $_displayUnit'
                                      : '--',
                                  style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _kText),
                                ),
                              ),
                              GestureDetector(
                                onTap: _showWeightInput,
                                child: Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(
                                    color: _kLime.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: _kLime.withValues(alpha: 0.3)),
                                  ),
                                  child: Icon(Icons.edit_rounded,
                                      size: 15, color: _kLime),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // kg / lbs toggle pill
                          GestureDetector(
                            onTap: _toggleWeightUnit,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _kBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _kBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: ['kg', 'lbs'].map((u) {
                                  final selected = _displayUnit == u;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: selected ? _kBlue : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(u,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: selected
                                              ? Colors.white
                                              : _kSub,
                                        )),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ]),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Chart card ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ChartCard(
                  isLoading: _isLoading,
                  chartIndex: _chartIndex,
                  spots: _currentSpots,
                  maxY: _maxY,
                  onIndexChanged: (i) => setState(() => _chartIndex = i),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Progress photos ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ProgressPhotosCard(
                  photos: _photos,
                  isLoading: _photosLoading,
                  onAdd: _showPhotoSourceSheet,
                  onTap: _openPhotoViewer,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Exercise history empty state ──────────────────────────────────
            if (!_isLoading && _currentSpots.every((s) => s.y == 0))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(children: [
                    Icon(Icons.menu_book_rounded, size: 44, color: _kSub.withValues(alpha: 0.4)),
                    const SizedBox(height: 10),
                    Text('No exercise history', style: GoogleFonts.poppins(
                        fontSize: 15, color: _kSub)),
                  ]),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _shimmer() => Container(
    height: 22, width: 80,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final Widget icon;
  final Widget child;
  const _StatCard({required this.label, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500, color: _kSub)),
        icon,
      ]),
      const SizedBox(height: 16),
      child,
    ]),
  );
}

// ── Circle badge ──────────────────────────────────────────────────────────────

class _CircleBadge extends StatelessWidget {
  final Color color;
  final Widget child;
  const _CircleBadge({required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: 0.1),
      border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
    ),
    child: Center(child: child),
  );
}

// ── Chart card ────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final bool isLoading;
  final int chartIndex;
  final List<FlSpot> spots;
  final double maxY;
  final void Function(int) onIndexChanged;

  const _ChartCard({
    required this.isLoading, required this.chartIndex,
    required this.spots, required this.maxY, required this.onIndexChanged,
  });

  static const _labels = ['D', 'M', 'Y'];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthLabels = ['J','F','M','A','M','J','J','A','S','O','N','D'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Workout Duration', style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700, color: _kText)),
          const Spacer(),
          // D / M / Y toggle
          Container(
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: List.generate(3, (i) {
                final selected = chartIndex == i;
                return GestureDetector(
                  onTap: () => onIndexChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? _kLime : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_labels[i], style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: selected ? Colors.black : _kSub,
                    )),
                  ),
                );
              }),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        isLoading
            ? const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_kLime))))
            : SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.white.withValues(alpha: 0.05),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (value, _) {
                            final i = value.toInt();
                            String label = '';
                            if (chartIndex == 0 && i >= 0 && i < _dayLabels.length) {
                              label = _dayLabels[i];
                            } else if (chartIndex != 0 && i >= 0 && i < _monthLabels.length) {
                              label = _monthLabels[i];
                            }
                            return Text(label, style: GoogleFonts.inter(
                                fontSize: 10, color: _kSub));
                          },
                        ),
                      ),
                    ),
                    minX: 0,
                    maxX: (spots.length - 1).toDouble().clamp(1, 100),
                    minY: 0,
                    maxY: maxY,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => _kCard2,
                        getTooltipItems: (spots) => spots.map((s) =>
                          LineTooltipItem(
                            '${s.y.round()} min',
                            GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: _kLime),
                          )).toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: _kLime,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _kLime.withValues(alpha: 0.15),
                              _kLime.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                ),
              ),
      ]),
    );
  }
}

// ── Progress photos card ──────────────────────────────────────────────────────

class _ProgressPhotosCard extends StatelessWidget {
  final List<ProgressPhoto> photos;
  final bool isLoading;
  final VoidCallback onAdd;
  final void Function(int index) onTap;

  const _ProgressPhotosCard({
    required this.photos,
    required this.isLoading,
    required this.onAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kLime.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.photo_camera_rounded, color: _kLime, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Progress Photos', style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w700, color: _kText)),
            Text('${photos.length} photo${photos.length == 1 ? "" : "s"}',
                style: GoogleFonts.inter(fontSize: 11, color: _kSub)),
          ])),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _kLime.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kLime.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_rounded, color: _kLime, size: 16),
                const SizedBox(width: 4),
                Text('Add', style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w700, color: _kLime)),
              ]),
            ),
          ),
        ]),

        const SizedBox(height: 16),

        if (isLoading)
          SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(_kLime))),
          )
        else if (photos.isEmpty)
          _EmptyPhotos(onAdd: onAdd)
        else
          _PhotoStrip(photos: photos, onTap: onTap),
      ]),
    );
  }
}

class _EmptyPhotos extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyPhotos({required this.onAdd});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onAdd,
    child: Container(
      height: 130,
      decoration: BoxDecoration(
        color: _kCard2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _kLime.withValues(alpha: 0.15), style: BorderStyle.solid),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_rounded,
            size: 36, color: _kLime.withValues(alpha: 0.4)),
        const SizedBox(height: 8),
        Text('Add your first photo', style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 4),
        Text('Track your body changes over time',
            style: GoogleFonts.inter(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.25))),
      ]),
    ),
  );
}

class _PhotoStrip extends StatelessWidget {
  final List<ProgressPhoto> photos;
  final void Function(int) onTap;
  const _PhotoStrip({required this.photos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: photos.length + 1, // +1 for add button at end
        itemBuilder: (context, i) {
          if (i == photos.length) {
            // "Add more" cell
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () =>
                    (context.findAncestorWidgetOfExactType<_ProgressPhotosCard>()
                            as dynamic)
                        ?.onAdd(),
                child: Container(
                  width: 95,
                  decoration: BoxDecoration(
                    color: _kCard2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.add_rounded,
                        color: Colors.white.withValues(alpha: 0.3), size: 28),
                    const SizedBox(height: 4),
                    Text('Add', style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.3))),
                  ]),
                ),
              ),
            );
          }

          final photo = photos[i];
          final isFirst = i == 0;
          return Padding(
            padding: EdgeInsets.only(right: 10, left: isFirst ? 0 : 0),
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Stack(children: [
                Container(
                  width: 95,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isFirst
                            ? _kLime.withValues(alpha: 0.4)
                            : _kBorder),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Image.file(
                    File(photo.localPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _kCard2,
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.white.withValues(alpha: 0.2), size: 28),
                    ),
                  ),
                ),
                // Date label
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(14)),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      DateFormat('MMM d').format(photo.takenAt),
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isFirst ? _kLime : Colors.white),
                    ),
                  ),
                ),
                // "Latest" badge on first photo
                if (isFirst)
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kLime,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('LATEST', style: GoogleFonts.inter(
                          fontSize: 8, fontWeight: FontWeight.w900,
                          color: Colors.black)),
                    ),
                  ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ── Source picker button ──────────────────────────────────────────────────────

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _kCard2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: _kLime, size: 20),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600, color: _kText)),
      ]),
    ),
  );
}

// ── Full-screen photo viewer ──────────────────────────────────────────────────

class _PhotoViewerPage extends StatefulWidget {
  final List<ProgressPhoto> photos;
  final int initialIndex;
  final Future<void> Function(ProgressPhoto) onDelete;

  const _PhotoViewerPage({
    required this.photos,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<_PhotoViewerPage> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111318),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Photo?', style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, color: Colors.white)),
        content: Text('This cannot be undone.',
            style: GoogleFonts.inter(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(
                color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.onDelete(widget.photos[_current]);
              if (mounted) Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.inter(
                color: const Color(0xFFFF4D4D),
                fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_current];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Swipeable photos
        PageView.builder(
          controller: _ctrl,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) {
            final p = widget.photos[i];
            return InteractiveViewer(
              child: Center(
                child: Image.file(
                  File(p.localPath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white24, size: 64),
                ),
              ),
            );
          },
        ),

        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              _IconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              // Counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_current + 1} / ${widget.photos.length}',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
              const Spacer(),
              _IconBtn(
                icon: Icons.delete_outline_rounded,
                onTap: _confirmDelete,
                color: const Color(0xFFFF4D4D),
              ),
            ]),
          ),
        ),

        // Bottom date + note strip
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, y').format(photo.takenAt),
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                if (photo.note != null && photo.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(photo.note!,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6))),
                ],
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}
