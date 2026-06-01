import '../data/mood_repository.dart';
import 'mood_model.dart';

/// DOMAIN layer untuk mood journal. Screen cukup memanggil use case ini.

class AddMoodUseCase {
  final MoodRepository _repo;
  AddMoodUseCase([MoodRepository? repo]) : _repo = repo ?? MoodRepository();

  Future<MoodModel> call({
    required String userId,
    required String mood,
    required String note,
    required DateTime date,
  }) async {
    final entry = MoodModel(
      id: _repo.newId(),
      userId: userId,
      mood: mood,
      note: note,
      date: date,
    );
    await _repo.add(entry);
    return entry;
  }
}

class GetMoodsUseCase {
  final MoodRepository _repo;
  GetMoodsUseCase([MoodRepository? repo]) : _repo = repo ?? MoodRepository();

  Stream<List<MoodModel>> call(String userId) => _repo.streamByUser(userId);
}

class UpdateMoodUseCase {
  final MoodRepository _repo;
  UpdateMoodUseCase([MoodRepository? repo]) : _repo = repo ?? MoodRepository();

  Future<void> call(MoodModel mood) => _repo.update(mood);
}

class DeleteMoodUseCase {
  final MoodRepository _repo;
  DeleteMoodUseCase([MoodRepository? repo]) : _repo = repo ?? MoodRepository();

  Future<void> call(String id) => _repo.delete(id);
}
