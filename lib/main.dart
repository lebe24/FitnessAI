import 'dart:async';
import 'dart:ui';

import 'package:fitness/app/core/constant/constant.dart';
import 'package:fitness/app/core/di.dart' as di;
import 'package:fitness/app/core/theme/theme.dart';
import 'package:fitness/app/core/routes/app_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';


Future<void> main() async {
  // Catch and log Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log to console
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Catch and log async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught async error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    await di.initDI();
    runApp(const MainApp());

    // Remove splash screen when bootstrap is complete
    FlutterNativeSplash.remove();
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Re-throw to see the error
    rethrow;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp.router(
        title: Constant.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.whiteThemeMode,
        routerConfig: ScreenPaths.appRouter,
      );
    }
}




