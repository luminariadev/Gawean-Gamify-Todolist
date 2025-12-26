import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class Achievement {
  int? id;
  String title;
  String description;
  String iconName; // Changed from iconData to iconName for clarity
  String colorHex;
  bool isEarned;
  DateTime? earnedAt;
  int xpReward; // Changed from xpRequired to xpReward (XP yang didapat saat unlock)
  String category; // 'quest', 'streak', 'productivity', 'level', 'special'

  Achievement({
    this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.colorHex,
    this.isEarned = false,
    this.earnedAt,
    required this.xpReward,
    required this.category,
  });

  Color get color {
    try {
      String hex = colorHex.replaceFirst('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // Add alpha value
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.blue; // Fallback color
    }
  }

  IconData get icon {
    // Map icon names to actual IconData
    final iconMap = {
      // Feather Icons
      'award': FeatherIcons.award,
      'star': FeatherIcons.star,
      'checkCircle': FeatherIcons.checkCircle,
      'trendingUp': FeatherIcons.trendingUp,
      'target': FeatherIcons.target,
      'zap': FeatherIcons.zap,
      'clock': FeatherIcons.clock,
      'calendar': FeatherIcons.calendar,
      'fire': FeatherIcons.activity, // Feather's activity looks like fire
      'trophy': FeatherIcons.award, // Using award as trophy

      // Material Icons
      'celebration': Icons.celebration,
      'workspace_premium': Icons.workspace_premium,
      'emoji_events': Icons.emoji_events,
      'diamond': Icons.diamond,
      'stars': Icons.stars,
      'rocket_launch': Icons.rocket_launch,
      'bolt': Icons.bolt,
      'local_fire_department': Icons.local_fire_department,
      'speed': Icons.speed,
      'auto_awesome': Icons.auto_awesome,
    };

    return iconMap[iconName] ?? Icons.help_outline;
  }

  // Helper method to get category color
  Color get categoryColor {
    switch (category) {
      case 'quest':
        return Colors.green;
      case 'streak':
        return Colors.orange;
      case 'productivity':
        return Colors.blue;
      case 'level':
        return Colors.purple;
      case 'special':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get category icon
  IconData get categoryIcon {
    switch (category) {
      case 'quest':
        return Icons.assignment_turned_in;
      case 'streak':
        return Icons.local_fire_department;
      case 'productivity':
        return Icons.trending_up;
      case 'level':
        return Icons.star;
      case 'special':
        return Icons.workspace_premium;
      default:
        return Icons.category;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_name': iconName, // Changed field name for consistency
      'color_hex': colorHex, // Changed field name for consistency
      'is_earned': isEarned ? 1 : 0,
      'earned_at': earnedAt?.toIso8601String(),
      'xp_reward': xpReward, // Changed field name
      'category': category,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      iconName: map['icon_name'] ??
          map['iconData'] ??
          'help_outline', // Support both old and new field names
      colorHex: map['color_hex'] ?? map['colorHex'] ?? '#2196F3',
      isEarned: (map['is_earned'] ?? map['isEarned'] ?? 0) == 1,
      earnedAt: map['earned_at'] != null
          ? DateTime.parse(map['earned_at'])
          : (map['earnedAt'] != null ? DateTime.parse(map['earnedAt']) : null),
      xpReward: map['xp_reward'] ??
          map['xpRequired'] ??
          0, // Support both old and new field names
      category: map['category'] ?? 'quest',
    );
  }

  // Copy with method for updates
  Achievement copyWith({
    int? id,
    String? title,
    String? description,
    String? iconName,
    String? colorHex,
    bool? isEarned,
    DateTime? earnedAt,
    int? xpReward,
    String? category,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isEarned: isEarned ?? this.isEarned,
      earnedAt: earnedAt ?? this.earnedAt,
      xpReward: xpReward ?? this.xpReward,
      category: category ?? this.category,
    );
  }

  // Mark as earned
  Achievement markAsEarned() {
    return copyWith(
      isEarned: true,
      earnedAt: DateTime.now(),
    );
  }

  // Check if achievement is recently earned (within last 24 hours)
  bool get isRecentlyEarned {
    if (earnedAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(earnedAt!);
    return difference.inHours <= 24;
  }

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, isEarned: $isEarned, category: $category)';
  }
}
