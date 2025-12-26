class DailyStat {
  int? id;
  DateTime date;
  int tasksCompleted;
  double productivityScore;
  int focusMinutes;

  DailyStat({
    this.id,
    required this.date,
    this.tasksCompleted = 0,
    this.productivityScore = 0.0,
    this.focusMinutes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'tasksCompleted': tasksCompleted,
      'productivityScore': productivityScore,
      'focusMinutes': focusMinutes,
    };
  }

  factory DailyStat.fromMap(Map<String, dynamic> map) {
    return DailyStat(
      id: map['id'],
      date: DateTime.parse(map['date']),
      tasksCompleted: map['tasksCompleted'],
      productivityScore: map['productivityScore'],
      focusMinutes: map['focusMinutes'],
    );
  }
}
