import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/ui/auth/domain/usecase/sign_out.dart';
import 'package:fitness/app/ui/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignOut usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SignOut(mockRepository);
  });

  test('should sign out successfully', () async {
    // arrange
    when(mockRepository.signOut()).thenAnswer((_) async => {});

    // act
    await usecase();

    // assert
    verify(mockRepository.signOut()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should throw exception when sign out fails', () async {
    // arrange
    when(mockRepository.signOut())
        .thenThrow(Exception('Sign out failed'));

    // act & assert
    expect(() => usecase(), throwsException);
    verify(mockRepository.signOut()).called(1);
  });
}

