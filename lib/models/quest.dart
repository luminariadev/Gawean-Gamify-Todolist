import 'dart:ui';
import 'package:flutter/material.dart';

class Quest {
  int? id;
  String title;
  String description;
  String category;
  String priority;
  DateTime date;
  TimeOfDay time;
  double progress;
  bool isCompleted;
  DateTime createdAt;
  DateTime? completedAt;
  int xpReward;
  int coinsReward;
  String? colorHex;

  Quest({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.date,
    required this.time,
    this.progress = 0.0,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.xpReward = 10,
    this.coinsReward = 0,
    this.colorHex,
  });

  Color get color {
    if (colorHex != null) {
      return Color(int.parse(colorHex!.replaceFirst('#', '0xff')));
    }

    // Fallback colors berdasarkan priority
    switch (priority) {
      case 'High':
      case 'Urgent':
        return Colors.red;
      case 'Medium':
        return Colors.amber;
      case 'Low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'progress': progress,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'xpReward': xpReward,
      'coinsReward': coinsReward,
      'colorHex': colorHex,
    };
  }

  factory Quest.fromMap(Map<String, dynamic> map) {
    final timeParts = (map['time'] as String).split(':');

    return Quest(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      priority: map['priority'],
      date: DateTime.parse(map['date']),
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      progress: map['progress'],
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      xpReward: map['xpReward'],
      coinsReward: map['coinsReward'] ?? 0,
      colorHex: map['colorHex'],
    );
  }
}
