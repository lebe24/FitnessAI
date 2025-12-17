import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/ui/auth/domain/usecase/sign_in_google.dart';
import 'package:fitness/app/ui/auth/domain/repositories/auth_repository.dart';
import 'package:fitness/app/ui/auth/domain/entities/user_entity.dart';
import '../../helpers/test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithGoogle usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = SignInWithGoogle(mockRepository);
  });

  test('should sign in with Google and return user', () async {
    // arrange
    final testUser = TestFixtures.getTestUser();
    when(mockRepository.signInWithGoogle())
        .thenAnswer((_) async => testUser);

    // act
    final result = await usecase();

    // assert
    expect(result, equals(testUser));
    verify(mockRepository.signInWithGoogle()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return null when sign in fails', () async {
    // arrange
    when(mockRepository.signInWithGoogle()).thenAnswer((_) async => null);

    // act
    final result = await usecase();

    // assert
    expect(result, isNull);
    verify(mockRepository.signInWithGoogle()).called(1);
  });

  test('should throw exception when repository throws', () async {
    // arrange
    when(mockRepository.signInWithGoogle())
        .thenThrow(Exception('Sign in failed'));

    // act & assert
    expect(() => usecase(), throwsException);
    verify(mockRepository.signInWithGoogle()).called(1);
  });
}

