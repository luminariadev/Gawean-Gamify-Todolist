import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math';
import '../models/quest.dart';
import '../models/user_profile.dart';
import '../models/achievement.dart';
import '../models/treasure.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'quest_adventure_v6.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create quests table
    await db.execute('''
      CREATE TABLE quests(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        priority TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        progress REAL DEFAULT 0.0,
        isCompleted INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        xpReward INTEGER DEFAULT 15,
        coinsReward INTEGER DEFAULT 10,
        colorHex TEXT
      )
    ''');

    // Create user_profile table
    await db.execute('''
      CREATE TABLE user_profile(
        id INTEGER PRIMARY KEY,
        displayName TEXT NOT NULL,
        photoPath TEXT,
        level INTEGER DEFAULT 1,
        currentXp INTEGER DEFAULT 0,
        xpToNextLevel INTEGER DEFAULT 100,
        totalCoins INTEGER DEFAULT 0,
        streakDays INTEGER DEFAULT 0,
        tasksCompleted INTEGER DEFAULT 0,
        efficiencyRate REAL DEFAULT 0.0,
        lastLogin TEXT,
        lastTaskDate TEXT,
        selectedTheme TEXT,
        highestStreak INTEGER DEFAULT 0,
        accountCreated TEXT,
        treasuresUnlocked INTEGER DEFAULT 0,
        achievementsEarned INTEGER DEFAULT 0,
        totalQuestsCreated INTEGER DEFAULT 0,
        averageProductivity REAL DEFAULT 0.0
      )
    ''');

    // Create achievements table
    await db.execute('''
      CREATE TABLE achievements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        icon_name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        is_earned INTEGER DEFAULT 0,
        earned_at TEXT,
        xp_reward INTEGER DEFAULT 0,
        category TEXT NOT NULL
      )
    ''');

    // Create treasures table
    await db.execute('''
      CREATE TABLE treasures(
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        colorHex TEXT NOT NULL,
        iconData TEXT NOT NULL,
        positionX REAL NOT NULL,
        positionY REAL NOT NULL,
        requiredTasks INTEGER NOT NULL,
        rewards TEXT NOT NULL,
        isUnlocked INTEGER DEFAULT 0,
        isClaimed INTEGER DEFAULT 0,
        unlockedAt TEXT,
        claimedAt TEXT
      )
    ''');

    // Create daily_stats table
    await db.execute('''
      CREATE TABLE daily_stats(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        tasksCompleted INTEGER DEFAULT 0,
        productivityScore REAL DEFAULT 0.0,
        focusMinutes INTEGER DEFAULT 0
      )
    ''');

    // Insert default data
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Upgrading database from version $oldVersion to $newVersion');

    // Version 1 to 2
    if (oldVersion < 2) {
      try {
        await db.execute(
            'ALTER TABLE quests ADD COLUMN coinsReward INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE user_profile ADD COLUMN totalCoins INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE user_profile ADD COLUMN streakDays INTEGER DEFAULT 0');
        print('✅ Upgraded to version 2');
      } catch (e) {
        print('⚠️ Error upgrading to version 2: $e');
      }
    }

    // Version 2 to 3
    if (oldVersion < 3) {
      try {
        await _resetUserData(db);
        print('✅ Upgraded to version 3');
      } catch (e) {
        print('⚠️ Error upgrading to version 3: $e');
      }
    }

    // Version 3 to 4
    if (oldVersion < 4) {
      try {
        await _upgradeToVersion4(db);
        print('✅ Upgraded to version 4');
      } catch (e) {
        print('⚠️ Error upgrading to version 4: $e');
      }
    }

    // Version 4 to 5
    if (oldVersion < 5) {
      try {
        await _upgradeToVersion5(db);
        print('✅ Upgraded to version 5');
      } catch (e) {
        print('⚠️ Error upgrading to version 5: $e');
      }
    }

    // Version 5 to 6 - Achievements update
    if (oldVersion < 6) {
      try {
        await _upgradeToVersion6(db);
        print('✅ Upgraded to version 6');
      } catch (e) {
        print('⚠️ Error upgrading to version 6: $e');
      }
    }
  }

  Future<void> _resetUserData(Database db) async {
    await db.update(
      'user_profile',
      {
        'level': 1,
        'currentXp': 0,
        'xpToNextLevel': 100,
        'totalCoins': 0,
        'streakDays': 0,
        'tasksCompleted': 0,
        'efficiencyRate': 0.0,
        'lastLogin': DateTime.now().toIso8601String(),
        'highestStreak': 0,
        'accountCreated': DateTime.now().toIso8601String(),
        'treasuresUnlocked': 0,
        'achievementsEarned': 0,
        'totalQuestsCreated': 0,
        'averageProductivity': 0.0,
      },
      where: 'id = 1',
    );
  }

  Future<void> _upgradeToVersion4(Database db) async {
    try {
      // Add new columns to user_profile
      await db.execute('''
        ALTER TABLE user_profile ADD COLUMN highestStreak INTEGER DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE user_profile ADD COLUMN accountCreated TEXT
      ''');
      await db.execute('''
        ALTER TABLE user_profile ADD COLUMN treasuresUnlocked INTEGER DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE user_profile ADD COLUMN achievementsEarned INTEGER DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE user_profile ADD COLUMN totalQuestsCreated INTEGER DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE user_profile ADD COLUMN averageProductivity REAL DEFAULT 0.0
      ''');

      // Update quests XP reward
      await db.execute('''
        UPDATE quests SET xpReward = 15 WHERE xpReward < 15
      ''');

      // Update quests coins reward
      await db.execute('''
        UPDATE quests SET coinsReward = 10 WHERE coinsReward < 10
      ''');

      // Update user XP system to new formula
      final users = await db.query('user_profile');
      for (var user in users) {
        final level = user['level'] as int;
        if (level > 0) {
          final newXpToNextLevel = (100 * pow(level, 1.5)).round();
          await db.update(
            'user_profile',
            {'xpToNextLevel': newXpToNextLevel},
            where: 'id = ?',
            whereArgs: [user['id']],
          );
        }
      }

      // Delete old treasures
      await db.delete('treasures');

      // Insert new treasures
      await _insertVersion4Treasures(db);

      print('✅ Successfully upgraded to version 4');
    } catch (e) {
      print('❌ Error upgrading to version 4: $e');
      // Recreate treasures table
      await db.execute('DROP TABLE IF EXISTS treasures');
      await db.execute('''
        CREATE TABLE treasures(
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          colorHex TEXT NOT NULL,
          iconData TEXT NOT NULL,
          positionX REAL NOT NULL,
          positionY REAL NOT NULL,
          requiredTasks INTEGER NOT NULL,
          rewards TEXT NOT NULL,
          isUnlocked INTEGER DEFAULT 0,
          isClaimed INTEGER DEFAULT 0,
          unlockedAt TEXT,
          claimedAt TEXT
        )
      ''');
      await _insertVersion4Treasures(db);
    }
  }

  Future<void> _upgradeToVersion5(Database db) async {
    try {
      print('🏔️ Upgrading to version 5: Vertical Mountain Layout');

      // Delete all old treasures
      await db.delete('treasures');

      // Insert vertical layout treasures
      await _insertVersion5Treasures(db);

      print('✅ Successfully upgraded to version 5 with vertical layout!');
    } catch (e) {
      print('❌ Error upgrading to version 5: $e');
      // Recreate treasures table
      await db.execute('DROP TABLE IF EXISTS treasures');
      await db.execute('''
        CREATE TABLE treasures(
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          colorHex TEXT NOT NULL,
          iconData TEXT NOT NULL,
          positionX REAL NOT NULL,
          positionY REAL NOT NULL,
          requiredTasks INTEGER NOT NULL,
          rewards TEXT NOT NULL,
          isUnlocked INTEGER DEFAULT 0,
          isClaimed INTEGER DEFAULT 0,
          unlockedAt TEXT,
          claimedAt TEXT
        )
      ''');
      await _insertVersion5Treasures(db);
    }
  }

  Future<void> _upgradeToVersion6(Database db) async {
    try {
      print('🏆 Upgrading to version 6: New Achievement System');

      // Check if old badges table exists
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='badges'");

      if (tables.isNotEmpty) {
        print('🔄 Found old badges table, migrating data...');
        // Migrate data from badges to achievements
        final oldBadges = await db.query('badges');

        // Create new achievements table if not exists
        final achievementsExist = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='achievements'");

        if (achievementsExist.isEmpty) {
          await db.execute('''
            CREATE TABLE achievements(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              description TEXT,
              icon_name TEXT NOT NULL,
              color_hex TEXT NOT NULL,
              is_earned INTEGER DEFAULT 0,
              earned_at TEXT,
              xp_reward INTEGER DEFAULT 0,
              category TEXT NOT NULL
            )
          ''');
        }

        // Migrate each badge
        for (var badge in oldBadges) {
          try {
            final newAchievement = Achievement(
              id: badge['id'] as int?,
              title: badge['title'] as String? ?? 'Unknown',
              description: badge['description'] as String? ?? 'No description',
              iconName: badge['iconData'] as String? ?? 'help_outline',
              colorHex: badge['colorHex'] as String? ?? '#2196F3',
              isEarned: (badge['isEarned'] as int? ?? 0) == 1,
              earnedAt: badge['earnedAt'] != null
                  ? DateTime.parse(badge['earnedAt'] as String)
                  : null,
              xpReward: (badge['xpRequired'] as int? ?? 0),
              category: badge['category'] as String? ?? 'quest',
            );

            await db.insert('achievements', newAchievement.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace);
          } catch (e) {
            print('⚠️ Error migrating badge: $e');
          }
        }

        // Drop old table
        await db.execute('DROP TABLE badges');
        print('✅ Migrated ${oldBadges.length} badges to achievements');
      } else {
        print('ℹ️ No old badges table found');
      }

      // Ensure achievements table has data
      final count = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM achievements')) ??
          0;

      if (count == 0) {
        print('📝 Inserting default achievements');
        await _insertDefaultAchievements(db);
      }

      print('✅ Successfully upgraded to version 6');
    } catch (e) {
      print('❌ Error upgrading to version 6: $e');
      // Ensure achievements table exists
      try {
        await db.execute('DROP TABLE IF EXISTS achievements');
        await db.execute('''
          CREATE TABLE achievements(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            icon_name TEXT NOT NULL,
            color_hex TEXT NOT NULL,
            is_earned INTEGER DEFAULT 0,
            earned_at TEXT,
            xp_reward INTEGER DEFAULT 0,
            category TEXT NOT NULL
          )
        ''');
        await _insertDefaultAchievements(db);
      } catch (e2) {
        print('❌ Critical error creating achievements table: $e2');
      }
    }
  }

  Future<void> _insertDefaultAchievements(Database db) async {
    final defaultAchievements = [
      Achievement(
        title: 'First Steps',
        description: 'Complete your first task',
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
        description: 'Complete 10 tasks',
        iconName: 'checkCircle',
        colorHex: '#9C27B0',
        isEarned: false,
        earnedAt: null,
        xpReward: 150,
        category: 'quest',
      ),
      Achievement(
        title: 'Task Veteran',
        description: 'Complete 50 tasks',
        iconName: 'emoji_events',
        colorHex: '#F44336',
        isEarned: false,
        earnedAt: null,
        xpReward: 300,
        category: 'quest',
      ),
      Achievement(
        title: 'Task Legend',
        description: 'Complete 100 tasks',
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

    for (var i = 0; i < defaultAchievements.length; i++) {
      final achievement = defaultAchievements[i].copyWith(id: i + 1);
      await db.insert('achievements', achievement.toMap());
    }

    print('✅ Inserted ${defaultAchievements.length} default achievements');
  }

  Future<void> _insertVersion4Treasures(Database db) async {
    final newTreasures = [
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
        isUnlocked: false,
        isClaimed: false,
      ),
      TreasureLevel(
        id: 2,
        title: "Task Initiate",
        description: "Complete 40 tasks.",
        colorHex: "#2196F3",
        iconData: "workspace_premium",
        positionX: 0.18,
        positionY: 0.35,
        requiredTasks: 40,
        rewards: ["+400 Coins", "+100 XP", "Initiate Badge"],
        isUnlocked: false,
        isClaimed: false,
      ),
      TreasureLevel(
        id: 3,
        title: "Consistent Contributor",
        description: "Reach 60 tasks.",
        colorHex: "#9C27B0",
        iconData: "emoji_events",
        positionX: 0.26,
        positionY: 0.6,
        requiredTasks: 60,
        rewards: ["+600 Coins", "+150 XP", "Contributor Title"],
        isUnlocked: false,
        isClaimed: false,
      ),
      TreasureLevel(
        id: 4,
        title: "Productive Explorer",
        description: "Complete 80 tasks.",
        colorHex: "#FF9800",
        iconData: "diamond",
        positionX: 0.34,
        positionY: 0.3,
        requiredTasks: 80,
        rewards: ["+800 Coins", "+200 XP", "Explorer Badge", "Bronze Avatar"],
        isUnlocked: false,
        isClaimed: false,
      ),
      TreasureLevel(
        id: 5,
        title: "Dedicated Achiever",
        description: "Complete 100 tasks.",
        colorHex: "#F44336",
        iconData: "stars",
        positionX: 0.42,
        positionY: 0.5,
        requiredTasks: 100,
        rewards: ["+1000 Coins", "+250 XP", "Achiever Badge", "Silver Theme"],
        isUnlocked: false,
        isClaimed: false,
      ),
    ];

    for (var treasure in newTreasures) {
      await db.insert('treasures', treasure.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _insertVersion5Treasures(Database db) async {
    final verticalTreasures = [
      TreasureLevel(
        id: 1,
        title: "Novice Adventurer",
        description: "Complete your first 20 tasks.",
        colorHex: "#4CAF50",
        iconData: "celebration",
        positionX: 0.5,
        positionY: 0.85,
        requiredTasks: 20,
        rewards: ["+200 Coins", "+50 XP", "Novice Badge"],
        isUnlocked: false,
        isClaimed: false,
      ),
      TreasureLevel(
        id: 2,
        title: "Task Initiate",
        description: "Complete 40 tasks.",
        colorHex: "#2196F3",
        iconData: "workspace_premium",
        positionX: 0.35,
        positionY: 0.75,
        requiredTasks: 40,
        rewards: ["+400 Coins", "+100 XP", "Initiate Badge"],
        isUnlocked: false,
        isClaimed: false,
      ),
      TreasureLevel(
        id: 3,
        title: "Consistent Contributor",
        description: "Reach 60 tasks.",
        colorHex: "#9C27B0",
        iconData: "emoji_events",
        positionX: 0.65,
        positionY: 0.65,
        requiredTasks: 60,
        rewards: ["+600 Coins", "+150 XP", "Contributor Title"],
        isUnlocked: false,
        isClaimed: false,
      ),
      TreasureLevel(
        id: 4,
        title: "Productive Explorer",
        description: "Complete 80 tasks.",
        colorHex: "#FF9800",
        iconData: "diamond",
        positionX: 0.25,
        positionY: 0.55,
        requiredTasks: 80,
        rewards: ["+800 Coins", "+200 XP", "Explorer Badge", "Bronze Avatar"],
        isUnlocked: false,
        isClaimed: false,
      ),
      TreasureLevel(
        id: 5,
        title: "Dedicated Achiever",
        description: "Complete 100 tasks.",
        colorHex: "#F44336",
        iconData: "stars",
        positionX: 0.75,
        positionY: 0.45,
        requiredTasks: 100,
        rewards: ["+1000 Coins", "+250 XP", "Achiever Badge", "Silver Theme"],
        isUnlocked: false,
        isClaimed: false,
      ),
      TreasureLevel(
        id: 6,
        title: "Master Organizer",
        description: "Complete 150 tasks.",
        colorHex: "#00BCD4",
        iconData: "workspace_premium",
        positionX: 0.4,
        positionY: 0.35,
        requiredTasks: 150,
        rewards: ["+1500 Coins", "+350 XP", "Organizer Title", "Gold Avatar"],
        isUnlocked: false,
        isClaimed: false,
      ),
      TreasureLevel(
        id: 7,
        title: "Elite Performer",
        description: "Complete 200 tasks.",
        colorHex: "#8BC34A",
        iconData: "emoji_events",
        positionX: 0.6,
        positionY: 0.25,
        requiredTasks: 200,
        rewards: ["+2000 Coins", "+500 XP", "Elite Badge", "Gold Frame"],
        isUnlocked: false,
        isClaimed: false,
      ),
      TreasureLevel(
        id: 8,
        title: "Productivity Champion",
        description: "Complete 250 tasks.",
        colorHex: "#FF5722",
        iconData: "diamond",
        positionX: 0.3,
        positionY: 0.15,
        requiredTasks: 250,
        rewards: [
          "+2500 Coins",
          "+750 XP",
          "Champion Badge",
          "Platinum Avatar"
        ],
        isUnlocked: false,
        isClaimed: false,
      ),
      TreasureLevel(
        id: 9,
        title: "Grand Master",
        description: "Complete 300 tasks.",
        colorHex: "#673AB7",
        iconData: "stars",
        positionX: 0.7,
        positionY: 0.08,
        requiredTasks: 300,
        rewards: ["+3000 Coins", "+1000 XP", "Master Title", "Diamond Theme"],
        isUnlocked: false,
        isClaimed: false,
      ),
      TreasureLevel(
        id: 10,
        title: "Legendary Hero",
        description: "Complete 400 tasks.",
        colorHex: "#E91E63",
        iconData: "workspace_premium",
        positionX: 0.5,
        positionY: 0.02,
        requiredTasks: 400,
        rewards: [
          "+4000 Coins",
          "+1500 XP",
          "Legendary Badge",
          "Legendary Avatar",
          "Eternal Glory"
        ],
        isUnlocked: false,
        isClaimed: false,
      ),
    ];

    for (var treasure in verticalTreasures) {
      await db.insert('treasures', treasure.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    // Insert default user profile
    final defaultUser = UserProfile(
      id: 1,
      displayName: 'Adventurer',
      photoPath: '',
      level: 1,
      currentXp: 0,
      xpToNextLevel: 100,
      totalCoins: 0,
      streakDays: 0,
      tasksCompleted: 0,
      efficiencyRate: 0.0,
      lastLogin: DateTime.now(),
      lastTaskDate: null,
      selectedTheme: 'light',
      highestStreak: 0,
      accountCreated: DateTime.now(),
      treasuresUnlocked: 0,
      achievementsEarned: 0,
      totalQuestsCreated: 0,
      averageProductivity: 0.0,
    );

    await db.insert('user_profile', defaultUser.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    // Insert default achievements
    await _insertDefaultAchievements(db);

    // Insert treasures with vertical layout
    await _insertVersion5Treasures(db);

    // Insert sample daily stats
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      await db.insert('daily_stats', {
        'date': date.toIso8601String(),
        'tasksCompleted': [5, 6, 4, 7, 8, 6, 9][i],
        'productivityScore': [4.0, 4.5, 3.8, 5.1, 6.0, 5.5, 6.8][i],
        'focusMinutes': [150, 180, 120, 240, 300, 270, 350][i],
      });
    }
  }

  // ========== PUBLIC METHODS ==========

  // User Profile
  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_profile');
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUserProfile(UserProfile user) async {
    final db = await database;
    return await db.update(
      'user_profile',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Quests
  Future<List<Quest>> getQuests() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('quests', orderBy: 'date DESC, priority DESC');
    return List.generate(maps.length, (i) => Quest.fromMap(maps[i]));
  }

  Future<int> insertQuest(Quest quest) async {
    final db = await database;
    return await db.insert('quests', quest.toMap());
  }

  Future<int> updateQuest(Quest quest) async {
    final db = await database;
    return await db.update(
      'quests',
      quest.toMap(),
      where: 'id = ?',
      whereArgs: [quest.id],
    );
  }

  Future<int> deleteQuest(int id) async {
    final db = await database;
    return await db.delete('quests', where: 'id = ?', whereArgs: [id]);
  }

  // Achievements
  Future<List<Achievement>> getAllAchievements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('achievements', orderBy: 'xp_reward ASC');
    return List.generate(maps.length, (i) => Achievement.fromMap(maps[i]));
  }

  Future<List<Achievement>> getEarnedAchievements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'achievements',
      where: 'is_earned = 1',
      orderBy: 'earned_at DESC',
    );
    return List.generate(maps.length, (i) => Achievement.fromMap(maps[i]));
  }

  Future<int> getTotalAchievementsCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM achievements')) ??
        0;
    return count;
  }

  Future<int> getEarnedAchievementsCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM achievements WHERE is_earned = 1')) ??
        0;
    return count;
  }

  Future<int> updateAchievement(Achievement achievement) async {
    final db = await database;
    return await db.update(
      'achievements',
      achievement.toMap(),
      where: 'id = ?',
      whereArgs: [achievement.id],
    );
  }

  Future<Achievement?> getAchievementById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'achievements',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Achievement.fromMap(maps.first);
  }

  // Untuk backward compatibility (digunakan oleh profile_page)
  Future<List<Achievement>> getEarnedBadges() async {
    return await getEarnedAchievements();
  }

  // Treasures
  Future<List<TreasureLevel>> getAllTreasures() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('treasures', orderBy: 'requiredTasks ASC');
    return List.generate(maps.length, (i) => TreasureLevel.fromMap(maps[i]));
  }

  Future<int> getTreasuresCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM treasures')) ??
        0;
    return count;
  }

  Future<int> getUnlockedTreasuresCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM treasures WHERE isUnlocked = 1')) ??
        0;
    return count;
  }

  Future<int> updateTreasure(TreasureLevel treasure) async {
    final db = await database;
    return await db.update(
      'treasures',
      treasure.toMap(),
      where: 'id = ?',
      whereArgs: [treasure.id],
    );
  }

  // Daily Stats
  Future<List<Map<String, dynamic>>> getDailyStats() async {
    final db = await database;
    return await db.query('daily_stats', orderBy: 'date ASC');
  }

  Future<int> upsertDailyStats({
    required DateTime date,
    int tasksCompleted = 0,
    double productivityScore = 0.0,
    int focusMinutes = 0,
  }) async {
    final db = await database;
    final dateString = date.toIso8601String();

    final existing = await db.query(
      'daily_stats',
      where: 'date LIKE ?',
      whereArgs: ['${dateString.split('T')[0]}%'],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'daily_stats',
        {
          'tasksCompleted': tasksCompleted,
          'productivityScore': productivityScore,
          'focusMinutes': focusMinutes,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      return await db.insert('daily_stats', {
        'date': dateString,
        'tasksCompleted': tasksCompleted,
        'productivityScore': productivityScore,
        'focusMinutes': focusMinutes,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final db = await database;
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));

    return await db.query(
      'daily_stats',
      where: 'date >= ?',
      whereArgs: [weekAgo.toIso8601String()],
      orderBy: 'date ASC',
    );
  }

  // Statistics
  Future<Map<String, dynamic>> getTotalStatistics() async {
    final db = await database;

    final userProfile = await getUserProfile();
    final totalTasks = userProfile?.tasksCompleted ?? 0;
    final unlockedTreasures = await getUnlockedTreasuresCount();
    final totalTreasures = await getTreasuresCount();
    final earnedAchievements = await getEarnedAchievementsCount();
    final totalAchievements = await getTotalAchievementsCount();

    final stats = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalDays,
        SUM(tasksCompleted) as totalDailyTasks,
        AVG(productivityScore) as avgProductivity,
        SUM(focusMinutes) as totalFocusMinutes
      FROM daily_stats
    ''');

    Map<String, dynamic> result = {
      'totalDays': 0,
      'totalTasks': totalTasks,
      'avgProductivity': 0.0,
      'totalFocusMinutes': 0,
      'totalDailyTasks': 0,
      'unlockedTreasures': unlockedTreasures,
      'totalTreasures': totalTreasures,
      'treasureProgress':
          totalTreasures > 0 ? unlockedTreasures / totalTreasures : 0.0,
      'earnedAchievements': earnedAchievements,
      'totalAchievements': totalAchievements,
      'achievementProgress':
          totalAchievements > 0 ? earnedAchievements / totalAchievements : 0.0,
    };

    if (stats.isNotEmpty && stats.first.isNotEmpty) {
      result['totalDays'] = stats.first['totalDays'] ?? 0;
      result['avgProductivity'] = stats.first['avgProductivity'] ?? 0.0;
      result['totalFocusMinutes'] = stats.first['totalFocusMinutes'] ?? 0;
      result['totalDailyTasks'] = stats.first['totalDailyTasks'] ?? 0;
    }

    return result;
  }

  // Maintenance
  Future<void> checkAndUpdateXpSystem() async {
    final db = await database;
    final users = await db.query('user_profile');

    for (var user in users) {
      final level = user['level'] as int;
      final currentXpToNextLevel = user['xpToNextLevel'] as int;
      final correctXpToNextLevel = (100 * pow(level, 1.5)).round();

      if (currentXpToNextLevel != correctXpToNextLevel) {
        await db.update(
          'user_profile',
          {'xpToNextLevel': correctXpToNextLevel},
          where: 'id = ?',
          whereArgs: [user['id']],
        );
      }
    }
  }

  Future<void> ensureTenTreasures() async {
    final db = await database;
    final treasuresCount = await getTreasuresCount();

    if (treasuresCount != 10) {
      await db.delete('treasures');
      await _insertVersion5Treasures(db);
    }
  }

  Future<void> ensureVerticalLayout() async {
    final db = await database;
    final treasures = await getAllTreasures();

    final hasHorizontalLayout =
        treasures.any((treasure) => treasure.positionY > 0.5);

    if (hasHorizontalLayout) {
      await migrateToVerticalLayout();
    }
  }

  Future<void> migrateToVerticalLayout() async {
    final db = await database;

    // Backup existing treasures status
    final oldTreasures = await getAllTreasures();
    final unlockedIds =
        oldTreasures.where((t) => t.isUnlocked).map((t) => t.id).toList();
    final claimedIds =
        oldTreasures.where((t) => t.isClaimed).map((t) => t.id).toList();

    // Delete old treasures
    await db.delete('treasures');

    // Insert new vertical layout treasures
    await _insertVersion5Treasures(db);

    // Restore unlocked status
    for (int id in unlockedIds) {
      await db.update(
        'treasures',
        {'isUnlocked': 1, 'unlockedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    // Restore claimed status
    for (int id in claimedIds) {
      await db.update(
        'treasures',
        {'isClaimed': 1, 'claimedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> ensureAchievementsTable() async {
    final db = await database;

    try {
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='achievements'");

      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE achievements(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            icon_name TEXT NOT NULL,
            color_hex TEXT NOT NULL,
            is_earned INTEGER DEFAULT 0,
            earned_at TEXT,
            xp_reward INTEGER DEFAULT 0,
            category TEXT NOT NULL
          )
        ''');

        await _insertDefaultAchievements(db);
      }
    } catch (e) {
      print('❌ Error ensuring achievements table: $e');
    }
  }

  Future<void> initializeWithChecks() async {
    final db = await database;

    await checkAndUpdateXpSystem();
    await ensureTenTreasures();
    await ensureVerticalLayout();
    await _ensureUserProfileColumns(db);
    await ensureAchievementsTable();
  }

  Future<void> _ensureUserProfileColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(user_profile)');
      final columnNames = columns.map((col) => col['name'] as String).toList();

      final requiredColumns = [
        'highestStreak',
        'accountCreated',
        'treasuresUnlocked',
        'achievementsEarned',
        'totalQuestsCreated',
        'averageProductivity'
      ];

      for (var column in requiredColumns) {
        if (!columnNames.contains(column)) {
          await db.execute(
              'ALTER TABLE user_profile ADD COLUMN $column ${_getColumnType(column)}');
        }
      }
    } catch (e) {
      print('❌ Error checking user profile columns: $e');
    }
  }

  String _getColumnType(String columnName) {
    switch (columnName) {
      case 'highestStreak':
      case 'treasuresUnlocked':
      case 'achievementsEarned':
      case 'totalQuestsCreated':
        return 'INTEGER DEFAULT 0';
      case 'accountCreated':
        return 'TEXT';
      case 'averageProductivity':
        return 'REAL DEFAULT 0.0';
      default:
        return 'TEXT';
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
    }
  }

  // Reset methods for testing
  Future<void> resetDatabase() async {
    final db = await database;

    await db.delete('quests');
    await db.delete('achievements');
    await db.delete('treasures');
    await db.delete('daily_stats');

    // Reset user profile
    await _resetUserData(db);

    // Re-insert default data
    await _insertDefaultAchievements(db);
    await _insertVersion5Treasures(db);
  }
}
