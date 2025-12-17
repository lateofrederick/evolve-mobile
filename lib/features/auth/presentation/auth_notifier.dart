import 'package:evolve/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

// State to track auth status
class AuthState {
  final bool isLoading;
  final String? token;
  final String? error;

  AuthState({this.isLoading = false, this.token, this.error});

  bool get isAuthenticated => token != null;

  AuthState copyWith({bool? isLoading, String? token, String? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      error: error ?? this.error,
    );
  }
}

// The Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  // In a real app, you would use a Dependency Injection framework or Riverpod
  // to provide the ApiClient singleton.
  final apiClient = ApiClient();
  final repo = AuthRepository(apiClient);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = await _repository.login(email, password);
      // Success: Save token (In prod: Use flutter_secure_storage)
      state = state.copyWith(isLoading: false, token: token);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void logout() {
    state = AuthState();
  }
}