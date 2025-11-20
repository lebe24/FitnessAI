import 'package:flutter/material.dart';

class CustomBottombar extends StatelessWidget {
  const CustomBottombar({
    super.key,
    required this.onItemTapped,
    required this.currentIndex,
  });

  final ValueChanged<int> onItemTapped;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 7, 224, 72).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 7),
              ),
            ],
            border: Border.all(
              width: 0,
              color: const Color.fromARGB(254, 15, 197, 5)),
            color: const Color(0xFF11181F),
            borderRadius: BorderRadius.circular(50),
          ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(icon: Icons.home, index: 0, label: "Home"),
              _navItem(icon: Icons.rocket_launch, index: 1, label: "Activity"),
              _navItem(icon: Icons.bar_chart, index: 2, label: "Stats"),
              _navItem(icon: Icons.person, index: 3, label: "Profile"),
            ],
          ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required int index,
    String? label,
  }) {
    final bool active = currentIndex == index;

    if (active) {
      return GestureDetector(
        onTap: () => onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFB7F034),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.black),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              ]
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Icon(icon, color: Colors.white70, size: 28),
    );
  }
}