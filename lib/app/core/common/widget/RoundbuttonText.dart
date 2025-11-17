import 'package:flutter/material.dart';


// ignore: must_be_immutable
class RoundBtnText extends StatelessWidget {
  RoundBtnText({super.key,required this.onPressed, required this.text});

  void Function() onPressed;
  String text;
  Size? size = Size(250, 55);
  Widget? widget;

  @override
  Widget build(BuildContext context) {
    return  ElevatedButton(
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