import 'package:dio/dio.dart';
import 'package:fitness/app/core/constant/constant.dart';

abstract class AgentRemoteDataSource {
  Future<String> generateMotivationQuote({
    required String userName,
    required String tone,
    required String message,
  });
}

class AgentRemoteDataSourceImpl implements AgentRemoteDataSource {
  final String baseUrl = Constant.backendUrl;
  
  late final Dio dio;

  AgentRemoteDataSourceImpl() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
  }

  @override
  Future<String> generateMotivationQuote({
    required String userName,
    required String tone,
    required String message,
  }) async {
    try {
      // Send as form-urlencoded data
      final response = await dio.post(
        '/motivation-quote-generator',
        data: {
          'user_name': userName,
          'tone': tone,
          'message': message,
        },
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        // Handle JSON response structure
        if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          
          // Check status
          final status = data['status'] as String?;
          if (status != null && status != 'success') {
            throw Exception("API returned non-success status: $status");
          }
          
          // Extract quote from response
          final quote = data['quote'] as String?;
          if (quote != null && quote.isNotEmpty) {
            return quote;
          }
          
          // Fallback to other possible fields
          final message = data['message'] as String?;
          if (message != null && message.isNotEmpty) {
            return message;
          }
          
          final responseText = data['response'] as String?;
          if (responseText != null && responseText.isNotEmpty) {
            return responseText;
          }
          
          throw Exception("No quote found in response");
        } else if (response.data is String) {
          // If response is a plain string, return it
          return response.data as String;
        } else {
          throw Exception("Unexpected response format: ${response.data.runtimeType}");
        }
      } else {
        throw Exception("Failed to generate motivation quote: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      throw Exception("Failed to generate motivation quote: ${e.message}");
    } catch (e) {
      throw Exception("Failed to generate motivation quote: $e");
    }
  }
}

