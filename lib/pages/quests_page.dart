import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_operations.dart';
import '../models/user_profile.dart';
import '../models/treasure.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _treasureAnimation;
  late Animation<double> _waveAnimation;

  late DatabaseOperations _dbOps;
  UserProfile? _user;
  List<TreasureLevel> _treasures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dbOps = DatabaseOperations();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _treasureAnimation = Tween<double>(begin: 0, end: pi / 4).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _dbOps.getUserProfile();
      final treasures = await _dbOps.getAllTreasures();

      setState(() {
        _user = user;
        _treasures = treasures;
        _isLoading = false;

        // Update treasure unlock status based on completed tasks
        _updateTreasureStatus();
      });
    } catch (e) {
      print('Error loading quest data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateTreasureStatus() {
    if (_user == null) return;

    for (var treasure in _treasures) {
      final shouldBeUnlocked = _user!.tasksCompleted >= treasure.requiredTasks;

      // If treasure should be unlocked but isn't, unlock it
      if (shouldBeUnlocked && !treasure.isUnlocked) {
        _unlockTreasure(treasure.id);
      }
    }
  }

  Future<void> _unlockTreasure(int treasureId) async {
    try {
      await _dbOps.unlockTreasure(treasureId);
      await _loadData(); // Reload data to get updated status
    } catch (e) {
      print('Error unlocking treasure: $e');
    }
  }

  Future<void> _claimTreasure(TreasureLevel treasure) async {
    if (treasure.isClaimed) return;

    try {
      // Claim treasure in database
      await _dbOps.claimTreasure(treasure.id);

      // Add coins reward to user
      int coinsReward = 0;
      for (var reward in treasure.rewards) {
        if (reward.contains('Coins')) {
          final match = RegExp(r'\+(\d+)').firstMatch(reward);
          if (match != null) {
            coinsReward += int.parse(match.group(1)!);
          }
        }
      }

      if (coinsReward > 0) {
        await _dbOps.addUserCoins(coinsReward);
      }

      // Reload data
      await _loadData();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully claimed ${treasure.title}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to claim treasure: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF87CEEB),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[800]!, Colors.cyan[500]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue[900]!.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCoinCounter(),
                      _buildLevelBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Treasure Hunt",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Sail to discover hidden treasures!",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildProgressIndicator(),
                ],
              ),
            ),

            // Treasure Map
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  height: MediaQuery.of(context).size.height * 1.2,
                  padding: const EdgeInsets.all(24),
                  child: Stack(
                    children: [
                      // Ocean Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF87CEEB),
                              Colors.blue[300]!,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                      // Ocean Waves
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedBuilder(
                          animation: _waveAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: OceanWavesPainter(_waveAnimation.value),
                              size: Size(
                                MediaQuery.of(context).size.width,
                                120,
                              ),
                            );
                          },
                        ),
                      ),

                      // Treasure Path and Islands
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: TreasureMapPainter(
                              treasures: _treasures,
                              user: _user,
                            ),
                            size: Size(
                              MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.height * 1.2,
                            ),
                          );
                        },
                      ),

                      // Treasure Chests
                      ..._buildTreasureChests(),

                      // Ship
                      _buildShip(),

                      // Floating Coins
                      ..._buildFloatingCoins(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinCounter() {
    final coins = _user?.totalCoins ?? 0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        // Perbaikan di sini: Pakai variabel terpisah untuk kondisi
        final shouldPulse = (_user?.tasksCompleted ?? 0) >=
            (_treasures.isNotEmpty ? _treasures.last.requiredTasks : 0);

        return Transform.scale(
          scale: shouldPulse ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[600]!, Colors.amber[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber[800]!.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monetization_on, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  coins.toString(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelBadge() {
    final userLevel = _user?.level ?? 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        "Level $userLevel",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (_treasures.isEmpty || _user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Text(
            "Start your journey!",
            style: GoogleFonts.poppins(
              color: Colors.blueGrey[900],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // Cari treasure berikutnya yang belum terbuka
    TreasureLevel? nextTreasure;
    for (var treasure in _treasures) {
      if (!treasure.isUnlocked) {
        nextTreasure = treasure;
        break;
      }
    }

    // Jika semua treasure sudah terbuka, gunakan yang terakhir
    nextTreasure ??= _treasures.last;

    final progress = _user!.tasksCompleted / nextTreasure.requiredTasks;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Next: ${nextTreasure!.title}",
                    style: GoogleFonts.poppins(
                      color: Colors.blueGrey[900],
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "${_user!.tasksCompleted}/${nextTreasure.requiredTasks} Tasks",
                    style: GoogleFonts.poppins(
                      color: Colors.blueGrey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(nextTreasure.color),
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 12,
                  ),
                  Positioned(
                    left: (MediaQuery.of(context).size.width - 64) *
                            progress.clamp(0.0, 1.0) -
                        12,
                    top: -6,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: nextTreasure.color,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.card_giftcard,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${(progress * 100).toStringAsFixed(0)}% to next treasure",
                style: GoogleFonts.poppins(
                  color: Colors.blueGrey[700],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTreasureChests() {
    return _treasures.asMap().entries.map((entry) {
      final index = entry.key;
      final treasure = entry.value;
      final isUnlocked = treasure.isUnlocked;
      final isClaimed = treasure.isClaimed;
      final tasksCompleted = _user?.tasksCompleted ?? 0;

      return Positioned(
        left: MediaQuery.of(context).size.width * treasure.positionX - 30,
        top: MediaQuery.of(context).size.height * 1.2 * treasure.positionY - 30,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _showTreasureDialog(treasure);
          },
          child: AnimatedTreasureChest(
            treasure: treasure,
            animationController: _animationController,
            isUnlocked: isUnlocked,
            isClaimed: isClaimed,
            isNext: !isUnlocked &&
                (index == 0 ||
                    tasksCompleted >= _treasures[index - 1].requiredTasks),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildShip() {
    if (_treasures.isEmpty || _user == null) return const SizedBox();

    final currentTreasure = _treasures.lastWhere(
      (treasure) => _user!.tasksCompleted >= treasure.requiredTasks,
      orElse: () => _treasures.first,
    );

    final currentIndex = _treasures.indexOf(currentTreasure);
    final nextIndex = (currentIndex + 1).clamp(0, _treasures.length - 1);
    final currentTreasurePos = _treasures[currentIndex];
    final nextTreasurePos = _treasures[nextIndex];

    final progress = (_user!.tasksCompleted - currentTreasure.requiredTasks) /
        (nextTreasurePos.requiredTasks - currentTreasure.requiredTasks)
            .clamp(1, double.infinity);
    final t = progress.clamp(0.0, 1.0);

    final x = _lerp(currentTreasurePos.positionX, nextTreasurePos.positionX, t);
    final y = _lerp(currentTreasurePos.positionY, nextTreasurePos.positionY, t);

    return Positioned(
      left: MediaQuery.of(context).size.width * x - 25,
      top: MediaQuery.of(context).size.height * 1.2 * y - 50,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, sin(_animationController.value * pi) * 2),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown[700]!, Colors.brown[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown[900]!.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_boat,
                color: Colors.white,
                size: 30,
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFloatingCoins() {
    return List.generate(6, (index) {
      final random = Random(index);
      final x = random.nextDouble() * 0.8 + 0.1;
      final y = random.nextDouble() * 0.6 + 0.2;
      return Positioned(
        left: MediaQuery.of(context).size.width * x,
        top: MediaQuery.of(context).size.height * 1.2 * y,
        child: AnimatedBuilder(
          animation: _treasureAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset:
                  Offset(0, sin(_animationController.value * pi + index) * 5),
              child: Transform.rotate(
                angle: _treasureAnimation.value,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.amber[400]!, Colors.amber[600]!],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber[800]!.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  void _showTreasureDialog(TreasureLevel treasure) {
    final isUnlocked = treasure.isUnlocked;
    final isClaimed = treasure.isClaimed;
    final tasksCompleted = _user?.tasksCompleted ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 60,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _treasureAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: isUnlocked ? _pulseAnimation.value : 1.0,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        treasure.color,
                                        treasure.color.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: treasure.color.withOpacity(0.5),
                                        blurRadius: 15,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    treasure.icon,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  treasure.title,
                                  style: GoogleFonts.poppins(
                                    color: Colors.blueGrey[900],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "${treasure.requiredTasks} Tasks Required",
                                  style: GoogleFonts.poppins(
                                    color: treasure.color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        treasure.description,
                        style: GoogleFonts.poppins(
                          color: Colors.blueGrey[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!isUnlocked)
                        Text(
                          "Completed: $tasksCompleted/${treasure.requiredTasks} tasks",
                          style: GoogleFonts.poppins(
                            color: Colors.orange[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildRewardsSection(treasure, isUnlocked, isClaimed),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blueGrey[800],
                                side: BorderSide(color: Colors.blueGrey[300]!),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Close',
                                style: GoogleFonts.poppins(
                                  color: Colors.blueGrey[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (isUnlocked && !isClaimed) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _claimTreasure(treasure);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: treasure.color,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: Text(
                                  'Claim Treasure',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRewardsSection(
      TreasureLevel treasure, bool isUnlocked, bool isClaimed) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isUnlocked ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: treasure.color,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isClaimed ? "Treasure Claimed" : "Treasure Rewards",
                      style: GoogleFonts.poppins(
                        color: Colors.blueGrey[900],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!isUnlocked)
                  Text(
                    "Complete ${treasure.requiredTasks - (_user?.tasksCompleted ?? 0)} more tasks to unlock!",
                    style: GoogleFonts.poppins(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                if (isClaimed)
                  Text(
                    "You have already claimed this treasure!",
                    style: GoogleFonts.poppins(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                if (isUnlocked && !isClaimed)
                  ...treasure.rewards.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            AnimatedBuilder(
                              animation: _treasureAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green[400],
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.value,
                              style: GoogleFonts.poppins(
                                color: Colors.blueGrey[800],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedTreasureChest extends StatelessWidget {
  final TreasureLevel treasure;
  final AnimationController animationController;
  final bool isUnlocked;
  final bool isClaimed;
  final bool isNext;

  const AnimatedTreasureChest({
    super.key,
    required this.treasure,
    required this.animationController,
    this.isUnlocked = false,
    this.isClaimed = false,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final scale = isNext ? 1.0 + (animationController.value * 0.08) : 1.0;
        final glowOpacity =
            isNext ? 0.4 + (animationController.value * 0.2) : 0.2;

        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: treasure.color.withOpacity(glowOpacity),
                ),
              ),
              // Chest
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isUnlocked ? treasure.color : Colors.grey[400]!,
                      isUnlocked
                          ? treasure.color.withOpacity(0.8)
                          : Colors.grey[500]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: treasure.color.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  treasure.icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              // Lock/Star/Check
              if (!isUnlocked)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              if (isClaimed)
                Positioned(
                  top: -8,
                  left: -8,
                  child: AnimatedBuilder(
                    animation: animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: animationController.value * pi / 4,
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green[400],
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
              if (isUnlocked && !isClaimed)
                Positioned(
                  top: -8,
                  left: -8,
                  child: AnimatedBuilder(
                    animation: animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: animationController.value * pi / 4,
                        child: Icon(
                          Icons.star,
                          color: Colors.amber[400],
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class TreasureMapPainter extends CustomPainter {
  final List<TreasureLevel> treasures;
  final UserProfile? user;

  const TreasureMapPainter({
    required this.treasures,
    required this.user,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (treasures.isEmpty) return;

    final pathPaint = Paint()
      ..color = Colors.blue[200]!.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final completedPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.green[400]!, Colors.green[600]!],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final completedPath = Path();

    path.moveTo(
      size.width * treasures[0].positionX,
      size.height * treasures[0].positionY,
    );
    completedPath.moveTo(
      size.width * treasures[0].positionX,
      size.height * treasures[0].positionY,
    );

    final tasksCompleted = user?.tasksCompleted ?? 0;
    final currentTreasure = treasures.lastWhere(
      (treasure) => tasksCompleted >= treasure.requiredTasks,
      orElse: () => treasures.first,
    );
    final currentIndex = treasures.indexOf(currentTreasure);
    final nextIndex = (currentIndex + 1).clamp(0, treasures.length - 1);

    for (int i = 1; i < treasures.length; i++) {
      final current = treasures[i];
      final previous = treasures[i - 1];

      final controlX =
          size.width * (previous.positionX + current.positionX) / 2;
      final controlY =
          size.height * (previous.positionY + current.positionY) / 2;

      path.quadraticBezierTo(
        controlX,
        controlY,
        size.width * current.positionX,
        size.height * current.positionY,
      );

      if (i <= currentIndex) {
        completedPath.quadraticBezierTo(
          controlX,
          controlY,
          size.width * current.positionX,
          size.height * current.positionY,
        );
      } else if (i == currentIndex + 1) {
        final progress = (tasksCompleted - currentTreasure.requiredTasks) /
            (treasures[nextIndex].requiredTasks - currentTreasure.requiredTasks)
                .clamp(1, double.infinity);

        if (progress > 0) {
          final partialPath = Path();
          partialPath.moveTo(
            size.width * previous.positionX,
            size.height * previous.positionY,
          );
          partialPath.quadraticBezierTo(
            controlX,
            controlY,
            size.width *
                (previous.positionX +
                    (current.positionX - previous.positionX) * progress),
            size.height *
                (previous.positionY +
                    (current.positionY - previous.positionY) * progress),
          );
          completedPath.addPath(partialPath, Offset.zero);
        }
      }
    }

    canvas.drawPath(path, pathPaint);
    canvas.drawPath(completedPath, completedPaint);

    // Draw islands
    for (int i = 0; i < treasures.length; i++) {
      final treasure = treasures[i];
      final isUnlocked = tasksCompleted >= treasure.requiredTasks;

      final islandPaint = Paint()
        ..color = isUnlocked ? Colors.green[500]! : Colors.brown[500]!
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(
            size.width * treasure.positionX, size.height * treasure.positionY),
        30,
        islandPaint,
      );

      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width * treasure.positionX + 4,
            size.height * treasure.positionY + 4),
        30,
        shadowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TreasureMapPainter oldDelegate) {
    return oldDelegate.user?.tasksCompleted != user?.tasksCompleted ||
        oldDelegate.treasures != treasures;
  }
}

class OceanWavesPainter extends CustomPainter {
  final double waveOffset;

  const OceanWavesPainter(this.waveOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = Colors.blue[400]!.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.6);

    for (double i = 0; i < size.width; i += 20) {
      path.quadraticBezierTo(
        i + 10,
        size.height * (0.4 + sin(waveOffset + i / 100) * 0.1),
        i + 20,
        size.height * 0.6,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant OceanWavesPainter oldDelegate) =>
      oldDelegate.waveOffset != waveOffset;
}
