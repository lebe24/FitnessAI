import 'dart:ui';

import 'package:fitness/ui/core/constants/assets.dart';
import 'package:flutter/material.dart';

class FitnessMethod{

   // ================================
// Dialog Methods
// ================================

 static Future<void> dialogBuilder(BuildContext context,Widget child) {
  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 4.0,
        child: child,
      );
    },
  );
}

  static Stack banner(
    BuildContext context
  ){
    return Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.2,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Image.asset(
                  ImagePath.motivateBanner,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
    );
  }
}