import 'dart:async';

import 'package:fitness/l10n/generated/app_localizations.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:fitness/ui/core/di.dart' as di;
import 'package:fitness/ui/core/locale/locale_provider.dart';
import 'package:fitness/ui/core/theme/theme.dart';
import 'package:fitness/ui/core/routes/app_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

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
    await dotenv.load(fileName: ".env");
    await di.initDI();
    runApp(const MainApp());
    FlutterNativeSplash.remove();
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: di.sl<LocaleProvider>(),
      child: Consumer<LocaleProvider>(
        builder: (_, localeProvider, __) {
          return MaterialApp.router(
            title: Constant.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.whiteThemeMode,
            routerConfig: ScreenPaths.appRouter,
            locale: localeProvider.locale,
            supportedLocales: kSupportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
