import 'dart:async';
import 'dart:convert';

import 'package:fitness/data/models/chat/chat_message_model.dart';
import 'package:fitness/data/models/chat/chat_response_model.dart';
import 'package:fitness/data/models/home/workout_plan_model.dart';
import 'package:fitness/data/models/storage/stored_fitness_plan_model.dart';
import 'package:fitness/data/services/chat/chat_remote_service.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket client for /ws/agent.
///
/// Sends the Supabase JWT on connection so the backend can load the full
/// user profile, workout plan, sessions, streak, and nutrition logs from
/// the database — no client-side context assembly needed.
class AgentWsDataSource implements ChatRemoteDataSource {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _messageController = StreamController<ChatMessageModel>.broadcast();
  bool _isConnected = false;
  String _currentUserId = '';

  @override
  Future<void> connect(
    String userId,
    String userName, {
    Map<String, dynamic>? workoutPlan, // ignored — backend loads from DB
  }) async {
    if (_isConnected && _channel != null) return;
    _currentUserId = userId;

    final uri = Uri.parse(Constant.agentWsUrl);
    _channel = WebSocketChannel.connect(uri);
    await _channel!.ready;
    _isConnected = true;

    // Send userId + JWT + local plan so backend always has current plan data
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken ?? '';
    final localPlan = await _loadLocalPlan();
    _channel!.sink.add(jsonEncode({
      'type':        'connection',
      'userId':      userId,
      'token':       token,
      if (localPlan != null) 'workoutPlan': localPlan,
    }));

    _subscription = _channel!.stream.listen(
      _onData,
      onError: (error) {
        _isConnected = false;
        _messageController.addError(error);
      },
      onDone: () => _isConnected = false,
      cancelOnError: false,
    );
  }

  Future<Map<String, dynamic>?> _loadLocalPlan() async {
    try {
      final box = await Hive.openBox<Map>('fitness_plans');
      if (box.isEmpty) return null;
      // Get the most recently updated plan
      StoredFitnessPlanModel? latest;
      for (final raw in box.values) {
        final map = Map<String, dynamic>.from(raw);
        final plan = StoredFitnessPlanModel.fromJson(map);
        if (latest == null || plan.updatedAt.isAfter(latest.updatedAt)) {
          latest = plan;
        }
      }
      if (latest == null) return null;
      return WorkoutPlanModel.fromEntity(latest.workoutPlan).toJson();
    } catch (_) {
      return null;
    }
  }

  void _onData(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json['type'] == 'typing')         return;
      if (json['type'] == 'connection_ack') return;
      if (json['type'] == 'error') {
        _messageController.addError(
          Exception(json['content'] ?? 'Unknown agent error'),
        );
        return;
      }
      if (json['type'] == 'message' ||
          json.containsKey('message') ||
          json.containsKey('content')) {
        final msg = ChatMessageModel.fromJson(json);
        if (!msg.isFromUser) _messageController.add(msg);
      }
    } catch (_) {
      _messageController.add(ChatMessageModel(
        id:         DateTime.now().millisecondsSinceEpoch.toString(),
        message:    raw.toString(),
        userId:     _currentUserId,
        timestamp:  DateTime.now(),
        isFromUser: false,
      ));
    }
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel    = null;
    _isConnected = false;
  }

  @override
  Future<ChatResponseModel> sendMessage({
    required String message,
    required String userId,
  }) async {
    if (!_isConnected || _channel == null) {
      throw Exception('Not connected to agent server');
    }
    _channel!.sink.add(jsonEncode({'type': 'message', 'content': message}));
    return const ChatResponseModel(message: '', planUpdated: false);
  }

  @override
  Stream<ChatMessageModel> get messageStream => _messageController.stream;

  @override
  bool get isConnected => _isConnected;

  void dispose() {
    _messageController.close();
    disconnect();
  }
}
