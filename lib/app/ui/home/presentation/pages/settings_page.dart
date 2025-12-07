import 'dart:io';

import 'package:fitness/app/core/di.dart' as di;
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/storage/domain/entities/stored_fitness_plan_entity.dart';
import 'package:fitness/app/storage/domain/usecases/get_all_fitness_plans_usecase.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<StoredFitnessPlanEntity> _storedPlans = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStoredPlans();
  }

  Future<void> _loadStoredPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final getAllFitnessPlansUsecase = di.sl<GetAllFitnessPlansUsecase>();
      final plans = await getAllFitnessPlansUsecase();
      setState(() {
        _storedPlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading plans: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalete.backgroundColorBk,
      appBar: AppBar(
        backgroundColor: AppPalete.backgroundColorBk,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppPalete.whiteColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Fitness Plans',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppPalete.whiteColor,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppPalete.whiteColor,
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppPalete.whiteColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppPalete.whiteColor.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadStoredPlans,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalete.whiteColor,
                            foregroundColor: AppPalete.backgroundColorBk,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _storedPlans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: AppPalete.whiteColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No fitness plans yet',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppPalete.whiteColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generate your first plan to see it here',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppPalete.whiteColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStoredPlans,
                        color: AppPalete.whiteColor,
                        backgroundColor: AppPalete.backgroundColorBk,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _storedPlans.length,
                          itemBuilder: (context, index) {
                            final plan = _storedPlans[index];
                            return _FitnessPlanCard(plan: plan);
                          },
                        ),
                      ),
      ),
    );
  }
}

class _FitnessPlanCard extends StatelessWidget {
  final StoredFitnessPlanEntity plan;

  const _FitnessPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to plan details page
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppPalete.borderColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppPalete.borderColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: plan.imagePath != null
                    ? FutureBuilder<bool>(
                        future: File(plan.imagePath!).exists(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              color: AppPalete.borderColor.withOpacity(0.5),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppPalete.whiteColor,
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasData && snapshot.data == true) {
                            return Image.file(
                              File(plan.imagePath!),
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color:
                                      AppPalete.borderColor.withOpacity(0.5),
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: AppPalete.whiteColor,
                                    size: 40,
                                  ),
                                );
                              },
                            );
                          }
                          return Container(
                            color: AppPalete.borderColor.withOpacity(0.5),
                            child: const Icon(
                              Icons.fitness_center,
                              color: AppPalete.whiteColor,
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppPalete.borderColor.withOpacity(0.5),
                        child: const Icon(
                          Icons.fitness_center,
                          color: AppPalete.whiteColor,
                          size: 40,
                        ),
                      ),
              ),
            ),
            // Info Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.workoutPlan.plan.goal,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppPalete.whiteColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.workoutPlan.plan.focus,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppPalete.whiteColor.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(plan.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppPalete.whiteColor.withOpacity(0.5),
                          ),
                        ),
                        if (plan.isSynced)
                          const Icon(
                            Icons.cloud_done,
                            size: 16,
                            color: Colors.green,
                          )
                        else
                          const Icon(
                            Icons.cloud_off,
                            size: 16,
                            color: Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

