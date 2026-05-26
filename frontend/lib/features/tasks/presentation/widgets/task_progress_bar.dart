import 'package:flutter/material.dart';

class TaskProgressBar extends StatelessWidget {
  final int progress;
  final Color activeColor;
  final Color backgroundColor;

  const TaskProgressBar({
    Key? key,
    required this.progress,
    required this.activeColor,
    this.backgroundColor = const Color(0xFFF0F0F4),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0, 100) / 100,
        child: Container(
          decoration: BoxDecoration(
            color: activeColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
