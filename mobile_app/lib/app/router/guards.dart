import 'package:fitness_care_bagerhat/core/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Route guard that checks authentication status.
///
/// Redirects unauthenticated users to the login screen and
/// authenticated users away from the login screen to their role home.
///
/// See also:
/// - [AuthProvider] for the auth state
/// - [Routes] for path constants
String? authGuard(BuildContext context, GoRouterState state, Ref ref) {
  final authState = ref.read(authProvider).valueOrNull;
  final isLoginRoute = state.matchedLocation == '/login';

  if (authState == null || authState.status == AuthStatus.unknown) {
    return null; // Still loading
  }

  if (authState.status == AuthStatus.unauthenticated) {
    return isLoginRoute ? null : '/login';
  }

  if (authState.status == AuthStatus.mustChangePassword) {
    return state.matchedLocation == '/change-password'
        ? null
        : '/change-password';
  }

  // Authenticated — redirect away from login
  if (isLoginRoute) {
    return authState.isAdmin ? '/admin' : '/member';
  }

  // Role-based access control
  final path = state.matchedLocation;
  if (authState.isAdmin && path.startsWith('/member')) {
    return '/admin';
  }
  if (authState.isMember && path.startsWith('/admin')) {
    return '/member';
  }

  return null; // No redirect needed
}
