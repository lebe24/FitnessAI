import 'package:fitness/app/ui/home/presentation/widget/dottedBorder.dart';
import 'package:flutter/material.dart';

class CameraBox extends StatelessWidget {
  const CameraBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return  Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.55,
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  painter: DottedBorderPainter(),
                );
              },
            ),
          ),
          Center(child: child),
        ],
      ),
    );
  }
}