import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderText extends StatelessWidget {
  const HeaderText({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(text: "Choose"),
              TextSpan(
                text: "Your",
                style: TextStyle(
                  backgroundColor: Color(0xFFCCFF00),
                  color: Colors.black,
                ),
              ),
              TextSpan(text: "\nGender"),
            ]
          ),
        ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.3, end: 0),
        Center(
          child: Text(
            "This data allows the Ai to tailor your workout",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ).animate(delay: 500.ms).fadeIn(duration: 1000.ms).slideY(begin: 0.2, end: 0),
        ),
      ],
    );
  }
}