import 'package:fitness/ui/core/constants/assets.dart';
import 'package:flutter/material.dart';

class AppWidgets {
  static Image appLogo() {
    return Image.asset(
      ImagePath.appLogo,
      fit: BoxFit.contain,
    );
  }

  static ElevatedButton roundbtnText(
    {
      required void Function() onPressed,
      required String text,
      Size? size,
      Widget? widget,
    }
  ) {
    return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      minimumSize: size,
      backgroundColor: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    child: widget ?? Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    )
  );
  }
}