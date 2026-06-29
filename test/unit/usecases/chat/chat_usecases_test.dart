import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/domain/use_cases/chat/connect_chat_usecase.dart';
import 'package:fitness/domain/use_cases/chat/send_message_usecase.dart';
import '../../../fakes/fake_chat_repository.dart';
import '../../../fixtures/fixtures.dart';

void main() {
  late FakesChatRepo repo;

  setUp(() => repo = FakesChatRepo());
  tearDown(() => repo.dispose());

  // ── ConnectChatUsecase ─────────────────────────────────────────────────────

  group('ConnectChatUsecase', () {
    test('connects and marks repository as connected', () async {
      await ConnectChatUsecase(repo)('user-001', 'Test User');
      expect(repo.connectCalled, true);
      expect(repo.isConnected, true);
      expect(repo.lastConnectedUserId, 'user-001');
    });

    test('passes workout plan to repository', () async {
      final plan = {'id': 'plan-1'};
      await ConnectChatUsecase(repo)(
        'user-001',
        'Test User',
        workoutPlan: plan,
      );
      expect(repo.connectCalled, true);
    });

    test('propagates exception from repository', () async {
      repo.connectError = Exception('Connection refused');
      expect(
        () => ConnectChatUsecase(repo)('user-001', 'Test User'),
        throwsException,
      );
    });
  });

  // ── SendMessageUsecase ─────────────────────────────────────────────────────

  group('SendMessageUsecase', () {
    test('returns chat response from repository', () async {
      final result = await SendMessageUsecase(repo)(
        message: 'Give me a workout plan',
        userId: 'user-001',
      );
      expect(result.message, isNotEmpty);
      expect(repo.lastSentMessage, 'Give me a workout plan');
    });

    test('propagates exception from repository', () async {
      repo.sendError = Exception('Server error');
      expect(
        () => SendMessageUsecase(repo)(
          message: 'hello',
          userId: 'user-001',
        ),
        throwsException,
      );
    });
  });
}

// Alias to avoid confusion with the import path
typedef FakesChatRepo = FakeChatRepository;
