import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/meal_detail_screen.dart';
import '../screens/home/body_stats_screen.dart';
import '../screens/home/physique_pictures_screen.dart';
import '../screens/workout/workout_screen.dart';
import '../screens/workout/youtube_player_screen.dart';
import '../screens/workout/exercise_progress_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/chats/chats_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/manage_plans_screen.dart';
import '../theme/app_colors.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _chatsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'chats');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'meals',
                  builder: (context, state) => const MealDetailScreen(),
                ),
                GoRoute(
                  path: 'body-stats',
                  builder: (context, state) => const BodyStatsScreen(),
                ),
                GoRoute(
                  path: 'physique-pictures',
                  builder: (context, state) => const PhysiquePicturesScreen(),
                ),
                GoRoute(
                  path: 'workout/:dayId',
                  builder: (context, state) {
                    final dayId = state.pathParameters['dayId']!;
                    return WorkoutScreen(dayId: dayId);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _chatsNavigatorKey,
          routes: [
            GoRoute(
              path: '/chats',
              builder: (context, state) => const ChatsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _profileNavigatorKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'progress',
                  builder: (context, state) => const ProgressScreen(),
                ),
                GoRoute(
                  path: 'manage-plans',
                  builder: (context, state) => const ManagePlansScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // Full-screen routes (outside bottom nav)
    GoRoute(
      path: '/youtube-player',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final videoId = state.uri.queryParameters['videoId'] ?? '';
        final title = state.uri.queryParameters['title'] ?? '';
        return YoutubePlayerScreen(videoId: videoId, title: title);
      },
    ),
    GoRoute(
      path: '/exercise-progress',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final exerciseName = state.uri.queryParameters['name'] ?? '';
        return ExerciseProgressScreen(exerciseName: exerciseName);
      },
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: navigationShell.currentIndex == 0,
                  onTap: () => navigationShell.goBranch(0),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chats',
                  isSelected: navigationShell.currentIndex == 1,
                  onTap: () => navigationShell.goBranch(1),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: navigationShell.currentIndex == 2,
                  onTap: () => navigationShell.goBranch(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
