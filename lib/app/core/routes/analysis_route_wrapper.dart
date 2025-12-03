import 'package:fitness/app/ui/home/presentation/pages/analysis_page.dart';
import 'package:fitness/app/ui/onboarding/bloc/onboarding_bloc.dart';
import 'package:fitness/app/ui/onboarding/model/onboarding_data.dart';
import 'package:fitness/app/ui/onboarding/utils/onboarding_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    
    return BlocProvider(
      create: (context) => OnboardingBloc(initialData: initialData),
      child: const AnalysisPage(),
    );
  }
}
