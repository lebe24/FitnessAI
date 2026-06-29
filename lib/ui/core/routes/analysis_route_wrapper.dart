import 'package:fitness/ui/features/home/views/analysis_page.dart';
import 'package:fitness/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/ui/features/onboarding/views/onboarding_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnalysisPageWithData extends StatefulWidget {
  const AnalysisPageWithData({super.key});

  @override
  State<AnalysisPageWithData> createState() => _AnalysisPageWithDataState();
}

class _AnalysisPageWithDataState extends State<AnalysisPageWithData> {
  OnboardingData? _loadedData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOnboardingData();
  }

  Future<void> _loadOnboardingData() async {
    final data = await OnboardingStorage.loadOnboardingData();
    setState(() {
      _loadedData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Create bloc with loaded data
    final initialData = _loadedData ?? const OnboardingData();
    
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(initialData: initialData),
      child: const AnalysisPage(),
    );
  }
}
