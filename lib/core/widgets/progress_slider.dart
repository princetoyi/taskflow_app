import 'package:flutter/material.dart';

class ProgressSlider extends StatelessWidget {
  final int progress;
  final Color activeColor;
  final Color backgroundColor;

  const ProgressSlider({
    Key? key,
    required this.progress,
    required this.activeColor,
    this.backgroundColor = const Color(0xFFF0F0F4),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final widthFactor = progress.clamp(0, 100) / 100;
            return Container(
              width: constraints.maxWidth * widthFactor,
              height: 8,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(6),
              ),
            );
          },
        ),
        Positioned(
          right: 0,
          top: -3,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: activeColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.08 * 255).round()),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
