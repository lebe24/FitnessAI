import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fitness/app/ui/home/data/model/workout_plan_model.dart';

class HomeRemoteDataSource {
  final String baseUrl = "https://fwq1p840-8080.uks1.devtunnels.ms/";
  
  late final Dio dio;

  HomeRemoteDataSource() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(minutes: 5), // Increased for image processing
      sendTimeout: const Duration(seconds: 60),
    ));
  }

  Future<WorkoutPlanModel> uploadImage(
    String? extraInfo,
    File image, {
    required String goal,
    required String duration,
    required String trainingSplit,
  }) async {
    final formData = FormData.fromMap({
      "extrainfo": extraInfo ?? "",
      "image": await MultipartFile.fromFile(
        image.path,
        filename: image.path.split("/").last,
      ),
      "goal": goal,
      "duration": duration,
      "training_split": trainingSplit,
    });

    try {
      final response = await dio.post("/workout-plan-generator", data: formData);

      if (response.statusCode == 200) {
        // Backend returns a Map with "plan" and "status"
        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          // Parse the response into WorkoutPlanModel
          return WorkoutPlanModel.fromJson(dataMap);
        } else if (response.data is String) {
          // If response is a string, try to parse it as JSON
          final dataMap = jsonDecode(response.data as String) as Map<String, dynamic>;
          return WorkoutPlanModel.fromJson(dataMap);
        } else {
          throw Exception("Unexpected response format: ${response.data.runtimeType}");
        }
      } else {
        throw Exception("Failed to upload image: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      throw Exception("Failed to upload image: ${e.message}");
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }

  Future<String> getWorkoutPlan() async {
    final response = await dio.get("/openai_agent");
    if (response.statusCode == 200) return response.data;
    throw Exception("Failed to fetch workout plan");
  }

  Future<String> getBaseInfo() async {
    try {
      final response = await dio.get("/");
      if (response.statusCode == 200) {
        // Handle different response types
        if (response.data is String) {
          return response.data as String;
        } else if (response.data is Map) {
          return response.data.toString();
        } else {
          return response.data.toString();
        }
      }
      throw Exception("Failed to fetch base info: ${response.statusMessage}");
    } on DioException catch (e) {
      throw Exception("Failed to fetch base info: ${e.message}");
    } catch (e) {
      throw Exception("Failed to fetch base info: $e");
    }
  }
}
