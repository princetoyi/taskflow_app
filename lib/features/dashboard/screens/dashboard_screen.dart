import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../tasks/presentation/widgets/stats_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! Authenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(context, state),
                Expanded(child: _buildBody(context)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Authenticated state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      color: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Thursday, 26 Feb · 14 active tasks',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.accent2, Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _avatarInitials(state.user.displayName, state.user.email),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      color: AppColors.canvas,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(),
                  const SizedBox(height: 16),
                  _buildStatusTabs(),
                  const SizedBox(height: 16),
                  _buildWorkloadSection(context),
                  const SizedBox(height: 20),
                  _buildRecentUpdates(context),
                ],
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      childAspectRatio: 1.18,
      children: const [
        StatsCard(
          icon: Icons.task_alt,
          label: 'Active Tasks',
          value: '14',
          background: Color(0xFFEEF4FF),
          iconColor: AppColors.accent2,
          valueColor: AppColors.accent2,
        ),
        StatsCard(
          icon: Icons.warning_amber_rounded,
          label: 'Overdue',
          value: '3',
          background: Color(0xFFFFF1EE),
          iconColor: AppColors.accent,
          valueColor: AppColors.accent,
        ),
        StatsCard(
          icon: Icons.check_circle_outline,
          label: 'Completed',
          value: '27',
          background: Color(0xFFEDFAF7),
          iconColor: AppColors.mint,
          valueColor: AppColors.mint,
        ),
        StatsCard(
          icon: Icons.lock_outline,
          label: 'Blocked',
          value: '2',
          background: Color(0xFFFFFBEB),
          iconColor: AppColors.warn,
          valueColor: AppColors.warn,
        ),
      ],
    );
  }

  Widget _buildStatusTabs() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTab('All 14', active: true),
          _buildTab('Not Started 4'),
          _buildTab('In Progress 5'),
          _buildTab('Blocked 2', background: const Color(0xFF7C3AED), textColor: Colors.white),
          _buildTab('Done 3', background: AppColors.mint, textColor: Colors.white),
        ],
      ),
    );
  }

  Widget _buildTab(String label, {bool active = false, Color background = const Color(0xFFF0F0F4), Color textColor = const Color(0xFF9EA3B0)}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkloadSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Team Workload', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        _workloadRow('Sarah K.', 0.8, '6 tasks', AppColors.accent2),
        const SizedBox(height: 8),
        _workloadRow('Marcus D.', 0.55, '4 tasks', AppColors.mint),
        const SizedBox(height: 8),
        _workloadRow('Lena P.', 0.3, '2 tasks', AppColors.warn),
        const SizedBox(height: 8),
        _workloadRow('Tom N.', 0.25, '2 tasks', const Color(0xFF7C3AED)),
      ],
    );
  }

  Widget _workloadRow(String name, double fill, String label, Color fillColor) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(color: const Color(0xFFEEF4FF), borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              widthFactor: fill,
              child: Container(
                decoration: BoxDecoration(color: fillColor, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 36, child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted), textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildRecentUpdates(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Updates', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        _buildUpdateTile(context, AppColors.accent, 'Warehouse inventory count', 'Sarah · 2 min ago', '⚠ AT-RISK', const Color(0xFFFFF3DC)),
        const SizedBox(height: 8),
        _buildUpdateTile(context, AppColors.accent2, 'Deliver unit 4B supplies', 'Marcus · 18 min ago', '65%', const Color(0xFFEEF4FF)),
        const SizedBox(height: 8),
        _buildUpdateTile(context, AppColors.mint, 'Staff scheduling Feb', 'Lena · 1 hr ago', 'DONE', const Color(0xFFE4FDF7)),
      ],
    );
  }

  Widget _buildUpdateTile(BuildContext context, Color dotColor, String title, String meta, String badgeText, Color badgeBackground) {
    final badgeColor = badgeBackground == const Color(0xFFE4FDF7) ? AppColors.mint : AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(meta, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: AppConstants.navHeight,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('⊞', 'Dashboard', true),
          _buildNavItem('📋', 'Tasks'),
          _buildNavItem('👥', 'Team'),
          _buildNavItem('📊', 'Reports'),
        ],
      ),
    );
  }

  Widget _buildNavItem(String icon, String label, [bool active = false]) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(icon, style: TextStyle(fontSize: 18, color: active ? AppColors.accent2 : AppColors.muted)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: active ? AppColors.accent2 : AppColors.muted),
        ),
      ],
    );
  }

  static String _avatarInitials(String displayName, String email) {
    if (displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      if (parts.length > 1) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return displayName.substring(0, 2).toUpperCase();
    }
    return email.substring(0, 2).toUpperCase();
  }
}
