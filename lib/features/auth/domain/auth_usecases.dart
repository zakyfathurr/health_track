import '../data/auth_repository.dart';
import 'user_model.dart';

/// DOMAIN layer: use case tipis di atas [AuthRepository].
/// Presentation cukup memanggil `LoginUseCase()` tanpa menyentuh data/Firebase.

class LoginUseCase {
  final AuthRepository _repo;
  LoginUseCase([AuthRepository? repo]) : _repo = repo ?? AuthRepository();

  Future<void> call({required String email, required String password}) =>
      _repo.login(email: email, password: password);
}

class RegisterUseCase {
  final AuthRepository _repo;
  RegisterUseCase([AuthRepository? repo]) : _repo = repo ?? AuthRepository();

  Future<UserModel> call({
    required String name,
    required String username,
    required String email,
    required String password,
  }) => _repo.register(
    name: name,
    username: username,
    email: email,
    password: password,
  );
}

class ResetPasswordUseCase {
  final AuthRepository _repo;
  ResetPasswordUseCase([AuthRepository? repo])
    : _repo = repo ?? AuthRepository();

  Future<void> call(String email) => _repo.resetPassword(email);
}

class LogoutUseCase {
  final AuthRepository _repo;
  LogoutUseCase([AuthRepository? repo]) : _repo = repo ?? AuthRepository();

  Future<void> call() => _repo.logout();
}
