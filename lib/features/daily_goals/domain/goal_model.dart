class GoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetValue;
  final double currentProgress;
  final String unit;
  final DateTime date;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetValue,
    required this.currentProgress,
    required this.unit,
    required this.date,
  });

  double get progressPercent =>
      targetValue > 0 ? (currentProgress / targetValue).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => currentProgress >= targetValue;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'targetValue': targetValue,
    'currentProgress': currentProgress,
    'unit': unit,
    'date': date.toIso8601String(),
  };

  factory GoalModel.fromMap(Map<String, dynamic> map) => GoalModel(
    id: map['id'] as String,
    userId: map['userId'] as String,
    title: map['title'] as String,
    targetValue: (map['targetValue'] as num).toDouble(),
    currentProgress: (map['currentProgress'] as num).toDouble(),
    unit: map['unit'] as String,
    date: DateTime.parse(map['date'] as String),
  );

  GoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetValue,
    double? currentProgress,
    String? unit,
    DateTime? date,
  }) => GoalModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    targetValue: targetValue ?? this.targetValue,
    currentProgress: currentProgress ?? this.currentProgress,
    unit: unit ?? this.unit,
    date: date ?? this.date,
  );
}
