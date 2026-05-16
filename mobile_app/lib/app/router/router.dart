import 'package:fitness_care_bagerhat/app/router/guards.dart';
import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/core/auth/auth_provider.dart';
import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/members/create/create_member_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/members/detail/member_detail_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/members/edit/edit_member_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/members/list/members_list_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/admin_chat_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/messages_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payments_list_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plans_list_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/settings/settings_screen.dart';
import 'package:fitness_care_bagerhat/features/admin/shell/admin_shell.dart';
import 'package:fitness_care_bagerhat/features/auth/change_password/change_password_screen.dart';
import 'package:fitness_care_bagerhat/features/auth/login/login_screen.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_screen.dart';
import 'package:fitness_care_bagerhat/features/member/logs/diet/diet_log_screen.dart';
import 'package:fitness_care_bagerhat/features/member/logs/logs_hub_screen.dart';
import 'package:fitness_care_bagerhat/features/member/logs/weight/weight_log_screen.dart';
import 'package:fitness_care_bagerhat/features/member/logs/workout/workout_log_screen.dart';
import 'package:fitness_care_bagerhat/features/member/messages/member_messages_screen.dart';
import 'package:fitness_care_bagerhat/features/member/payments/member_payments_screen.dart';
import 'package:fitness_care_bagerhat/features/member/profile/member_profile_screen.dart';
import 'package:fitness_care_bagerhat/features/member/shell/member_shell.dart';
import 'package:fitness_care_bagerhat/features/member/subscription/member_subscription_screen.dart';
import 'package:fitness_care_bagerhat/features/developer/developer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Provides the singleton [GoRouter] instance.
final routerProvider = Provider<GoRouter>((ref) {
  final listenable = RouterListenable(ref);
  return createRouter(ref, listenable);
});

GoRouter createRouter(Ref ref, Listenable listenable) {
  return GoRouter(
    initialLocation: Routes.login,
    debugLogDiagnostics: true,
    refreshListenable: listenable,
    redirect: (context, state) => authGuard(context, state, ref),
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
                        builder: (context, state) {
                          final member = state.extra! as Member;
                          return EditMemberScreen(
                            id: state.pathParameters['id']!,
                            member: member,
                          );
                        },
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
                    path: ':conversationId',
                    name: 'adminChat',
                    builder: (context, state) {
                      final memberId = state.pathParameters['conversationId']!;
                      final memberName = state.extra as String?;
                      return AdminChatScreen(
                        memberId: memberId,
                        memberName: memberName,
                      );
                    },
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
                builder: (context, state) => const MemberSubscriptionScreen(),
              ),
              GoRoute(
                path: 'payments',
                name: 'memberPayments',
                builder: (context, state) => const MemberPaymentsScreen(),
              ),
              GoRoute(
                path: 'logs',
                name: 'memberLogs',
                builder: (context, state) => const LogsHubScreen(),
                routes: [
                  GoRoute(
                    path: 'weight',
                    name: 'memberWeightLog',
                    builder: (context, state) => const WeightLogScreen(),
                  ),
                  GoRoute(
                    path: 'workout',
                    name: 'memberWorkoutLog',
                    builder: (context, state) => const WorkoutLogScreen(),
                  ),
                  GoRoute(
                    path: 'diet',
                    name: 'memberDietLog',
                    builder: (context, state) => const DietLogScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: 'messages',
                name: 'memberMessages',
                builder: (context, state) => const MemberMessagesScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.developer,
        name: 'developer',
        builder: (context, state) => const DeveloperScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}

/// Listenable that notifies GoRouter when the auth state changes.
class RouterListenable extends ChangeNotifier {
  RouterListenable(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
