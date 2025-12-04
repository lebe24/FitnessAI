import 'package:fitness/app/ui/onboarding/model/onboarding_data.dart';
import 'package:fitness/app/ui/onboarding/utils/onboarding_storage.dart';

abstract class ProfileLocalDataSource {
  Future<OnboardingData?> getOnboardingData();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  @override
  Future<OnboardingData?> getOnboardingData() async {
    return await OnboardingStorage.loadOnboardingData();
  }
}

