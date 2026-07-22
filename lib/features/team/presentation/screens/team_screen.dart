import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow_app/core/network/api_client.dart';
import 'package:taskflow_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:taskflow_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:taskflow_app/core/widgets/custom_bottom_navigation_bar.dart';
import 'package:taskflow_app/routes/app_routes.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({Key? key}) : super(key: key);

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late Future<List<Map<String, dynamic>>> _teamMembersFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  void _loadTeamMembers() {
    final apiClient = context.read<ApiClient>();
    _teamMembersFuture = _fetchTeamMembers(apiClient);
  }

  Future<List<Map<String, dynamic>>> _fetchTeamMembers(ApiClient apiClient) async {
    final response = await apiClient.get<dynamic>('/users/team');
    if (response is List) {
      return response.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    if (response is Map<String, dynamic> && response['users'] is List) {
      return (response['users'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authState.user.isManager) {
          return Scaffold(
            appBar: AppBar(title: const Text('Team')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only managers can view team members',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const CustomBottomNavigationBar(
              currentIndex: 2,
              items: [
                BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
                BottomNavItem(icon: Icons.list_alt, label: 'Tasks'),
                BottomNavItem(icon: Icons.group, label: 'Team'),
                BottomNavItem(icon: Icons.bar_chart, label: 'Reports'),
              ],
              onTap: _noopTap,
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text('Team Members'),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(_loadTeamMembers);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search team members...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _teamMembersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingSkeleton();
                    }

                    if (snapshot.hasError) {
                      return _buildErrorWidget(
                        snapshot.error.toString(),
                        _loadTeamMembers,
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    var members = snapshot.data!;

                    // Filter by search query
                    if (_searchQuery.isNotEmpty) {
                      members = members.where((member) {
                        final displayName =
                            (member['display_name'] ?? '').toString();
                        final email = (member['email'] ?? '').toString();
                        final query = _searchQuery.toLowerCase();
                        return displayName.toLowerCase().contains(query) ||
                            email.toLowerCase().contains(query);
                      }).toList();
                    }

                    if (members.isEmpty) {
                      return Center(
                        child: Text(
                          'No team members found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return _buildTeamMemberCard(context, member);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: const CustomBottomNavigationBar(
            currentIndex: 2,
            items: [
              BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
              BottomNavItem(icon: Icons.list_alt, label: 'Tasks'),
              BottomNavItem(icon: Icons.group, label: 'Team'),
              BottomNavItem(icon: Icons.bar_chart, label: 'Reports'),
            ],
            onTap: _noopTap,
          ),
        );
      },
    );
  }

  Widget _buildTeamMemberCard(
    BuildContext context,
    Map<String, dynamic> member,
  ) {
    final displayName = member['display_name'] ?? 'Unknown';
    final email = member['email'] ?? '';
    final uid = member['uid'] ?? '';
    final initials = _getInitials(displayName.toString());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          displayName.toString(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(email.toString()),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            context.push(
              AppRoutes.teamMemberDetails.replaceFirst(':id', uid.toString()),
              extra: member,
            );
          },
        ),
        onTap: () {
          context.push(
            AppRoutes.teamMemberDetails.replaceFirst(':id', uid.toString()),
            extra: member,
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            title: Container(
              height: 16,
              color: Colors.grey[300],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                height: 12,
                color: Colors.grey[300],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Team Members',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  static void _noopTap(int _) {}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Team Members',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your team is empty',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _getInitials(String displayName) {
    if (displayName.isEmpty) return 'TM';
    final parts = displayName.split(' ');
    return parts
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();
  }
}
