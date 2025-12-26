import 'package:flutter/material.dart'; // TAMBAHKAN INI

class TreasureLevel {
  final int id;
  final String title;
  final String description;
  final String colorHex;
  final String iconData;
  final double positionX;
  final double positionY;
  final int requiredTasks;
  final List<String> rewards;
  bool isUnlocked;
  bool isClaimed;
  DateTime? unlockedAt;
  DateTime? claimedAt;

  TreasureLevel({
    required this.id,
    required this.title,
    required this.description,
    required this.colorHex,
    required this.iconData,
    required this.positionX,
    required this.positionY,
    required this.requiredTasks,
    required this.rewards,
    this.isUnlocked = false,
    this.isClaimed = false,
    this.unlockedAt,
    this.claimedAt,
  });

  Color get color {
    if (colorHex.startsWith('#')) {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    }
    return Color(int.parse(colorHex));
  }

  IconData get icon {
    switch (iconData) {
      case 'Icons.celebration':
        return Icons.celebration;
      case 'Icons.workspace_premium':
        return Icons.workspace_premium;
      case 'Icons.emoji_events':
        return Icons.emoji_events;
      case 'Icons.diamond':
        return Icons.diamond;
      case 'Icons.stars':
        return Icons.stars;
      default:
        return Icons.help_outline;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'colorHex': colorHex,
      'iconData': iconData,
      'positionX': positionX,
      'positionY': positionY,
      'requiredTasks': requiredTasks,
      'rewards': rewards.join('|'),
      'isUnlocked': isUnlocked ? 1 : 0,
      'isClaimed': isClaimed ? 1 : 0,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'claimedAt': claimedAt?.toIso8601String(),
    };
  }

  factory TreasureLevel.fromMap(Map<String, dynamic> map) {
    return TreasureLevel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      colorHex: map['colorHex'],
      iconData: map['iconData'],
      positionX: map['positionX'],
      positionY: map['positionY'],
      requiredTasks: map['requiredTasks'],
      rewards: (map['rewards'] as String).split('|'),
      isUnlocked: map['isUnlocked'] == 1,
      isClaimed: map['isClaimed'] == 1,
      unlockedAt:
          map['unlockedAt'] != null ? DateTime.parse(map['unlockedAt']) : null,
      claimedAt:
          map['claimedAt'] != null ? DateTime.parse(map['claimedAt']) : null,
    );
  }
}
