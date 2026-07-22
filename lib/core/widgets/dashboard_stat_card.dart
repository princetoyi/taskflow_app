import 'package:flutter/material.dart';
import 'package:taskflow_app/core/constants/app_colors.dart';

class DashboardStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color backgroundColor;
  final Color valueColor;

  const DashboardStatCard({
    Key? key,
    required this.value,
    required this.label,
    required this.backgroundColor,
    required this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}
