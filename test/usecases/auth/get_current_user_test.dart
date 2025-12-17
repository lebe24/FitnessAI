import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/ui/auth/domain/usecase/get_current_user.dart';
import 'package:fitness/app/ui/auth/domain/repositories/auth_repository.dart';
import 'package:fitness/app/ui/auth/domain/entities/user_entity.dart';
import '../../helpers/test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetCurrentUser usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = GetCurrentUser(mockRepository);
  });

  test('should get current user from repository', () {
    // arrange
    final testUser = TestFixtures.getTestUser();
    when(mockRepository.getCurrentUser()).thenReturn(testUser);

    // act
    final result = usecase();

    // assert
    expect(result, equals(testUser));
    verify(mockRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return null when no user is logged in', () {
    // arrange
    when(mockRepository.getCurrentUser()).thenReturn(null);

    // act
    final result = usecase();

    // assert
    expect(result, isNull);
    verify(mockRepository.getCurrentUser()).called(1);
  });
}

