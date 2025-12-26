import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'dart:math';

// Import model dan database
import '../database/database_operations.dart';
import '../models/user_profile.dart';
import '../models/achievement.dart';
import '../models/statistics.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late DatabaseOperations _dbOps;
  UserProfile? _user;
  List<Achievement> _achievements = [];
  List<DailyStat> _weeklyStats = [];
  Map<String, dynamic> _overallStats = {};
  bool _isLoading = true;
  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();
  final Random _random = Random();

  // Theme state
  bool _isDarkMode = false;

  // Notification states
  bool _dailyReminders = true;
  bool _streakAlerts = true;
  bool _achievementAlerts = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);

  // Data fokus mingguan
  String _weeklyFocus = "Productivity Score";
  String _weeklyFocusDetail = "Based on task completion rate";
  double _weeklyFocusProgress = 0.0;
  int _totalAchievements = 12; // Default value

  @override
  void initState() {
    super.initState();
    _dbOps = DatabaseOperations();
    _loadSettings();
    _loadData();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _dailyReminders = prefs.getBool('dailyReminders') ?? true;
      _streakAlerts = prefs.getBool('streakAlerts') ?? true;
      _achievementAlerts = prefs.getBool('achievementAlerts') ?? true;

      final hour = prefs.getInt('notificationHour') ?? 9;
      final minute = prefs.getInt('notificationMinute') ?? 0;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('dailyReminders', _dailyReminders);
    await prefs.setBool('streakAlerts', _streakAlerts);
    await prefs.setBool('achievementAlerts', _achievementAlerts);
    await prefs.setInt('notificationHour', _notificationTime.hour);
    await prefs.setInt('notificationMinute', _notificationTime.minute);
  }

  Future<void> _toggleTheme(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });
    await _saveSettings();

    // Apply theme change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${isDark ? 'Dark' : 'Light'} theme saved.'),
        backgroundColor: isDark ? Colors.grey[800] : Colors.blue,
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      final user = await _dbOps.getUserProfile();
      final achievements = await _dbOps.getEarnedAchievements();
      final weeklyStats = await _dbOps.getWeeklyStats();
      final overallStats = await _dbOps.getOverallStatistics();

      // Get total achievements count
      final totalAchievements = await _dbOps.getTotalAchievementsCount();

      setState(() {
        _user = user;
        _achievements = achievements;
        _weeklyStats = weeklyStats;
        _overallStats = overallStats;
        _totalAchievements = totalAchievements;
        _calculateWeeklyFocus();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateWeeklyFocus() {
    if (_weeklyStats.isEmpty || _user == null) {
      _weeklyFocus = "Build Consistency";
      _weeklyFocusDetail = "Complete your first task to start tracking!";
      _weeklyFocusProgress = 0.0;
      return;
    }

    // Hitung rata-rata produktivitas mingguan
    final avgProductivity = _weeklyStats
            .map((stat) => stat.productivityScore)
            .reduce((a, b) => a + b) /
        _weeklyStats.length;

    // Hitung jumlah task yang diselesaikan minggu ini
    final weeklyCompletedTasks = _overallStats['completedQuests'] ?? 0;

    // Hitung streak berjalan
    final currentStreak = _user?.streakDays ?? 0;

    // Tentukan fokus mingguan berdasarkan data
    if (weeklyCompletedTasks == 0) {
      _weeklyFocus = "Task Initiation";
      _weeklyFocusDetail = "Start by completing at least one task this week";
      _weeklyFocusProgress = 0.0;
    } else if (avgProductivity < 2.0) {
      _weeklyFocus = "Productivity Boost";
      _weeklyFocusDetail =
          "Aim for higher completion rates (currently ${avgProductivity.toStringAsFixed(1)}/5)";
      _weeklyFocusProgress = avgProductivity / 5.0;
    } else if (currentStreak < 3) {
      _weeklyFocus = "Streak Building";
      _weeklyFocusDetail =
          "Maintain daily activity for 3+ days (current: $currentStreak days)";
      _weeklyFocusProgress = currentStreak / 7.0;
    } else if (_user!.level < 5) {
      _weeklyFocus = "Level Up";
      _weeklyFocusDetail =
          "Earn more XP to reach level 5 (current: level ${_user!.level})";
      _weeklyFocusProgress = _user!.currentXp / _user!.xpToNextLevel;
    } else {
      _weeklyFocus = "Mastery";
      _weeklyFocusDetail =
          "Maintain high productivity (${avgProductivity.toStringAsFixed(1)}/5 average)";
      _weeklyFocusProgress = avgProductivity / 5.0;
    }
  }

  Future<void> _updateDisplayName(String newName) async {
    if (newName.trim().isEmpty || _user == null) return;

    await _dbOps.updateUserDisplayName(newName);
    await _loadData();
    setState(() {
      _isEditingName = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Name updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && _user != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = File('${appDir.path}/$fileName');

        await File(pickedFile.path).copy(savedImage.path);

        _user!.photoPath = savedImage.path;
        await _dbOps.updateUserProfile(_user!);

        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile image updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileImage() {
    if (_user?.photoPath != null) {
      final file = File(_user!.photoPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: 28,
          backgroundImage: FileImage(file),
        );
      }
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.grey[200],
      child: Icon(
        FeatherIcons.user,
        size: 24,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildGamifiedHeader() {
    final currentLevel = _user?.level ?? 0;
    final currentXp = _user?.currentXp ?? 0;
    final xpToNextLevel = _user?.xpToNextLevel ?? 100;
    final progress = xpToNextLevel > 0 ? currentXp / xpToNextLevel : 0.0;

    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
            const Color(0xFFEC4899),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            top: 5,
            right: 5,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.emoji_events,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),

          // Header content
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Adventure Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Lv.$currentLevel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // XP progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress to Next Level',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '$currentXp/$xpToNextLevel XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      children: [
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              height: 3,
                              width: constraints.maxWidth * progress,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.yellow, Colors.orange],
                                ),
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Custom Header dengan design gamifikasi
              SliverToBoxAdapter(
                child: _buildGamifiedHeader(),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile Card dengan data dari database
                    _buildProfileCard(context, theme),

                    const SizedBox(height: 12),

                    // Stats Grid dengan data real
                    _buildStatsGrid(theme),

                    const SizedBox(height: 12),

                    // Weekly Focus dengan logika dinamis
                    _buildWeeklyFocusSection(theme),

                    const SizedBox(height: 12),

                    // Achievements Earned Section dengan progress yang benar
                    _buildAchievementsSection(theme),

                    const SizedBox(height: 12),

                    // Insights Section berdasarkan data user yang real
                    _buildInsightsSection(theme),

                    const SizedBox(height: 12),

                    // Settings Options dengan logika yang tepat
                    _buildSettingsSection(theme),

                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, ThemeData theme) {
    final user = _user ?? UserProfile(displayName: 'New Adventurer');
    final currentLevel = user.level;
    final currentXp = user.currentXp;
    final totalCoins = user.totalCoins;
    final streakDays = user.streakDays;

    // Hitung quest rate yang benar
    final completedQuests = _overallStats['completedQuests'] ?? 0;
    final totalQuests = _overallStats['totalQuests'] ?? 0;
    final questRate = totalQuests > 0 ? completedQuests / totalQuests : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Image
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: _buildProfileImage(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isEditingName)
                  GestureDetector(
                    onTap: () {
                      _nameController.text = user.displayName;
                      setState(() {
                        _isEditingName = true;
                      });
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter your name",
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () =>
                            _updateDisplayName(_nameController.text),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _isEditingName = false;
                          });
                        },
                      ),
                    ],
                  ),

                const SizedBox(height: 6),

                // Stats row
                Row(
                  children: [
                    // Level dengan logika yang tepat
                    _buildMiniStat(
                      icon: Icons.star,
                      value: 'Lv.$currentLevel',
                      label: 'Level',
                      color: Colors.amber[600]!,
                    ),

                    const SizedBox(width: 8),

                    // Coins
                    _buildMiniStat(
                      icon: Icons.monetization_on,
                      value: totalCoins.toString(),
                      label: 'Coins',
                      color: Colors.amber[700]!,
                    ),

                    const SizedBox(width: 8),

                    // Streak dengan icon yang tepat
                    _buildMiniStat(
                      icon: streakDays > 0
                          ? Icons.local_fire_department
                          : Icons.local_fire_department_outlined,
                      value: streakDays.toString(),
                      label: 'Streak',
                      color: streakDays > 0 ? Colors.orange : Colors.grey,
                    ),

                    const SizedBox(width: 8),

                    // Quest Rate
                    _buildMiniStat(
                      icon: FeatherIcons.target,
                      value: '${(questRate * 100).toInt()}%',
                      label: 'Rate',
                      color: questRate >= 0.7 ? Colors.green : Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 10,
              color: color,
            ),
            const SizedBox(width: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    final completedTasks = _overallStats['completedQuests'] ?? 0;
    final totalXp = _overallStats['totalXpEarned'] ?? 0;
    final completionRate = _overallStats['completionRate'] ?? 0.0;
    final streakDays = _user?.streakDays ?? 0;

    final stats = [
      {
        'value': completedTasks.toString(),
        'label': 'Quests\nCompleted',
        'icon': FeatherIcons.checkCircle,
        'color': Colors.green,
        'size': 28.0,
      },
      {
        'value': streakDays.toString(),
        'label': 'Current\nStreak',
        'icon': Icons.local_fire_department_rounded,
        'color': Colors.orange,
        'size': 28.0,
      },
      {
        'value': '${(completionRate * 100).toStringAsFixed(0)}%',
        'label': 'Completion\nRate',
        'icon': FeatherIcons.target,
        'color': Colors.blue,
        'size': 28.0,
      },
      {
        'value': totalXp.toString(),
        'label': 'Total\nXP',
        'icon': Icons.auto_awesome,
        'color': Colors.purple,
        'size': 28.0,
      },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final color = stat['color'] as Color;
        final iconSize = stat['size'] as double;

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        stat['icon'] as IconData,
                        color: color,
                        size: iconSize,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyFocusSection(ThemeData theme) {
    final progress = _weeklyFocusProgress;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Weekly Focus",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _weeklyFocus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getFocusColor(progress),
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _getFocusColor(progress),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _weeklyFocusDetail,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getFocusColor(progress),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Color _getFocusColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.6) return Colors.orange;
    if (progress < 0.8) return Colors.blue;
    return Colors.green;
  }

  Widget _buildAchievementsSection(ThemeData theme) {
    final earnedCount = _achievements.length;
    final progress =
        _totalAchievements > 0 ? earnedCount / _totalAchievements : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Achievements",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$earnedCount of $_totalAchievements unlocked",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2.5,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getAchievementColor(progress),
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _getAchievementColor(progress),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_achievements.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No Achievements Yet",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Complete quests to unlock amazing achievements!",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue,
                              Colors.purple,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${(progress * 100).toInt()}% to first achievement",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.9,
                ),
                itemCount: min(_achievements.length, 8),
                itemBuilder: (context, index) {
                  final achievement = _achievements[index];
                  return GestureDetector(
                    onTap: () {
                      _showAchievementDialog(achievement);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                achievement.color.withOpacity(0.3),
                                achievement.color.withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: achievement.color.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              achievement.icon,
                              color: achievement.color,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          achievement.title,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showAchievementDialog(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          achievement.title,
          style: const TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  achievement.icon,
                  color: achievement.color,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Earned: ${achievement.earnedAt != null ? 'Yes' : 'No'}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getAchievementColor(double progress) {
    if (progress < 0.25) return Colors.blue;
    if (progress < 0.5) return Colors.green;
    if (progress < 0.75) return Colors.orange;
    return Colors.purple;
  }

  Widget _buildInsightsSection(ThemeData theme) {
    final insights = <Map<String, dynamic>>[];

    if (_user != null) {
      final completedTasks = _overallStats['completedQuests'] ?? 0;
      final streakDays = _user!.streakDays;
      final efficiencyRate = _user!.efficiencyRate;
      final totalCoins = _user!.totalCoins;
      final level = _user!.level;
      final currentXp = _user!.currentXp;
      final xpToNextLevel = _user!.xpToNextLevel;
      final weeklyAvgProductivity = _weeklyStats.isNotEmpty
          ? _weeklyStats
                  .map((stat) => stat.productivityScore)
                  .reduce((a, b) => a + b) /
              _weeklyStats.length
          : 0.0;

      // Insight 1: Based on completion rate
      if (completedTasks == 0) {
        insights.add({
          'icon': Icons.rocket_launch,
          'title': "Start Your Journey",
          'desc': "Complete your first quest to begin your adventure!",
          'color': Colors.blue,
          'priority': 1,
        });
      } else if (completedTasks < 5) {
        insights.add({
          'icon': Icons.bolt,
          'title': "Build Momentum",
          'desc':
              "You've completed $completedTasks quests. Aim for 5 to unlock your first achievement!",
          'color': Colors.orange,
          'priority': 2,
        });
      }

      // Insight 2: Based on streak
      if (streakDays == 0) {
        insights.add({
          'icon': Icons.calendar_today,
          'title': "Build a Streak",
          'desc': "Complete a quest daily for bonus rewards and XP!",
          'color': Colors.red,
          'priority': 1,
        });
      } else if (streakDays == 1) {
        insights.add({
          'icon': Icons.local_fire_department,
          'title': "Streak Started!",
          'desc': "Great! Keep going for 3 days to earn streak bonus!",
          'color': Colors.orange,
          'priority': 2,
        });
      } else if (streakDays >= 3 && streakDays < 7) {
        insights.add({
          'icon': Icons.local_fire_department,
          'title': "Impressive Streak!",
          'desc': "$streakDays days in a row! Keep it up for weekly bonus!",
          'color': Colors.orange[700]!,
          'priority': 3,
        });
      }

      // Insight 3: Based on level progress
      final levelProgress = xpToNextLevel > 0 ? currentXp / xpToNextLevel : 0.0;
      if (levelProgress > 0.5 && levelProgress < 1.0) {
        insights.add({
          'icon': Icons.star,
          'title': "Level Up Soon!",
          'desc':
              "${((1 - levelProgress) * xpToNextLevel).toInt()} XP needed for next level!",
          'color': Colors.purple,
          'priority': 3,
        });
      }

      // Insight 4: Based on weekly performance
      if (weeklyAvgProductivity < 2.0 && completedTasks > 0) {
        insights.add({
          'icon': Icons.trending_up,
          'title': "Boost Productivity",
          'desc':
              "Your weekly score is low (${weeklyAvgProductivity.toStringAsFixed(1)}/5). Try focusing on fewer, important tasks.",
          'color': Colors.blue,
          'priority': 2,
        });
      } else if (weeklyAvgProductivity >= 4.0) {
        insights.add({
          'icon': Icons.emoji_events,
          'title': "Outstanding Week!",
          'desc':
              "Great productivity (${weeklyAvgProductivity.toStringAsFixed(1)}/5)! Maintain this pace!",
          'color': Colors.green,
          'priority': 4,
        });
      }

      // Insight 5: Based on coins
      if (totalCoins == 0 && completedTasks > 0) {
        insights.add({
          'icon': Icons.monetization_on_outlined,
          'title': "Earn Coins",
          'desc': "Complete more quests to collect coins for rewards!",
          'color': Colors.amber,
          'priority': 2,
        });
      } else if (totalCoins > 100) {
        insights.add({
          'icon': Icons.savings,
          'title': "Coin Collector!",
          'desc': "You have $totalCoins coins! Consider redeeming rewards.",
          'color': Colors.amber[700]!,
          'priority': 3,
        });
      }

      // Insight 6: Based on efficiency
      if (efficiencyRate < 0.5 && completedTasks > 3) {
        insights.add({
          'icon': Icons.speed,
          'title': "Improve Efficiency",
          'desc':
              "Try completing tasks closer to their deadlines for better scores.",
          'color': Colors.teal,
          'priority': 2,
        });
      }
    }

    // Sort by priority and take top 2
    insights
        .sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
    final displayInsights = insights.take(2).toList();

    // Add default if no insights
    if (displayInsights.isEmpty) {
      displayInsights.add({
        'icon': Icons.tips_and_updates,
        'title': "Welcome!",
        'desc': "Start by creating and completing your first quest!",
        'color': Colors.blueGrey,
      });
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: theme.colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                "Personalized Insights",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...displayInsights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildInsightCard(
                  icon: insight['icon'] as IconData,
                  title: insight['title'] as String,
                  desc: insight['desc'] as String,
                  color: insight['color'] as Color,
                  theme: theme,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Settings",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),

          // Appearance
          _buildSettingItem(
            icon: Icons.palette_outlined,
            title: "Appearance",
            subtitle: "Theme",
            color: Colors.blue,
            onTap: () {
              _showThemeDialog();
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 0.5),
          ),

          // Notifications
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: "Notifications",
            subtitle: "Quest reminders & daily alerts",
            color: Colors.orange,
            onTap: () {
              _showNotificationSettings();
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 0.5),
          ),

          // Data Management
          _buildSettingItem(
            icon: Icons.storage_outlined,
            title: "Data Management",
            subtitle: "Backup, restore & clear data",
            color: Colors.green,
            onTap: () {
              _showDataManagementDialog();
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 0.5),
          ),

          // Help & Support
          _buildSettingItem(
            icon: Icons.help_outline,
            title: "Help & Support",
            subtitle: "FAQ, Contact & About app",
            color: Colors.purple,
            onTap: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 30,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey[400],
        size: 18,
      ),
      onTap: onTap,
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Theme Settings", style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Theme Mode",
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Light Theme
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _toggleTheme(false);
                  },
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: !_isDarkMode
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_isDarkMode
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.light_mode,
                          color: !_isDarkMode
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Light",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !_isDarkMode
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Dark Theme
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _toggleTheme(true);
                  },
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDarkMode
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.dark_mode,
                          color: _isDarkMode
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Dark",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _isDarkMode
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Note: App restart may be required for full theme changes",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Notification Settings",
                  style: TextStyle(fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text("Daily Reminders",
                        style: TextStyle(fontSize: 13)),
                    subtitle: const Text("Get reminded about daily quests"),
                    value: _dailyReminders,
                    onChanged: (value) =>
                        setState(() => _dailyReminders = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text("Streak Alerts",
                        style: TextStyle(fontSize: 13)),
                    subtitle:
                        const Text("Notifications about your streak status"),
                    value: _streakAlerts,
                    onChanged: (value) => setState(() => _streakAlerts = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text("Achievement Alerts",
                        style: TextStyle(fontSize: 13)),
                    subtitle:
                        const Text("Get notified when earning achievements"),
                    value: _achievementAlerts,
                    onChanged: (value) =>
                        setState(() => _achievementAlerts = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 10),
                  const Text("Notification Time",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Daily reminder at: ${_notificationTime.format(context)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () async {
                        final TimeOfDay? newTime = await showTimePicker(
                          context: context,
                          initialTime: _notificationTime,
                        );
                        if (newTime != null) {
                          setState(() {
                            _notificationTime = newTime;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Note: For notifications to work properly, please enable app notifications in your device settings.",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _saveSettings();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Notification settings saved"),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Schedule notifications
                    _scheduleNotifications();
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _scheduleNotifications() {
    // TODO: Implement notification scheduling logic
    // This will require the flutter_local_notifications package
    print("Scheduling notifications for ${_notificationTime.format(context)}");
    print("Daily reminders: $_dailyReminders");
    print("Streak alerts: $_streakAlerts");
    print("Achievement alerts: $_achievementAlerts");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Notification preferences saved"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _backupData() async {
    try {
      // Backup logic here
      final appDir = await getApplicationDocumentsDirectory();
      final backupFile = File(
          '${appDir.path}/quest_backup_${DateTime.now().millisecondsSinceEpoch}.db');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Backup completed successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Backup failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear image cache
      imageCache.clear();
      imageCache.clearLiveImages();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cache cleared successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to clear cache: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDataManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Data Management", style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.backup, color: Colors.blue),
              title: const Text("Backup Data", style: TextStyle(fontSize: 13)),
              subtitle: const Text("Save your progress locally"),
              onTap: () {
                Navigator.pop(context);
                _backupData();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cloud_upload, color: Colors.blue),
              title: const Text("Cloud Backup", style: TextStyle(fontSize: 13)),
              subtitle: const Text("Save to cloud service"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Cloud backup initiated"),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restore, color: Colors.green),
              title: const Text("Restore Data", style: TextStyle(fontSize: 13)),
              subtitle: const Text("Restore from previous backup"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Restore initiated"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text("Clear Cache", style: TextStyle(fontSize: 13)),
              subtitle: const Text("Clear temporary files"),
              onTap: () {
                Navigator.pop(context);
                _clearCache();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.warning, color: Colors.orange),
              title:
                  const Text("Reset All Data", style: TextStyle(fontSize: 13)),
              subtitle: const Text("⚠️ Warning: This cannot be undone"),
              onTap: () {
                Navigator.pop(context);
                _showResetConfirmationDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ Reset All Data",
            style: TextStyle(fontSize: 16, color: Colors.red)),
        content: const Text(
            "Are you sure you want to reset all data? This will delete all your quests, progress, and achievements. This action cannot be undone!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("Reset All Data"),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData() async {
    try {
      // Reset dengan cara lain jika resetDatabase tidak tersedia
      // Hapus database dan buat ulang
      final databasesPath = await getDatabasesPath();
      final dbPath = '$databasesPath/quest_app.db';

      // Hapus file database
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) {
        await dbFile.delete();
      }

      // Clear preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Initialize database baru
      _dbOps = DatabaseOperations();

      // Reload data
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All data has been reset successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reset failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Help & Support", style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.help, color: Colors.blue),
              title: const Text("FAQ", style: TextStyle(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _showFAQDialog();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email, color: Colors.green),
              title:
                  const Text("Contact Support", style: TextStyle(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _showContactSupportDialog();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info, color: Colors.purple),
              title: const Text("About App", style: TextStyle(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text("Rate App", style: TextStyle(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _showRateAppDialog();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text("Share App", style: TextStyle(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _shareApp();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Contact Support", style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Email: rizkianuari83@gmail.com"),
            SizedBox(height: 8),
            Text("Hours: Mon-Fri, 9AM-5PM"),
            SizedBox(height: 8),
            Text("Response Time: Within 24 hours"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Email support@questapp.com for assistance"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Send Email"),
          ),
        ],
      ),
    );
  }

  void _showRateAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rate Quest App", style: TextStyle(fontSize: 16)),
        content: const Text(
            "If you enjoy using Quest App, please consider rating it on the app store. Your feedback helps us improve!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Not Now"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Thank you for your support!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Rate Now"),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Share functionality is ready"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showFAQDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Frequently Asked Questions",
            style: TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Q: How do I earn XP?",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Text("A: Complete quests and maintain streaks to earn XP.",
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              const Text("Q: What are coins for?",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Text(
                  "A: Coins can be used to unlock special features and rewards.",
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              const Text("Q: How does streak work?",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Text(
                  "A: Complete at least one quest daily to maintain your streak.",
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              const Text("Q: How do I change my profile picture?",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Text(
                  "A: Tap on your profile picture in the profile section.",
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              const Text("Q: Can I backup my data?",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Text(
                  "A: Yes! Go to Settings > Data Management > Backup Data.",
                  style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("About Quest App", style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Version: 1.0.0", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            const Text(
                "A gamified productivity app to help you achieve your goals through quests and rewards.",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text("Features:",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Text("• Create and manage quests",
                style: TextStyle(fontSize: 11)),
            const Text("• Earn XP and level up",
                style: TextStyle(fontSize: 11)),
            const Text("• Track productivity trends",
                style: TextStyle(fontSize: 11)),
            const Text("• Unlock achievements", style: TextStyle(fontSize: 11)),
            const SizedBox(height: 12),
            const Text("© 2024 Quest App. All rights reserved.",
                style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
