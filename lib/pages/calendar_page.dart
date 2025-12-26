import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../database/database_operations.dart';
import '../models/quest.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with TickerProviderStateMixin {
  late final ValueNotifier<List<Quest>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late DatabaseOperations _dbOps;
  Map<DateTime, List<Quest>> _events = {};
  bool _isLoading = true;

  List<Quest> _getEventsForDay(DateTime day) {
    // Normalize the date to remove time component
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  Future<void> _loadEvents() async {
    try {
      final allQuests = await _dbOps.getAllQuests();

      // Group quests by date
      final Map<DateTime, List<Quest>> groupedEvents = {};

      for (var quest in allQuests) {
        // Normalize quest date to remove time component for grouping
        final questDate =
            DateTime.utc(quest.date.year, quest.date.month, quest.date.day);

        if (groupedEvents.containsKey(questDate)) {
          groupedEvents[questDate]!.add(quest);
        } else {
          groupedEvents[questDate] = [quest];
        }
      }

      // Sort quests within each date by priority (Urgent → High → Medium → Low)
      for (var date in groupedEvents.keys) {
        groupedEvents[date]!.sort((a, b) {
          final priorityOrder = {
            'Urgent': 4,
            'High': 3,
            'Medium': 2,
            'Low': 1,
          };
          final aPriority = priorityOrder[a.priority] ?? 0;
          final bPriority = priorityOrder[b.priority] ?? 0;
          return bPriority.compareTo(aPriority); // Descending order
        });
      }

      setState(() {
        _events = groupedEvents;
        _selectedEvents.value = _getEventsForDay(_selectedDay ?? _focusedDay);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading calendar events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.amber;
      case 'Low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Work':
        return FeatherIcons.briefcase;
      case 'Study':
        return FeatherIcons.book;
      case 'Personal':
        return FeatherIcons.heart;
      case 'Health':
        return FeatherIcons.activity;
      case 'Finance':
        return FeatherIcons.dollarSign;
      default:
        return FeatherIcons.flag;
    }
  }

  @override
  void initState() {
    super.initState();
    _dbOps = DatabaseOperations();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _fadeController.forward();
    _scaleController.forward();

    _loadEvents();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _selectedEvents.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;

      // Reset animations
      _fadeController.reset();
      _scaleController.reset();

      // Update events
      _selectedEvents.value = _getEventsForDay(selectedDay);

      // Restart animations
      _fadeController.forward();
      _scaleController.forward();
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  // Function to calculate responsive height for calendar
  double _getCalendarHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (screenHeight < 600) {
      // Very small screens (Pixel 3a portrait: 592px)
      return 320;
    } else if (screenHeight < 700) {
      // Small screens
      return 340;
    } else if (screenHeight < 800) {
      // Medium screens
      return 360;
    } else {
      // Large screens
      return 380;
    }
  }

  // Function to calculate responsive font sizes
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 360; // Base width for Pixel 3a
    return baseSize * scale.clamp(0.8, 1.2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? theme.colorScheme.surface : theme.colorScheme.background,
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
      backgroundColor:
          isDark ? theme.colorScheme.surface : theme.colorScheme.background,
      appBar: AppBar(
        title: const Text("Calendar"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // 🗓️ Animated Calendar Card dengan height yang responsive
            Container(
              height: _getCalendarHeight(context),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar<Quest>(
                  focusedDay: _focusedDay,
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getEventsForDay,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    leftChevronIcon: Container(
                      width: screenWidth < 360 ? 32 : 36,
                      height: screenWidth < 360 ? 32 : 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        FeatherIcons.chevronLeft,
                        color: theme.colorScheme.primary,
                        size: screenWidth < 360 ? 16 : 18,
                      ),
                    ),
                    rightChevronIcon: Container(
                      width: screenWidth < 360 ? 32 : 36,
                      height: screenWidth < 360 ? 32 : 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        FeatherIcons.chevronRight,
                        color: theme.colorScheme.primary,
                        size: screenWidth < 360 ? 16 : 18,
                      ),
                    ),
                    headerPadding: EdgeInsets.symmetric(
                      vertical: screenHeight < 600 ? 12 : 16,
                    ),
                    headerMargin: const EdgeInsets.only(bottom: 4),
                    leftChevronPadding: EdgeInsets.zero,
                    rightChevronPadding: EdgeInsets.zero,
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: _getResponsiveFontSize(context, 12),
                    ),
                    weekendStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary.withOpacity(0.8),
                      fontSize: _getResponsiveFontSize(context, 12),
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                      fontSize: _getResponsiveFontSize(context, 14),
                    ),
                    weekendTextStyle: TextStyle(
                      color: theme.colorScheme.primary.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: _getResponsiveFontSize(context, 14),
                    ),
                    outsideTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                      fontSize: _getResponsiveFontSize(context, 14),
                    ),
                    todayTextStyle: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: _getResponsiveFontSize(context, 14),
                    ),
                    selectedTextStyle: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: _getResponsiveFontSize(context, 14),
                    ),
                    todayDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    markerDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerSize: screenWidth < 360 ? 4 : 5,
                    markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                    markersAlignment: Alignment.bottomCenter,
                    markersMaxCount: 2,
                    cellPadding: EdgeInsets.all(screenWidth < 360 ? 2 : 4),
                    tablePadding: EdgeInsets.symmetric(
                      horizontal: screenWidth < 360 ? 8 : 12,
                    ),
                  ),
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() => _calendarFormat = format);
                    }
                  },
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                  },
                ),
              ),
            ),

            // 📅 Selected Date Card dengan padding yang responsive
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 360 ? 12 : 16,
                vertical: screenHeight < 600 ? 4 : 8,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDay?.day.toString() ?? '',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 28),
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          _selectedDay != null
                              ? '${_getMonthName(_selectedDay!.month)} ${_selectedDay!.year}'
                              : '',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                            fontSize: _getResponsiveFontSize(context, 12),
                          ),
                        ),
                      ],
                    ),
                    ValueListenableBuilder<List<Quest>>(
                      valueListenable: _selectedEvents,
                      builder: (context, events, _) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth < 360 ? 8 : 12,
                            vertical: screenWidth < 360 ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${events.length} ${events.length == 1 ? 'Quest' : 'Quests'}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: _getResponsiveFontSize(context, 10),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 📋 Animated Event List dengan flexible height
            Expanded(
              child: ValueListenableBuilder<List<Quest>>(
                valueListenable: _selectedEvents,
                builder: (context, quests, _) {
                  if (quests.isEmpty) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Center(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: screenWidth < 360 ? 60 : 80,
                                    height: screenWidth < 360 ? 60 : 80,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      FeatherIcons.calendar,
                                      size: screenWidth < 360 ? 24 : 32,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  SizedBox(
                                      height: screenHeight < 600 ? 12 : 20),
                                  Text(
                                    "No quests for this day",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize:
                                          _getResponsiveFontSize(context, 14),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Add quests from the home page",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize:
                                          _getResponsiveFontSize(context, 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth < 360 ? 12 : 16,
                      vertical: 8,
                    ),
                    itemCount: quests.length,
                    itemBuilder: (context, index) {
                      final quest = quests[index];
                      final priorityColor = _getPriorityColor(quest.priority);
                      final categoryIcon = _getCategoryIcon(quest.category);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.1 : 0.04,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    _showQuestDetailsDialog(quest, context);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                        screenWidth < 360 ? 12 : 16),
                                    child: Row(
                                      children: [
                                        // Color indicator based on priority
                                        Container(
                                          width: 3,
                                          height: screenWidth < 360 ? 32 : 40,
                                          decoration: BoxDecoration(
                                            color: priorityColor,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        SizedBox(
                                            width: screenWidth < 360 ? 12 : 16),
                                        // Quest icon based on category
                                        Container(
                                          width: screenWidth < 360 ? 32 : 40,
                                          height: screenWidth < 360 ? 32 : 40,
                                          decoration: BoxDecoration(
                                            color:
                                                priorityColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            categoryIcon,
                                            color: priorityColor,
                                            size: screenWidth < 360 ? 14 : 18,
                                          ),
                                        ),
                                        SizedBox(
                                            width: screenWidth < 360 ? 8 : 12),
                                        // Quest details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      quest.title,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize:
                                                            _getResponsiveFontSize(
                                                                context, 13),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: priorityColor
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      quest.priority,
                                                      style: TextStyle(
                                                        fontSize:
                                                            _getResponsiveFontSize(
                                                                context, 9),
                                                        color: priorityColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                quest.description.isNotEmpty
                                                    ? quest.description
                                                    : "No description",
                                                style: TextStyle(
                                                  fontSize:
                                                      _getResponsiveFontSize(
                                                          context, 11),
                                                  color: Colors.grey[600],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                maxLines: 1,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    FeatherIcons.clock,
                                                    size: screenWidth < 360
                                                        ? 10
                                                        : 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatTime(quest.time),
                                                    style: TextStyle(
                                                      fontSize:
                                                          _getResponsiveFontSize(
                                                              context, 10),
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Icon(
                                                    FeatherIcons.tag,
                                                    size: screenWidth < 360
                                                        ? 10
                                                        : 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    quest.category,
                                                    style: TextStyle(
                                                      fontSize:
                                                          _getResponsiveFontSize(
                                                              context, 10),
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestDetailsDialog(Quest quest, BuildContext context) {
    final priorityColor = _getPriorityColor(quest.priority);
    final categoryIcon = _getCategoryIcon(quest.category);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: priorityColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quest.category,
                          style: TextStyle(
                            fontSize: 13,
                            color: priorityColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                "Description",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                quest.description.isNotEmpty
                    ? quest.description
                    : "No description provided",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 20),

              // Details
              Row(
                children: [
                  Icon(
                    FeatherIcons.calendar,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${quest.date.day}/${quest.date.month}/${quest.date.year}",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    FeatherIcons.clock,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(quest.time),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      quest.priority,
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Progress",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: quest.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(priorityColor),
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${(quest.progress * 100).toInt()}% completed",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
