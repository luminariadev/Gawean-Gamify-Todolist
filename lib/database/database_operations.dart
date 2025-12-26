import 'package:sqflite/sqflite.dart';
import 'dart:math';
import './database_helper.dart';
import '../models/quest.dart';
import '../models/user_profile.dart';
import '../models/achievement.dart';
import '../models/treasure.dart';
import '../models/statistics.dart';

class DatabaseOperations {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // === QUEST OPERATIONS ===
  Future<int> insertQuest(Quest quest) async {
    final db = await _dbHelper.database;
    return await db.insert('quests', quest.toMap());
  }

  Future<List<Quest>> getAllQuests() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('quests', orderBy: 'date DESC, priority DESC');
    return List.generate(maps.length, (i) => Quest.fromMap(maps[i]));
  }

  Future<List<Quest>> getTodayQuests() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final todayString = DateTime(today.year, today.month, today.day)
        .toIso8601String()
        .split('T')[0];

    final List<Map<String, dynamic>> maps = await db.query(
      'quests',
      where: 'date LIKE ?',
      whereArgs: ['$todayString%'],
      orderBy: 'priority DESC',
    );
    return List.generate(maps.length, (i) => Quest.fromMap(maps[i]));
  }

  Future<List<Quest>> getQuestsByCategory(String category) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quests',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'priority DESC, date ASC',
    );
    return List.generate(maps.length, (i) => Quest.fromMap(maps[i]));
  }

  Future<int> updateQuest(Quest quest) async {
    final db = await _dbHelper.database;
    return await db.update(
      'quests',
      quest.toMap(),
      where: 'id = ?',
      whereArgs: [quest.id],
    );
  }

  Future<int> deleteQuest(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'quests',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === USER PROFILE OPERATIONS ===
  Future<UserProfile?> getUserProfile() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('user_profile', limit: 1);

    if (maps.isEmpty) {
      // Create default user if doesn't exist
      final defaultUser = UserProfile(
        id: 1,
        displayName: 'Adventurer',
        level: 1,
        currentXp: 0,
        xpToNextLevel: 100,
        totalCoins: 0,
        streakDays: 0,
        tasksCompleted: 0,
        efficiencyRate: 0.0,
        lastLogin: DateTime.now(),
      );
      await db.insert('user_profile', defaultUser.toMap());
      return defaultUser;
    }

    return UserProfile.fromMap(maps.first);
  }

  Future<int> updateUserProfile(UserProfile user) async {
    final db = await _dbHelper.database;
    user.lastLogin = DateTime.now();
    return await db.update(
      'user_profile',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> addUserXp(int xp) async {
    final user = await getUserProfile();
    if (user == null) return 0;

    user.currentXp += xp;
    user.tasksCompleted += 1;

    // Update streak
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (user.lastTaskDate == null) {
      user.streakDays = 1;
    } else if (user.lastTaskDate!.year == yesterday.year &&
        user.lastTaskDate!.month == yesterday.month &&
        user.lastTaskDate!.day == yesterday.day) {
      user.streakDays += 1;
    } else if (user.lastTaskDate!.year == today.year &&
        user.lastTaskDate!.month == today.month &&
        user.lastTaskDate!.day == today.day) {
      // Already completed task today
    } else {
      user.streakDays = 1;
    }

    user.lastTaskDate = today;

    // Level up logic
    while (user.currentXp >= user.xpToNextLevel) {
      user.currentXp -= user.xpToNextLevel;
      user.level += 1;
      user.xpToNextLevel = (100 * pow(user.level, 1.5)).round();
    }

    return await updateUserProfile(user);
  }

  Future<int> addUserCoins(int coins) async {
    final user = await getUserProfile();
    if (user == null) return 0;

    user.totalCoins += coins;
    return await updateUserProfile(user);
  }

  Future<int> updateUserDisplayName(String newName) async {
    final user = await getUserProfile();
    if (user == null) return 0;

    user.displayName = newName;
    return await updateUserProfile(user);
  }

  // === ACHIEVEMENT OPERATIONS (UPDATED) ===
  Future<List<Achievement>> getAllAchievements() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('achievements');
    return List.generate(maps.length, (i) => Achievement.fromMap(maps[i]));
  }

  Future<List<Achievement>> getEarnedAchievements() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'achievements',
      where: 'is_earned = 1',
      orderBy: 'earned_at DESC',
    );
    return List.generate(maps.length, (i) => Achievement.fromMap(maps[i]));
  }

  Future<int> earnAchievement(int achievementId) async {
    final db = await _dbHelper.database;
    final achievement = await getAchievementById(achievementId);
    if (achievement == null) return 0;

    // Award XP to user
    if (achievement.xpReward > 0) {
      await addUserXp(achievement.xpReward);
    }

    return await db.update(
      'achievements',
      achievement.markAsEarned().toMap(),
      where: 'id = ?',
      whereArgs: [achievementId],
    );
  }

  Future<Achievement?> getAchievementById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'achievements',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Achievement.fromMap(maps.first);
  }

  Future<Achievement?> getAchievementByTitle(String title) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'achievements',
      where: 'title = ?',
      whereArgs: [title],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Achievement.fromMap(maps.first);
  }

  Future<int> getTotalAchievementsCount() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM achievements')) ??
        0;
    return count;
  }

  Future<int> getEarnedAchievementsCount() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM achievements WHERE is_earned = 1')) ??
        0;
    return count;
  }

  // === ACHIEVEMENT CHECKING SYSTEM ===
  Future<void> checkAndAwardAchievements() async {
    final user = await getUserProfile();
    if (user == null) return;

    final allAchievements = await getAllAchievements();
    final earnedAchievements = await getEarnedAchievements();
    final earnedIds = earnedAchievements.map((a) => a.id).toList();

    for (var achievement in allAchievements) {
      if (achievement.id != null && earnedIds.contains(achievement.id)) {
        continue; // Already earned
      }

      bool shouldAward = false;

      // Check achievement criteria
      switch (achievement.category) {
        case 'quest':
          shouldAward = _checkQuestAchievement(achievement, user);
          break;
        case 'streak':
          shouldAward = _checkStreakAchievement(achievement, user);
          break;
        case 'productivity':
          shouldAward = _checkProductivityAchievement(achievement, user);
          break;
        case 'level':
          shouldAward = _checkLevelAchievement(achievement, user);
          break;
        case 'speed':
          shouldAward = _checkSpeedAchievement(achievement, user);
          break;
        case 'special':
          shouldAward = _checkSpecialAchievement(achievement, user);
          break;
      }

      if (shouldAward && achievement.id != null) {
        await earnAchievement(achievement.id!);
        // Show notification or snackbar
        print('Achievement earned: ${achievement.title}');
      }
    }
  }

  bool _checkQuestAchievement(Achievement achievement, UserProfile user) {
    final title = achievement.title.toLowerCase();

    if (title.contains('first') && user.tasksCompleted >= 1) {
      return true;
    }
    if (title.contains('beginner') && user.tasksCompleted >= 10) {
      return true;
    }
    if (title.contains('veteran') && user.tasksCompleted >= 50) {
      return true;
    }
    if (title.contains('legend') && user.tasksCompleted >= 100) {
      return true;
    }

    return false;
  }

  bool _checkStreakAchievement(Achievement achievement, UserProfile user) {
    final title = achievement.title.toLowerCase();

    if (title.contains('warrior') && user.streakDays >= 7) {
      return true;
    }
    if (title.contains('master') && user.streakDays >= 30) {
      return true;
    }

    return false;
  }

  bool _checkProductivityAchievement(
      Achievement achievement, UserProfile user) {
    final title = achievement.title.toLowerCase();

    if (title.contains('explorer') && user.efficiencyRate >= 0.8) {
      return true;
    }
    if (title.contains('guru') && user.efficiencyRate >= 0.95) {
      return true;
    }

    return false;
  }

  bool _checkLevelAchievement(Achievement achievement, UserProfile user) {
    final title = achievement.title.toLowerCase();

    if (title.contains('level up') && user.level >= 5) {
      return true;
    }
    if (title.contains('xp collector') && user.currentXp >= 1000) {
      return true;
    }

    return false;
  }

  bool _checkSpeedAchievement(Achievement achievement, UserProfile user) {
    // Implement speed-based achievement logic
    return false;
  }

  bool _checkSpecialAchievement(Achievement achievement, UserProfile user) {
    // Implement special achievement logic
    return false;
  }

  // === TREASURE OPERATIONS ===
  Future<List<TreasureLevel>> getAllTreasures() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('treasures', orderBy: 'requiredTasks ASC');
    return List.generate(maps.length, (i) => TreasureLevel.fromMap(maps[i]));
  }

  Future<int> unlockTreasure(int treasureId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'treasures',
      {
        'isUnlocked': 1,
        'unlockedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [treasureId],
    );
  }

  Future<int> claimTreasure(int treasureId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'treasures',
      {
        'isClaimed': 1,
        'claimedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [treasureId],
    );
  }

  Future<List<TreasureLevel>> getUnlockedTreasures() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'treasures',
      where: 'isUnlocked = 1',
      orderBy: 'unlockedAt DESC',
    );
    return List.generate(maps.length, (i) => TreasureLevel.fromMap(maps[i]));
  }

  Future<int> getTotalTreasuresUnlocked() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM treasures WHERE isUnlocked = 1')) ??
        0;
    return count;
  }

  Future<int> getTotalTreasures() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM treasures')) ??
        0;
    return count;
  }

  Future<TreasureLevel?> getTreasureById(int treasureId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'treasures',
      where: 'id = ?',
      whereArgs: [treasureId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return TreasureLevel.fromMap(maps.first);
  }

  Future<int> updateUserTreasureProgress(int treasureId) async {
    final user = await getUserProfile();
    if (user == null) return 0;

    int bonusCoins = 0;
    switch (treasureId) {
      case 1:
        bonusCoins = 200;
        break;
      case 2:
        bonusCoins = 400;
        break;
      case 3:
        bonusCoins = 600;
        break;
      case 4:
        bonusCoins = 800;
        break;
      case 5:
        bonusCoins = 1000;
        break;
      case 6:
        bonusCoins = 1500;
        break;
      case 7:
        bonusCoins = 2000;
        break;
      case 8:
        bonusCoins = 2500;
        break;
      case 9:
        bonusCoins = 3000;
        break;
      case 10:
        bonusCoins = 4000;
        break;
      default:
        bonusCoins = 500;
        break;
    }

    await addUserCoins(bonusCoins);
    user.lastLogin = DateTime.now();

    return await updateUserProfile(user);
  }

  Future<bool> initializeDefaultTreasures() async {
    try {
      final existingTreasures = await getAllTreasures();
      if (existingTreasures.isNotEmpty) return true;

      final treasures = [
        // ... (keep the same treasure data as before)
        TreasureLevel(
          id: 1,
          title: "Novice Adventurer",
          description: "Complete your first 20 tasks.",
          colorHex: "#4CAF50",
          iconData: "celebration",
          positionX: 0.1,
          positionY: 0.5,
          requiredTasks: 20,
          rewards: ["+200 Coins", "+50 XP", "Novice Badge"],
        ),
        // ... (add other treasures with updated iconData)
      ];

      final db = await _dbHelper.database;
      for (var treasure in treasures) {
        await db.insert('treasures', treasure.toMap());
      }

      return true;
    } catch (e) {
      print('Error initializing default treasures: $e');
      return false;
    }
  }

  // === STATISTICS OPERATIONS ===
  Future<List<DailyStat>> getWeeklyStats() async {
    final db = await _dbHelper.database;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_stats',
      where: 'date >= ?',
      whereArgs: [weekAgo.toIso8601String()],
      orderBy: 'date ASC',
    );
    return List.generate(maps.length, (i) => DailyStat.fromMap(maps[i]));
  }

  Future<int> updateTodayStats(
      int tasksCompleted, double productivityScore) async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final todayString =
        DateTime(today.year, today.month, today.day).toIso8601String();

    final existing = await db.query(
      'daily_stats',
      where: 'date LIKE ?',
      whereArgs: ['${todayString.split('T')[0]}%'],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'daily_stats',
        {
          'tasksCompleted':
              (existing.first['tasksCompleted'] as int) + tasksCompleted,
          'productivityScore': productivityScore,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      return await db.insert('daily_stats', {
        'date': todayString,
        'tasksCompleted': tasksCompleted,
        'productivityScore': productivityScore,
        'focusMinutes': 0,
      });
    }
  }

  // === STATISTICS CALCULATIONS ===
  Future<Map<String, dynamic>> getOverallStatistics() async {
    final db = await _dbHelper.database;

    final totalQuests = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM quests')) ??
        0;

    final completedQuests = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM quests WHERE isCompleted = 1')) ??
        0;

    final totalXp = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT SUM(xpReward) FROM quests WHERE isCompleted = 1')) ??
        0;

    final totalCoins = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT SUM(coinsReward) FROM quests WHERE isCompleted = 1')) ??
        0;

    final earnedAchievements = await getEarnedAchievementsCount();
    final totalAchievements = await getTotalAchievementsCount();

    final unlockedTreasures = await getTotalTreasuresUnlocked();
    final totalTreasures = await getTotalTreasures();

    final user = await getUserProfile();

    return {
      'totalQuests': totalQuests,
      'completedQuests': completedQuests,
      'completionRate': totalQuests > 0 ? (completedQuests / totalQuests) : 0,
      'totalXpEarned': totalXp,
      'totalCoinsEarned': totalCoins,
      'streakDays': user?.streakDays ?? 0,
      'currentLevel': user?.level ?? 1,
      'efficiencyRate': user?.efficiencyRate ?? 0.0,
      'tasksCompleted': user?.tasksCompleted ?? 0,
      'achievementsEarned': earnedAchievements,
      'totalAchievements': totalAchievements,
      'unlockedTreasures': unlockedTreasures,
      'totalTreasures': totalTreasures,
    };
  }

  // === CATEGORY COUNT ===
  Future<Map<String, int>> getCategoryCounts() async {
    final db = await _dbHelper.database;

    final categories = [
      'Work',
      'Study',
      'Personal',
      'Health',
      'Finance',
      'Other'
    ];
    final counts = <String, int>{};

    for (var category in categories) {
      final count = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM quests WHERE category = ?', [category])) ??
          0;
      counts[category] = count;
    }

    final total = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM quests')) ??
        0;
    counts['All'] = total;

    return counts;
  }

  // === DATABASE INITIALIZATION ===
  Future<void> initializeDatabase() async {
    // Initialize default achievements
    await _initializeDefaultAchievements();

    // Initialize default treasures
    await initializeDefaultTreasures();

    print('Database initialized with default data');
  }

  Future<void> _initializeDefaultAchievements() async {
    try {
      final existingAchievements = await getAllAchievements();
      if (existingAchievements.isNotEmpty) return;

      final db = await _dbHelper.database;

      final defaultAchievements = [
        Achievement(
          title: 'First Steps',
          description: 'Complete your first 20 tasks',
          iconName: 'celebration',
          colorHex: '#4CAF50',
          isEarned: false,
          xpReward: 100,
          category: 'quest',
        ),
        Achievement(
          title: 'Week Warrior',
          description: 'Maintain a 7-day streak',
          iconName: 'local_fire_department',
          colorHex: '#2196F3',
          isEarned: false,
          earnedAt: null,
          xpReward: 200,
          category: 'streak',
        ),
        Achievement(
          title: 'Monthly Master',
          description: 'Maintain a 30-day streak',
          iconName: 'workspace_premium',
          colorHex: '#FF9800',
          isEarned: false,
          earnedAt: null,
          xpReward: 500,
          category: 'streak',
        ),
        Achievement(
          title: 'Task Beginner',
          description: 'Complete 50 tasks',
          iconName: 'checkCircle',
          colorHex: '#9C27B0',
          isEarned: false,
          earnedAt: null,
          xpReward: 150,
          category: 'quest',
        ),
        Achievement(
          title: 'Task Veteran',
          description: 'Complete 150 tasks',
          iconName: 'emoji_events',
          colorHex: '#F44336',
          isEarned: false,
          earnedAt: null,
          xpReward: 300,
          category: 'quest',
        ),
        Achievement(
          title: 'Task Legend',
          description: 'Complete 300 tasks',
          iconName: 'diamond',
          colorHex: '#673AB7',
          isEarned: false,
          earnedAt: null,
          xpReward: 600,
          category: 'quest',
        ),
        Achievement(
          title: 'Efficient Explorer',
          description: 'Achieve 80% efficiency rate',
          iconName: 'trendingUp',
          colorHex: '#00BCD4',
          isEarned: false,
          earnedAt: null,
          xpReward: 250,
          category: 'productivity',
        ),
        Achievement(
          title: 'Productivity Guru',
          description: 'Achieve 95% efficiency rate',
          iconName: 'stars',
          colorHex: '#8BC34A',
          isEarned: false,
          earnedAt: null,
          xpReward: 400,
          category: 'productivity',
        ),
        Achievement(
          title: 'Early Bird',
          description: 'Complete 5 tasks before 9 AM',
          iconName: 'zap',
          colorHex: '#FFC107',
          isEarned: false,
          earnedAt: null,
          xpReward: 150,
          category: 'special',
        ),
        Achievement(
          title: 'Speed Demon',
          description: 'Complete a task within 30 minutes of creation',
          iconName: 'speed',
          colorHex: '#E91E63',
          isEarned: false,
          earnedAt: null,
          xpReward: 200,
          category: 'speed',
        ),
        Achievement(
          title: 'Level Up',
          description: 'Reach level 5',
          iconName: 'star',
          colorHex: '#9C27B0',
          isEarned: false,
          earnedAt: null,
          xpReward: 300,
          category: 'level',
        ),
        Achievement(
          title: 'XP Collector',
          description: 'Earn 1000 total XP',
          iconName: 'auto_awesome',
          colorHex: '#3F51B5',
          isEarned: false,
          earnedAt: null,
          xpReward: 500,
          category: 'level',
        ),
      ];

      // Insert achievements with proper field names
      for (var i = 0; i < defaultAchievements.length; i++) {
        final achievement = defaultAchievements[i];
        final map = achievement.copyWith(id: i + 1).toMap();
        await db.insert('achievements', map);
      }
    } catch (e) {
      print('Error initializing default achievements: $e');
    }
  }

  // === BACKUP & RESTORE ===
  Future<bool> resetDatabase() async {
    try {
      final db = await _dbHelper.database;

      // Delete all data from tables (but keep table structure)
      await db.delete('quests');
      await db.delete('achievements');
      await db.delete('treasures');
      await db.delete('daily_stats');

      // Reset user profile to default
      await db.delete('user_profile');

      // Re-initialize default data
      await initializeDatabase();

      return true;
    } catch (e) {
      print('Error resetting database: $e');
      return false;
    }
  }
}
