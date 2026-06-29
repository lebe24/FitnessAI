import 'package:fitness/data/models/onboarding/onboarding_data.dart';
import 'package:fitness/ui/features/onboarding/views/onboarding_storage.dart';

abstract class ProfileLocalDataSource {
  Future<OnboardingData?> getOnboardingData();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  @override
  Future<OnboardingData?> getOnboardingData() async {
    return await OnboardingStorage.loadOnboardingData();
  }
}

