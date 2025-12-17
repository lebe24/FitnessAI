import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/ui/auth/domain/usecase/sign_in_gmail.dart';
import 'package:fitness/app/ui/auth/domain/repositories/auth_repository.dart';
import 'package:fitness/app/ui/auth/domain/entities/user_entity.dart';
import '../../helpers/test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithGmail usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SignInWithGmail(mockRepository);
  });

  test('should sign in with Gmail and return user', () async {
    // arrange
    const email = 'test@example.com';
    final testUser = TestFixtures.getTestUser();
    when(mockRepository.signInWithGmail(email))
        .thenAnswer((_) async => testUser);

    // act
    final result = await usecase(email);

    // assert
    expect(result, equals(testUser));
    verify(mockRepository.signInWithGmail(email)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return null when sign in fails', () async {
    // arrange
    const email = 'test@example.com';
    when(mockRepository.signInWithGmail(email))
        .thenAnswer((_) async => null);

    // act
    final result = await usecase(email);

    // assert
    expect(result, isNull);
    verify(mockRepository.signInWithGmail(email)).called(1);
  });

  test('should throw exception when repository throws', () async {
    // arrange
    const email = 'test@example.com';
    when(mockRepository.signInWithGmail(email))
        .thenThrow(Exception('Sign in failed'));

    // act & assert
    expect(() => usecase(email), throwsException);
    verify(mockRepository.signInWithGmail(email)).called(1);
  });
}

