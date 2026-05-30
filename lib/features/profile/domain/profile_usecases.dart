import '../../auth/domain/user_model.dart';
import '../data/profile_repository.dart';

/// DOMAIN layer untuk profil. Reuse [UserModel] milik fitur auth.

class GetProfileUseCase {
  final ProfileRepository _repo;
  GetProfileUseCase([ProfileRepository? repo])
    : _repo = repo ?? ProfileRepository();

  Future<UserModel?> call() => _repo.getProfile();
}

class UpdateNameUseCase {
  final ProfileRepository _repo;
  UpdateNameUseCase([ProfileRepository? repo])
    : _repo = repo ?? ProfileRepository();

  Future<void> call(String name) => _repo.updateName(name);
}
