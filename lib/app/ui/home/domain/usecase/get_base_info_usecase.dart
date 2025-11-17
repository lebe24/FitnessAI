import 'package:fitness/app/ui/home/domain/repository/home_repository.dart';

class GetBaseInfoUseCase {
  final HomeRepository repository;
  GetBaseInfoUseCase(this.repository);

  Future<String> call() async {
    return await repository.getBaseInfo();
  }
}








