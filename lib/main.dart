import 'dart:async';

import 'package:fitness/l10n/generated/app_localizations.dart';
import 'package:fitness/ui/core/constants/constant.dart';
import 'package:fitness/data/services/billing/billing_bootstrap.dart';
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

  // The muscle map's body outlines are MuscleMap by Melih Colpan (MIT), and
  // the MIT License requires its notice to travel with every copy. Registering
  // it here puts it in the app itself, not only in the repository's NOTICE.md.
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(['MuscleMap'], _kMuscleMapLicense);
  });

  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  try {
    await dotenv.load(fileName: ".env");
    await di.initDI();
    // Configure billing for whoever is signed in, and keep it following them.
    // Not awaited on the critical path beyond its own guard: it never throws,
    // and the app must open whether or not RevenueCat is reachable.
    await di.sl<BillingBootstrap>().start();
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

const _kMuscleMapLicense = '''MIT License

Copyright (c) 2026 Melih Colpan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''';
