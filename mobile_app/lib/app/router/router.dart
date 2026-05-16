import 'package:fitness_care_bagerhat/app/router/guards.dart';
import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/core/auth/auth_provider.dart';
import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/members/create/create_member_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/members/detail/member_detail_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/members/list/members_list_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/messages_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payments_list_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plans_list_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/settings/settings_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/shell/admin_shell.dart';
import 'package:fitness_care_bagerhat/features/auth/change_password/change_password_screen.dart';
import 'package:fitness_care_bagerhat/features/auth/login/login_screen.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_screen.dart';
import 'package:fitness_care_bagerhat/features/member/logs/diet/diet_log_screen.dart';
import 'package:fitness_care_bagerhat/features/member/logs/weight/weight_log_screen.dart';
import 'package:fitness_care_bagerhat/features/member/logs/workout/workout_log_screen.dart';
import 'package:fitness_care_bagerhat/features/member/messages/member_messages_screen.dart';
import 'package:fitness_care_bagerhat/features/member/profile/member_profile_screen.dart';
import 'package:fitness_care_bagerhat/features/member/shell/member_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Provides the singleton [GoRouter] instance.
///
/// The router is scoped to a [WidgetRef] so that auth guards can
/// read the current [AuthState] during redirect evaluation.
final routerProvider = Provider<GoRouter>((ref) {
  final listenable = RouterListenable(ref);
  return createRouter(ref, listenable);
});

/// Creates the app-wide [GoRouter] with all routes and guards.
///
/// Route tree:
/// ```
/// /login              → LoginScreen
/// /change-password    → ChangePasswordScreen
/// /admin              → AdminShell (bottom nav)
///   /admin/members    → MembersListScreen
///   /admin/members/:id → MemberDetailScreen
///   ...
/// /member             → MemberShell (bottom nav)
///   /member/logs/weight → WeightLogScreen
///   ...
/// ```


GoRouter createRouter(Ref ref, Listenable listenable) {
  return GoRouter(
    initialLocation: Routes.login,
    debugLogDiagnostics: true,
    refreshListenable: listenable,
    redirect: (context, state) => authGuard(
      context,
      state,
      ref,
    ),
    routes: [
      // ─── Auth ────────────────────────────────────────────
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.changePassword,
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // ─── Admin Shell ─────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            name: 'adminDashboard',
            builder: (context, state) => const DashboardScreen(),
            routes: [
              GoRoute(
                path: 'members',
                name: 'adminMembers',
                builder: (context, state) => const MembersListScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'adminMemberCreate',
                    builder: (context, state) => const CreateMemberScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'adminMemberDetail',
                    builder: (context, state) => MemberDetailScreen(
                      id: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: 'adminMemberEdit',
                        builder: (context, state) =>
                            const _PlaceholderScreen(title: 'Edit Member'),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'plans',
                name: 'adminPlans',
                builder: (context, state) => const PlansListScreen(),
              ),
              GoRoute(
                path: 'payments',
                name: 'adminPayments',
                builder: (context, state) => const PaymentsListScreen(),
              ),
              GoRoute(
                path: 'messages',
                name: 'adminMessages',
                builder: (context, state) => const MessagesScreen(),
                routes: [
                  GoRoute(
                    path: 'broadcast',
                    name: 'adminBroadcast',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Broadcast'),
                  ),
                  GoRoute(
                    path: ':conversationId',
                    name: 'adminChat',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Chat'),
                  ),
                ],
              ),
              GoRoute(
                path: 'settings',
                name: 'adminSettings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ─── Member Shell ────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MemberShell(child: child),
        routes: [
          GoRoute(
            path: '/member',
            name: 'memberHome',
            builder: (context, state) => const MemberHomeScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                name: 'memberProfile',
                builder: (context, state) => const MemberProfileScreen(),
              ),
              GoRoute(
                path: 'subscription',
                name: 'memberSubscription',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Subscription'),
              ),
              GoRoute(
                path: 'payments',
                name: 'memberPayments',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Payments'),
              ),
              GoRoute(
                path: 'logs/weight',
                name: 'memberWeightLog',
                builder: (context, state) => const WeightLogScreen(),
              ),
              GoRoute(
                path: 'logs/workout',
                name: 'memberWorkoutLog',
                builder: (context, state) => const WorkoutLogScreen(),
              ),
              GoRoute(
                path: 'logs/diet',
                name: 'memberDietLog',
                builder: (context, state) => const DietLogScreen(),
              ),
              GoRoute(
                path: 'messages',
                name: 'memberMessages',
                builder: (context, state) => const MemberMessagesScreen(),
                routes: [
                  GoRoute(
                    path: ':conversationId',
                    name: 'memberChat',
                    builder: (context, state) =>
                        const _PlaceholderScreen(title: 'Chat'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}

// ─── Placeholder Widgets (replaced in later steps) ─────────

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

class _AdminShellPlaceholder extends StatelessWidget {
  const _AdminShellPlaceholder({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _MemberShellPlaceholder extends StatelessWidget {
  const _MemberShellPlaceholder({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
/// Listenable that notifies GoRouter when the auth state changes.
class RouterListenable extends ChangeNotifier {
  RouterListenable(this._ref) {
    _ref.listen(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
}
