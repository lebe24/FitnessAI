
import 'package:fitness/app/core/constant/constant.dart';
import 'package:fitness/app/core/di.dart' as di;
import 'package:fitness/app/core/theme/theme.dart';
import 'package:fitness/app/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  await di.initDI();
  runApp(const MainApp());
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




