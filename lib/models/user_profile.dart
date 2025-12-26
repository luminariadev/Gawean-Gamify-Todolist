import 'package:flutter/material.dart';
import 'dart:math';

class UserProfile {
  int? id;
  String displayName;
  String? photoPath;
  int level;
  int currentXp;
  int xpToNextLevel;
  int totalCoins;
  int streakDays;
  int tasksCompleted;
  double efficiencyRate;
  DateTime? lastLogin;
  DateTime? lastTaskDate;
  String? selectedTheme;
  int? highestStreak;
  DateTime? accountCreated;
  int treasuresUnlocked;
  int achievementsEarned;
  int totalQuestsCreated;
  double averageProductivity;

  UserProfile({
    this.id,
    this.displayName = 'Adventurer',
    this.photoPath,
    this.level = 1,
    this.currentXp = 0,
    this.xpToNextLevel = 100,
    this.totalCoins = 0,
    this.streakDays = 0,
    this.tasksCompleted = 0,
    this.efficiencyRate = 0.0,
    this.lastLogin,
    this.lastTaskDate,
    this.selectedTheme,
    this.highestStreak = 0,
    this.accountCreated,
    this.treasuresUnlocked = 0,
    this.achievementsEarned = 0,
    this.totalQuestsCreated = 0,
    this.averageProductivity = 0.0,
  }) {
    // Set tanggal pembuatan akun jika null
    accountCreated ??= DateTime.now();
    // Set last login jika null
    lastLogin ??= DateTime.now();
  }

  double get progress => xpToNextLevel > 0 ? currentXp / xpToNextLevel : 0.0;

  // Hitung XP yang dibutuhkan untuk naik level berikutnya
  int get nextLevelXpRequired {
    if (level <= 0) return 100;
    // Formula: 100 * (level^1.5)
    return (100 * pow(level, 1.5)).round();
  }

  // XP yang sudah dikumpulkan untuk level saat ini
  int get xpEarnedThisLevel => currentXp;

  // XP yang dibutuhkan untuk menyelesaikan level saat ini
  int get xpRemainingThisLevel => max(0, xpToNextLevel - currentXp);

  // Total XP yang sudah dikumpulkan sepanjang waktu
  int get totalXpEarned {
    int total = currentXp;

    // Hitung XP dari level-level sebelumnya
    for (int i = 1; i < level; i++) {
      total += (100 * pow(i, 1.5)).round();
    }

    return total;
  }

  // Persentase menyelesaikan level saat ini
  double get levelCompletionPercentage {
    if (xpToNextLevel <= 0) return 0.0;
    return (currentXp / xpToNextLevel).clamp(0.0, 1.0);
  }

  // Perkiraan kapan akan naik level berdasarkan rata-rata XP per hari
  int estimateDaysToNextLevel(int averageXpPerDay) {
    if (averageXpPerDay <= 0) return 999;
    final days = xpRemainingThisLevel / averageXpPerDay;
    return days.ceil();
  }

  // Update highest streak jika streak saat ini lebih tinggi
  void updateHighestStreak() {
    if (streakDays > (highestStreak ?? 0)) {
      highestStreak = streakDays;
    }
  }

  // Reset streak jika melewatkan sehari
  void resetStreakIfNeeded() {
    if (lastTaskDate == null) return;

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    // Jika last task lebih dari 1 hari yang lalu, reset streak
    if (lastTaskDate!.isBefore(yesterday)) {
      streakDays = 0;
    }
  }

  // Tambahkan XP dengan update level otomatis
  void addXp(int xpToAdd) {
    currentXp += xpToAdd;
    tasksCompleted++;

    // Update last task date
    lastTaskDate = DateTime.now();

    // Update streak
    if (lastTaskDate != null) {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      if (streakDays == 0) {
        streakDays = 1;
      } else if (lastTaskDate!.year == yesterday.year &&
          lastTaskDate!.month == yesterday.month &&
          lastTaskDate!.day == yesterday.day) {
        streakDays++;
      } else if (lastTaskDate!.year != today.year ||
          lastTaskDate!.month != today.month ||
          lastTaskDate!.day != today.day) {
        streakDays = 1;
      }
    }

    // Update highest streak
    updateHighestStreak();

    // Check level up
    while (currentXp >= xpToNextLevel) {
      currentXp -= xpToNextLevel;
      level++;
      xpToNextLevel = nextLevelXpRequired;
    }
  }

  // Tambahkan koin
  void addCoins(int coinsToAdd) {
    totalCoins += coinsToAdd;
  }

  // Kurangi koin (untuk pembelian)
  bool spendCoins(int coinsToSpend) {
    if (totalCoins >= coinsToSpend) {
      totalCoins -= coinsToSpend;
      return true;
    }
    return false;
  }

  // Update efficiency rate
  void updateEfficiencyRate(int completedTasks, int totalTasks) {
    if (totalTasks > 0) {
      efficiencyRate = (completedTasks / totalTasks) * 100.0;
    }
  }

  // Hitung level berdasarkan total XP (untuk display)
  static int calculateLevelFromTotalXp(int totalXp) {
    int level = 1;
    int xpNeeded = 0;

    while (totalXp >= xpNeeded) {
      xpNeeded = (100 * pow(level, 1.5)).round();
      if (totalXp >= xpNeeded) {
        totalXp -= xpNeeded;
        level++;
      } else {
        break;
      }
    }

    return level;
  }

  // Hitung XP progress untuk level tertentu dari total XP
  static Map<String, dynamic> calculateLevelProgressFromTotalXp(int totalXp) {
    int level = 1;
    int currentLevelXp = 0;
    int xpNeededForNextLevel = 0;
    int xpRemaining = totalXp;

    while (xpRemaining >= 0) {
      xpNeededForNextLevel = (100 * pow(level, 1.5)).round();

      if (xpRemaining >= xpNeededForNextLevel) {
        xpRemaining -= xpNeededForNextLevel;
        level++;
      } else {
        currentLevelXp = xpRemaining;
        break;
      }
    }

    return {
      'level': level,
      'currentXp': currentLevelXp,
      'xpToNextLevel': xpNeededForNextLevel,
    };
  }

  // Get level title berdasarkan level
  String get levelTitle {
    if (level < 5) return 'Novice';
    if (level < 10) return 'Apprentice';
    if (level < 15) return 'Journeyman';
    if (level < 20) return 'Expert';
    if (level < 25) return 'Master';
    if (level < 30) return 'Grand Master';
    if (level < 40) return 'Legend';
    return 'Mythic';
  }

  // Get level color berdasarkan level
  Color get levelColor {
    if (level < 5) return Colors.green;
    if (level < 10) return Colors.blue;
    if (level < 15) return Colors.purple;
    if (level < 20) return Colors.orange;
    if (level < 25) return Colors.red;
    if (level < 30) return Colors.cyan;
    if (level < 40) return Colors.pink;
    return Colors.yellow;
  }

  // Get level icon berdasarkan level
  IconData get levelIcon {
    if (level < 5) return Icons.emoji_emotions;
    if (level < 10) return Icons.star_border;
    if (level < 15) return Icons.star_half;
    if (level < 20) return Icons.star;
    if (level < 25) return Icons.workspace_premium;
    if (level < 30) return Icons.diamond;
    if (level < 40) return Icons.celebration;
    return Icons.auto_awesome;
  }

  // Get badge level (untuk UI)
  String get badgeLevel {
    if (level < 3) return '🥉';
    if (level < 6) return '🥈';
    if (level < 10) return '🥇';
    if (level < 15) return '🏆';
    if (level < 20) return '👑';
    if (level < 25) return '💎';
    if (level < 30) return '⭐';
    return '🌟';
  }

  // Waktu sejak akun dibuat
  String get accountAge {
    if (accountCreated == null) return 'New';

    final now = DateTime.now();
    final difference = now.difference(accountCreated!);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'Just now';
    }
  }

  // Milestone berikutnya - DIPERBAIKI
  String get nextMilestone {
    final milestones = [
      {'level': 5, 'title': 'Reach Level 5'},
      {'level': 10, 'title': 'Reach Level 10'},
      {'level': 15, 'title': 'Reach Level 15'},
      {'level': 20, 'title': 'Reach Level 20'},
      {'level': 25, 'title': 'Reach Level 25'},
      {'level': 30, 'title': 'Reach Level 30'},
      {'level': 40, 'title': 'Reach Level 40'},
      {'level': 50, 'title': 'Reach Level 50'},
    ];

    for (final milestone in milestones) {
      final milestoneLevel = milestone['level'] as int; // Explicit cast ke int
      if (level < milestoneLevel) {
        return milestone['title'] as String;
      }
    }

    return 'Max Level Achieved!';
  }

  // Persentase progress ke milestone berikutnya - DIPERBAIKI
  double get milestoneProgress {
    final milestones = [5, 10, 15, 20, 25, 30, 40, 50];

    for (final milestone in milestones) {
      if (level < milestone) {
        final index = milestones.indexOf(milestone);
        final prevMilestone = index > 0 ? milestones[index - 1] : 0;
        final range = milestone - prevMilestone;
        final progressInRange = level - prevMilestone;
        return range > 0 ? progressInRange / range : 0.0;
      }
    }

    return 1.0;
  }

  // Achievement progress
  double get achievementProgress {
    if (achievementsEarned == 0) return 0.0;
    // Asumsi total achievements = 20 (bisa disesuaikan)
    return achievementsEarned / 20.0;
  }

  // Treasure progress
  double get treasureProgress {
    if (treasuresUnlocked == 0) return 0.0;
    // Asumsi total treasures = 10 (bisa disesuaikan)
    return treasuresUnlocked / 10.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'photoPath': photoPath,
      'level': level,
      'currentXp': currentXp,
      'xpToNextLevel': xpToNextLevel,
      'totalCoins': totalCoins,
      'streakDays': streakDays,
      'tasksCompleted': tasksCompleted,
      'efficiencyRate': efficiencyRate,
      'lastLogin': lastLogin?.toIso8601String(),
      'lastTaskDate': lastTaskDate?.toIso8601String(),
      'selectedTheme': selectedTheme,
      'highestStreak': highestStreak ?? 0,
      'accountCreated': accountCreated?.toIso8601String(),
      'treasuresUnlocked': treasuresUnlocked,
      'achievementsEarned': achievementsEarned,
      'totalQuestsCreated': totalQuestsCreated,
      'averageProductivity': averageProductivity,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      displayName: map['displayName'],
      photoPath: map['photoPath'],
      level: map['level'],
      currentXp: map['currentXp'],
      xpToNextLevel: map['xpToNextLevel'],
      totalCoins: map['totalCoins'] ?? 0,
      streakDays: map['streakDays'] ?? 0,
      tasksCompleted: map['tasksCompleted'] ?? 0,
      efficiencyRate: map['efficiencyRate'] ?? 0.0,
      lastLogin:
          map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
      lastTaskDate: map['lastTaskDate'] != null
          ? DateTime.parse(map['lastTaskDate'])
          : null,
      selectedTheme: map['selectedTheme'],
      highestStreak: map['highestStreak'] ?? 0,
      accountCreated: map['accountCreated'] != null
          ? DateTime.parse(map['accountCreated'])
          : DateTime.now(),
      treasuresUnlocked: map['treasuresUnlocked'] ?? 0,
      achievementsEarned: map['achievementsEarned'] ?? 0,
      totalQuestsCreated: map['totalQuestsCreated'] ?? 0,
      averageProductivity: map['averageProductivity'] ?? 0.0,
    );
  }

  // Copy dengan method
  UserProfile copyWith({
    int? id,
    String? displayName,
    String? photoPath,
    int? level,
    int? currentXp,
    int? xpToNextLevel,
    int? totalCoins,
    int? streakDays,
    int? tasksCompleted,
    double? efficiencyRate,
    DateTime? lastLogin,
    DateTime? lastTaskDate,
    String? selectedTheme,
    int? highestStreak,
    DateTime? accountCreated,
    int? treasuresUnlocked,
    int? achievementsEarned,
    int? totalQuestsCreated,
    double? averageProductivity,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      photoPath: photoPath ?? this.photoPath,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      totalCoins: totalCoins ?? this.totalCoins,
      streakDays: streakDays ?? this.streakDays,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      efficiencyRate: efficiencyRate ?? this.efficiencyRate,
      lastLogin: lastLogin ?? this.lastLogin,
      lastTaskDate: lastTaskDate ?? this.lastTaskDate,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      highestStreak: highestStreak ?? this.highestStreak,
      accountCreated: accountCreated ?? this.accountCreated,
      treasuresUnlocked: treasuresUnlocked ?? this.treasuresUnlocked,
      achievementsEarned: achievementsEarned ?? this.achievementsEarned,
      totalQuestsCreated: totalQuestsCreated ?? this.totalQuestsCreated,
      averageProductivity: averageProductivity ?? this.averageProductivity,
    );
  }

  // Validasi data user
  bool isValid() {
    return displayName.isNotEmpty &&
        level > 0 &&
        currentXp >= 0 &&
        xpToNextLevel > 0 &&
        totalCoins >= 0 &&
        streakDays >= 0 &&
        tasksCompleted >= 0 &&
        efficiencyRate >= 0.0 &&
        efficiencyRate <= 100.0;
  }

  @override
  String toString() {
    return 'UserProfile{'
        'id: $id, '
        'displayName: $displayName, '
        'level: $level, '
        'xp: $currentXp/$xpToNextLevel, '
        'coins: $totalCoins, '
        'streak: $streakDays, '
        'tasks: $tasksCompleted, '
        'efficiency: $efficiencyRate%, '
        'treasures: $treasuresUnlocked, '
        'achievements: $achievementsEarned'
        '}';
  }
}
