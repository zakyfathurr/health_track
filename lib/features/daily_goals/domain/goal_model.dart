import 'goal_category.dart';

/// Target harian yang BERULANG.
///
/// Progres tidak lagi disimpan sebagai satu angka `currentProgress`, tapi
/// sebagai map per-hari `progress: { 'yyyy-MM-dd': nilai }`. Dengan begitu
/// target "reset" tiap hari, dan kita bisa hitung streak + statistik mingguan
/// dari satu dokumen (tanpa query tambahan).
class GoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetValue;
  final String unit;
  final String categoryId;

  /// Kapan target dibuat — dipakai untuk urutan & batas bawah perhitungan.
  final DateTime createdAt;

  /// 'yyyy-MM-dd' -> nilai progres pada hari itu.
  final Map<String, double> progress;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetValue,
    required this.unit,
    required this.categoryId,
    required this.createdAt,
    required this.progress,
  });

  // --- Helpers tanggal (hindari dependensi intl di domain) ---

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // --- Derived getters ---

  GoalCategory get category => GoalCategory.byId(categoryId);

  double progressOn(DateTime day) => progress[dayKey(day)] ?? 0;

  double get todayProgress => progressOn(_today());

  double percentOn(DateTime day) =>
      targetValue > 0 ? (progressOn(day) / targetValue).clamp(0.0, 1.0) : 0.0;

  double get todayPercent => percentOn(_today());

  bool completedOn(DateTime day) =>
      targetValue > 0 && progressOn(day) >= targetValue;

  bool get isCompletedToday => completedOn(_today());

  /// Jumlah hari beruntun target terpenuhi, dihitung mundur dari hari ini.
  /// Kalau hari ini belum selesai, streak tidak putus — dihitung dari kemarin
  /// (hari ini masih "berjalan"). Streak putus begitu ketemu hari terlewat.
  int get streak {
    var day = _today();
    var count = 0;
    // Hari ini: kalau sudah selesai ikut dihitung; kalau belum, lewati tanpa
    // memutus streak lalu mulai dari kemarin.
    if (completedOn(day)) {
      count++;
    }
    day = day.subtract(const Duration(days: 1));
    while (completedOn(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// Persen tiap hari untuk 7 hari terakhir, urut lama -> baru (untuk chart).
  List<double> get last7DaysPercent {
    final today = _today();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return percentOn(day);
    });
  }

  // --- Serialization ---

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'targetValue': targetValue,
    'unit': unit,
    'categoryId': categoryId,
    'createdAt': createdAt.toIso8601String(),
    'progress': progress,
  };

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    // Backward compat: dokumen lama punya `currentProgress` + `date`,
    // tanpa `progress`/`categoryId`/`step`/`createdAt`.
    final rawProgress = map['progress'];
    final Map<String, double> progress;
    if (rawProgress is Map) {
      progress = rawProgress.map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      );
    } else if (map['currentProgress'] != null && map['date'] != null) {
      final legacyDate = DateTime.parse(map['date'] as String);
      progress = {dayKey(legacyDate): (map['currentProgress'] as num).toDouble()};
    } else {
      progress = {};
    }

    final createdAtRaw = map['createdAt'] ?? map['date'];
    final createdAt = createdAtRaw is String
        ? DateTime.parse(createdAtRaw)
        : DateTime.now();

    return GoalModel(
      id: (map['id'] as String?) ?? '',
      userId: map['userId'] as String,
      title: map['title'] as String,
      targetValue: (map['targetValue'] as num).toDouble(),
      unit: map['unit'] as String,
      categoryId: (map['categoryId'] as String?) ?? GoalCategory.fallback.id,
      createdAt: createdAt,
      progress: progress,
    );
  }

  GoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetValue,
    String? unit,
    String? categoryId,
    DateTime? createdAt,
    Map<String, double>? progress,
  }) => GoalModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    targetValue: targetValue ?? this.targetValue,
    unit: unit ?? this.unit,
    categoryId: categoryId ?? this.categoryId,
    createdAt: createdAt ?? this.createdAt,
    progress: progress ?? this.progress,
  );
}
