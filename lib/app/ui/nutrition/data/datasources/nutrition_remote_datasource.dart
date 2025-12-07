import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fitness/app/ui/nutrition/data/models/nutrition_analysis_model.dart';

abstract class NutritionRemoteDataSource {
  Future<NutritionAnalysisModel> analyzeFood({
    required File image,
    String? goal,
    String? gender,
    String? height,
    String? weight,
    String? experience,
    String? extraInfo,
  });
}

class NutritionRemoteDataSourceImpl implements NutritionRemoteDataSource {
  final String baseUrl = "https://fwq1p840-8080.uks1.devtunnels.ms/";
  
  late final Dio dio;

  NutritionRemoteDataSourceImpl() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(seconds: 60),
    ));
  }

  @override
  Future<NutritionAnalysisModel> analyzeFood({
    required File image,
    String? goal,
    String? gender,
    String? height,
    String? weight,
    String? experience,
    String? extraInfo,
  }) async {
    final formData = FormData.fromMap({
      "image": await MultipartFile.fromFile(
        image.path,
        filename: image.path.split("/").last,
      ),
      "goal": goal ?? "",
      "gender": gender ?? "",
      "height": height ?? "",
      "weight": weight ?? "",
      "experience": experience ?? "",
      "extraInfo": extraInfo ?? "",
    });

    try {
      final response = await dio.post(
        "/nutrition-plan-analyzer",
        data: formData,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return NutritionAnalysisModel.fromJson(response.data as Map<String, dynamic>);
        } else {
          throw Exception("Unexpected response format: ${response.data.runtimeType}");
        }
      } else {
        throw Exception("Failed to analyze food: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      throw Exception("Failed to analyze food: ${e.message}");
    } catch (e) {
      throw Exception("Failed to analyze food: $e");
    }
  }
}











