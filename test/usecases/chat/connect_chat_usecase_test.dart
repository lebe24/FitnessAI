import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/chat/domain/usecases/connect_chat_usecase.dart';
import 'package:fitness/app/chat/domain/repositories/chat_repository.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late ConnectChatUsecase usecase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    usecase = ConnectChatUsecase(mockRepository);
  });

  test('should connect to chat successfully', () async {
    // arrange
    const userId = 'user-123';
    const userName = 'Test User';
    when(mockRepository.connectChat(
      userId: userId,
      userName: userName,
      workoutPlan: anyNamed('workoutPlan'),
    )).thenAnswer((_) async => {});

    // act
    await usecase(userId, userName);

    // assert
    verify(mockRepository.connectChat(
      userId: userId,
      userName: userName,
      workoutPlan: null,
    )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should connect to chat with workout plan', () async {
    // arrange
    const userId = 'user-123';
    const userName = 'Test User';
    final workoutPlan = {'id': 'plan-1'};
    when(mockRepository.connectChat(
      userId: userId,
      userName: userName,
      workoutPlan: anyNamed('workoutPlan'),
    )).thenAnswer((_) async => {});

    // act
    await usecase(userId, userName, workoutPlan: workoutPlan);

    // assert
    verify(mockRepository.connectChat(
      userId: userId,
      userName: userName,
      workoutPlan: workoutPlan,
    )).called(1);
  });

  test('should throw exception when connection fails', () async {
    // arrange
    const userId = 'user-123';
    const userName = 'Test User';
    when(mockRepository.connectChat(
      userId: userId,
      userName: userName,
      workoutPlan: anyNamed('workoutPlan'),
    )).thenThrow(Exception('Connection failed'));

    // act & assert
    expect(
      () => usecase(userId, userName),
      throwsException,
    );
  });
}

