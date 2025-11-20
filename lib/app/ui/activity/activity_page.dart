import 'package:flutter/material.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Activity Page',
        style: TextStyle(
          color: Colors.white,
          fontSize: 26, fontWeight: FontWeight.bold),
      ),
    );
  }
}