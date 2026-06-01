import '../data/workout_repository.dart';
import 'workout_model.dart';

/// DOMAIN layer untuk workout.

class AddWorkoutUseCase {
  final WorkoutRepository _repo;
  AddWorkoutUseCase([WorkoutRepository? repo])
    : _repo = repo ?? WorkoutRepository();

  Future<WorkoutModel> call({
    required String userId,
    required String type,
    required int durationMinutes,
    required int caloriesBurned,
    required DateTime date,
  }) async {
    final workout = WorkoutModel(
      id: _repo.newId(),
      userId: userId,
      type: type,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
      date: date,
    );
    await _repo.add(workout);
    return workout;
  }
}

class GetWorkoutsUseCase {
  final WorkoutRepository _repo;
  GetWorkoutsUseCase([WorkoutRepository? repo])
    : _repo = repo ?? WorkoutRepository();

  Stream<List<WorkoutModel>> call(String userId) => _repo.streamByUser(userId);
}

class DeleteWorkoutUseCase {
  final WorkoutRepository _repo;
  DeleteWorkoutUseCase([WorkoutRepository? repo])
    : _repo = repo ?? WorkoutRepository();

  Future<void> call(String id) => _repo.delete(id);
}
