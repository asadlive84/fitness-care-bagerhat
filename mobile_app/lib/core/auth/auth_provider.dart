import 'package:fitness_care_bagerhat/core/api/api_exception.dart';
import 'package:fitness_care_bagerhat/core/auth/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The global auth state provider.
///
/// Watches this to react to login/logout transitions.
/// The router guards read this to decide navigation.
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Possible authentication states.
enum AuthStatus {
  /// Initial check in progress.
  unknown,

  /// User is logged in.
  authenticated,

  /// User needs to change password before proceeding.
  mustChangePassword,

  /// User is not logged in.
  unauthenticated,
}

/// Immutable auth state.
class AuthState {
  final AuthStatus status;
  final String? role;
  final String? userName;
  final String? userId;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.role,
    this.userName,
    this.userId,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? role,
    String? userName,
    String? userId,
  }) {
    return AuthState(
      status: status ?? this.status,
      role: role ?? this.role,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Manages the authentication lifecycle.
///
/// On initialization, checks for existing tokens and validates them.
/// Exposes [login] and [logout] methods that update global state.
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final isAuth = await repo.isAuthenticated();

    if (!isAuth) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }

    final role = await repo.getUserRole();
    final name = await repo.getUserName();

    return AuthState(
      status: AuthStatus.authenticated,
      role: role,
      userName: name,
    );
  }

  /// Attempts login. Updates state to authenticated on success.
  ///
  /// Throws [ApiException] subclasses on failure.
  Future<void> login({
    required String identifier,
    required String password,
    required String role,
  }) async {
    state = const AsyncLoading();

    final newState = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final authData = await repo.login(
        identifier: identifier,
        password: password,
        role: role,
      );

      final mustChangePassword =
          authData['must_change_password'] as bool? ?? false;

      // The repository already saved user info from JWT
      final jwtRole = await repo.getUserRole();
      final name = await repo.getUserName();

      return AuthState(
        status: mustChangePassword
            ? AuthStatus.mustChangePassword
            : AuthStatus.authenticated,
        role: jwtRole ?? role,
        userName: name ?? identifier.split('@')[0],
      );
    });

    state = newState;
    if (newState.hasError) {
      Error.throwWithStackTrace(newState.error!, newState.stackTrace!);
    }
  }

  /// Logs out and clears all stored credentials.
  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData(
      AuthState(status: AuthStatus.unauthenticated),
    );
  }

  /// Marks password as changed, transitioning to authenticated.
  void markPasswordChanged() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current.copyWith(status: AuthStatus.authenticated),
      );
    }
  }
}
