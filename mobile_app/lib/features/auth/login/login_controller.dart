import 'package:fitness_care_bagerhat/core/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ## LoginController
///
/// Manages the state of the login form, including role selection,
/// loading status, and error handling.
class LoginController extends AutoDisposeNotifier<LoginState> {
  @override
  LoginState build() {
    return const LoginState();
  }

  /// Toggles between 'admin' and 'member' roles.
  void setRole(String role) {
    state = state.copyWith(role: role, error: null);
  }

  /// Attempts to login with the provided credentials.
  Future<void> login(String identifier, String password) async {
    if (identifier.isEmpty || password.isEmpty) {
      state = state.copyWith(error: 'Please fill in all fields');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(authProvider.notifier).login(
            identifier: identifier,
            password: password,
            role: state.role,
          );
    } catch (e) {
      String errorMessage = e.toString().replaceAll('ApiException: ', '');
      if (errorMessage.toLowerCase().contains('unreachable') || 
          errorMessage.toLowerCase().contains('connection')) {
        errorMessage = '❌ Server is not connected. Please check settings.';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }
}

/// State for the login screen.
class LoginState {
  final String role;
  final bool isLoading;
  final String? error;

  const LoginState({
    this.role = 'member',
    this.isLoading = false,
    this.error,
  });

  LoginState copyWith({
    String? role,
    bool? isLoading,
    String? error,
  }) {
    return LoginState(
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(
  LoginController.new,
);
