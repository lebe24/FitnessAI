import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fitness/app/chat/domain/usecases/send_message_usecase.dart';
import 'package:fitness/app/chat/domain/repositories/chat_repository.dart';
import 'package:fitness/app/chat/domain/entities/chat_response_entity.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late SendMessageUsecase usecase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    usecase = SendMessageUsecase(mockRepository);
  });

  test('should send message and return response', () async {
    // arrange
    const testMessage = 'Hello, I need a workout plan';
    const testUserId = 'user-123';
    final testResponse = ChatResponseEntity(
      message: 'Here is your workout plan...',
      planUpdated: false,
      updatedPlanData: null,
    );

    when(mockRepository.sendMessage(
      message: testMessage,
      userId: testUserId,
    )).thenAnswer((_) async => testResponse);

    // act
    final result = await usecase(
      message: testMessage,
      userId: testUserId,
    );

    // assert
    expect(result, equals(testResponse));
    verify(mockRepository.sendMessage(
      message: testMessage,
      userId: testUserId,
    )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should throw exception when repository throws', () async {
    // arrange
    const testMessage = 'Hello';
    const testUserId = 'user-123';
    when(mockRepository.sendMessage(
      message: testMessage,
      userId: testUserId,
    )).thenThrow(Exception('Send failed'));

    // act & assert
    expect(
      () => usecase(message: testMessage, userId: testUserId),
      throwsException,
    );
    verify(mockRepository.sendMessage(
      message: testMessage,
      userId: testUserId,
    )).called(1);
  });
}

