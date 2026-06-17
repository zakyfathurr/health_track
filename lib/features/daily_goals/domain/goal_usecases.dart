import '../data/goal_repository.dart';
import 'goal_model.dart';

/// DOMAIN layer untuk daily goals.

class AddGoalUseCase {
  final GoalRepository _repo;
  AddGoalUseCase([GoalRepository? repo]) : _repo = repo ?? GoalRepository();

  Future<GoalModel> call({
    required String userId,
    required String title,
    required double targetValue,
    required String unit,
    required String categoryId,
  }) async {
    final goal = GoalModel(
      id: _repo.newId(),
      userId: userId,
      title: title,
      targetValue: targetValue,
      unit: unit,
      categoryId: categoryId,
      createdAt: DateTime.now(),
      progress: const {},
    );
    await _repo.add(goal);
    return goal;
  }
}

class GetGoalsUseCase {
  final GoalRepository _repo;
  GetGoalsUseCase([GoalRepository? repo]) : _repo = repo ?? GoalRepository();

  Stream<List<GoalModel>> call(String userId) => _repo.streamByUser(userId);
}

/// Set progres HARI INI. Menerima nilai absolut baru, di-clamp >= 0.
/// Presentation menghitung nilai baru (mis. `todayProgress + step`) lalu
/// memanggil ini — supaya logika hari/tanggal terpusat di domain.
class SetTodayProgressUseCase {
  final GoalRepository _repo;
  SetTodayProgressUseCase([GoalRepository? repo])
    : _repo = repo ?? GoalRepository();

  Future<void> call(String goalId, double newValue) {
    final clamped = newValue < 0 ? 0.0 : newValue;
    final todayKey = GoalModel.dayKey(DateTime.now());
    return _repo.setProgressForDay(goalId, todayKey, clamped);
  }
}

class DeleteGoalUseCase {
  final GoalRepository _repo;
  DeleteGoalUseCase([GoalRepository? repo]) : _repo = repo ?? GoalRepository();

  Future<void> call(String id) => _repo.delete(id);
}
