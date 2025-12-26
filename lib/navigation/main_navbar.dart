import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../pages/home_page.dart';
import '../pages/quests_page.dart';
import '../pages/profile_page.dart';

class MainNavbar extends StatefulWidget {
  const MainNavbar({super.key});

  @override
  State<MainNavbar> createState() => _MainNavbarState();
}

class _MainNavbarState extends State<MainNavbar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [HomePage(), QuestsPage(), ProfilePage()];
  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': FeatherIcons.home,
      'label': 'Home',
      'gradient': [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    },
    {
      'icon': FeatherIcons.checkSquare,
      'label': 'Quests',
      'gradient': [Color(0xFF10B981), Color(0xFF34D399)],
    },
    {
      'icon': FeatherIcons.user,
      'label': 'Profile',
      'gradient': [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        height: 75, // Sedikit lebih tinggi untuk aman
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF1F2937) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _navItems.length,
              (index) => _buildNavItem(index, isDarkMode),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDarkMode) {
    final isSelected = _selectedIndex == index;
    final item = _navItems[index];
    final icon = item['icon'] as IconData;
    final label = item['label'] as String;
    final gradient = item['gradient'] as List<Color>;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        constraints: BoxConstraints(
          minWidth: 64,
          maxWidth: 80,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon dengan Stack untuk badge
            SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[100],
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : Colors.transparent,
                        width: isSelected ? 1.5 : 0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: gradient.first.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                    ),
                  ),

                  // Badge untuk quests
                  if (index == 1 && !isSelected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.yellow],
                          ),
                          border: Border.all(
                            color:
                                isDarkMode ? Color(0xFF1F2937) : Colors.white,
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                  // Badge untuk profile
                  if (index == 2 && !isSelected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.purple,
                          border: Border.all(
                            color:
                                isDarkMode ? Color(0xFF1F2937) : Colors.white,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Label
            SizedBox(
              height: 16, // Fixed height untuk text
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? gradient.first
                        : isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Active indicator
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gradient.first,
                ),
              )
            else
              const SizedBox(height: 4), // Spacer konsisten
          ],
        ),
      ),
    );
  }
}
