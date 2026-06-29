import 'package:fitness/ui/core/theme/app_pallet.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // Modern border decoration for inputs
  // static _border([Color? color]) => OutlineInputBorder(
  //       borderSide: BorderSide(
  //         color: color ?? AppPalete.borderColor.withOpacity(0.3),
  //         width: 1.5,
  //       ),
  //       borderRadius: BorderRadius.circular(16),
  //     );

  // Card decoration for modern mobile design
  // static BoxDecoration cardDecoration({bool isDark = false}) => BoxDecoration(
  //       color: isDark
  //           ? AppPalete.backgroundColorBk.withOpacity(0.6)
  //           : AppPalete.whiteColor,
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(
  //           color: isDark
  //               ? Colors.black.withOpacity(0.3)
  //               : Colors.black.withOpacity(0.08),
  //           blurRadius: 20,
  //           offset: const Offset(0, 4),
  //           spreadRadius: 0,
  //         ),
  //       ],
  //     );

  // // Elevated button decoration
  // static BoxDecoration elevatedButtonDecoration({bool isDark = false}) =>
  //     BoxDecoration(
  //       gradient: const LinearGradient(
  //         colors: [AppPalete.gradient1, AppPalete.gradient2],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppPalete.gradient2.withOpacity(0.4),
  //           blurRadius: 12,
  //           offset: const Offset(0, 6),
  //           spreadRadius: 0,
  //         ),
  //       ],
  //     );

  // White/Light Theme Mode
  static final whiteThemeMode = ThemeData.light().copyWith(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      // primary: AppPalete.gradient1,
      secondary: AppPalete.gradient2,
      surface: AppPalete.whiteColor,
      background: AppPalete.backgroundColorWH,
      error: AppPalete.errorColor,
      onPrimary: AppPalete.whiteColor,
      onSecondary: AppPalete.whiteColor,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
      onError: AppPalete.whiteColor,
    ),
    scaffoldBackgroundColor: AppPalete.backgroundColorWH,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: Colors.black87,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        color: Colors.black87,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        color: Colors.black87,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        color: Colors.black87,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        color: Colors.black87,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        color: Colors.black87,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        color: Colors.black87,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalete.backgroundColorWH,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      iconTheme: const IconThemeData(
        color: Colors.black87,
        size: 24,
      ),
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        // backgroundColor: AppPalete.gradient1,
        foregroundColor: AppPalete.whiteColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        // foregroundColor: AppPalete.gradient1,
        // side: BorderSide(color: AppPalete.gradient1, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        // foregroundColor: AppPalete.gradient1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppPalete.whiteColor,
      deleteIconColor: Colors.black54,
      disabledColor: Colors.grey.shade300,
      // selectedColor: AppPalete.gradient1.withOpacity(0.2),
      secondarySelectedColor: AppPalete.gradient2.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        // color: AppPalete.gradient1,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      brightness: Brightness.light,
      elevation: 0,
      pressElevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalete.whiteColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      // border: _border(),
      // enabledBorder: _border(),
      // focusedBorder: _border(AppPalete.gradient2),
      // errorBorder: _border(AppPalete.errorColor),
      // focusedErrorBorder: _border(AppPalete.errorColor),
      // disabledBorder: _border(Colors.grey.shade300),
      errorStyle: const TextStyle(
        color: AppPalete.errorColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: TextStyle(
        color: Colors.black54,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: Colors.black38,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      // backgroundColor: AppPalete.gradient1,
      foregroundColor: AppPalete.whiteColor,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppPalete.whiteColor,
      // selectedItemColor: AppPalete.gradient1,
      unselectedItemColor: Colors.black54,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    iconTheme: const IconThemeData(
      color: Colors.black87,
      size: 24,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.black.withOpacity(0.12),
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  // Dark Theme Mode
  static final darkThemeMode = ThemeData.dark().copyWith(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      // primary: AppPalete.gradient1,
      secondary: AppPalete.gradient2,
      surface: AppPalete.backgroundColorBk,
      background: AppPalete.backgroundColorBk,
      error: AppPalete.errorColor,
      onPrimary: AppPalete.whiteColor,
      onSecondary: AppPalete.whiteColor,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: AppPalete.whiteColor,
    ),
    scaffoldBackgroundColor: AppPalete.backgroundColorBk,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        color: Colors.white60,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalete.backgroundColorBk,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        // backgroundColor: AppPalete.gradient1,
        foregroundColor: AppPalete.whiteColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalete.gradient2,
        side: BorderSide(color: AppPalete.gradient2, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppPalete.gradient2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppPalete.backgroundColorBk.withOpacity(0.6),
      deleteIconColor: Colors.white70,
      disabledColor: Colors.grey.shade800,
      // selectedColor: AppPalete.gradient1.withOpacity(0.3),
      secondarySelectedColor: AppPalete.gradient2.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppPalete.gradient2,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      brightness: Brightness.dark,
      elevation: 0,
      pressElevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalete.backgroundColorBk.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      // border: _border(Colors.white.withOpacity(0.2)),
      // enabledBorder: _border(Colors.white.withOpacity(0.2)),
      // focusedBorder: _border(AppPalete.gradient2),
      // errorBorder: _border(AppPalete.errorColor),
      // focusedErrorBorder: _border(AppPalete.errorColor),
      // disabledBorder: _border(Colors.grey.shade700),
      errorStyle: const TextStyle(
        color: AppPalete.errorColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: TextStyle(
        color: Colors.white70,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: Colors.white54,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      // backgroundColor: AppPalete.gradient1,
      foregroundColor: AppPalete.whiteColor,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppPalete.backgroundColorBk,
      selectedItemColor: AppPalete.gradient2,
      unselectedItemColor: Colors.white54,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
      size: 24,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.12),
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
