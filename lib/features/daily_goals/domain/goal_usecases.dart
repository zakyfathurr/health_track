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
    required DateTime date,
  }) async {
    final goal = GoalModel(
      id: _repo.newId(),
      userId: userId,
      title: title,
      targetValue: targetValue,
      currentProgress: 0,
      unit: unit,
      date: date,
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

class UpdateGoalProgressUseCase {
  final GoalRepository _repo;
  UpdateGoalProgressUseCase([GoalRepository? repo])
    : _repo = repo ?? GoalRepository();

  Future<void> call(String id, double currentProgress) =>
      _repo.updateProgress(id, currentProgress);
}

class DeleteGoalUseCase {
  final GoalRepository _repo;
  DeleteGoalUseCase([GoalRepository? repo]) : _repo = repo ?? GoalRepository();

  Future<void> call(String id) => _repo.delete(id);
}
