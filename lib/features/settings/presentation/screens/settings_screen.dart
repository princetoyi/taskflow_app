import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/theme_bloc.dart';
import '../bloc/theme_event.dart';
import '../bloc/theme_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appearance', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, state) {
                  final isDark = state is ThemeLoaded && state.mode == ThemeMode.dark;
                  return SwitchListTile(
                    activeThumbColor: AppColors.accent,
                    title: const Text('Dark mode'),
                    subtitle: const Text('Keep your theme preference on this device.'),
                    value: isDark,
                    onChanged: (_) => context.read<ThemeBloc>().add(const ToggleThemeMode()),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              const Text('Firebase notifications are enabled automatically when permissions are granted.'),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: const Text('View notification center'),
                  subtitle: const Text('See the latest push alerts and updates.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(AppRoutes.notifications),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('View profile'),
                      subtitle: const Text('Edit your name, phone number, and password.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.profile),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Log out', style: TextStyle(color: Colors.red)),
                      onTap: () => _confirmLogout(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                authBloc.add(LogoutRequested());
              },
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
  }
}
