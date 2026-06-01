class WorkoutModel {
  final String id;
  final String userId;
  final String type;
  final int durationMinutes;
  final int caloriesBurned;
  final DateTime date;

  const WorkoutModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'type': type,
    'durationMinutes': durationMinutes,
    'caloriesBurned': caloriesBurned,
    'date': date.toIso8601String(),
  };

  factory WorkoutModel.fromMap(Map<String, dynamic> map) => WorkoutModel(
    id: map['id'] as String,
    userId: map['userId'] as String,
    type: map['type'] as String,
    durationMinutes: map['durationMinutes'] as int,
    caloriesBurned: map['caloriesBurned'] as int,
    date: DateTime.parse(map['date'] as String),
  );

  WorkoutModel copyWith({
    String? id,
    String? userId,
    String? type,
    int? durationMinutes,
    int? caloriesBurned,
    DateTime? date,
  }) => WorkoutModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    date: date ?? this.date,
  );
}
