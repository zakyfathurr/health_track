class MoodModel {
  final String id;
  final String userId;
  final String mood;
  final String note;
  final DateTime date;

  const MoodModel({
    required this.id,
    required this.userId,
    required this.mood,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'mood': mood,
    'note': note,
    'date': date.toIso8601String(),
  };

  factory MoodModel.fromMap(Map<String, dynamic> map) => MoodModel(
    id: map['id'] as String,
    userId: map['userId'] as String,
    mood: map['mood'] as String,
    note: map['note'] as String,
    date: DateTime.parse(map['date'] as String),
  );

  MoodModel copyWith({
    String? id,
    String? userId,
    String? mood,
    String? note,
    DateTime? date,
  }) => MoodModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    mood: mood ?? this.mood,
    note: note ?? this.note,
    date: date ?? this.date,
  );
}
