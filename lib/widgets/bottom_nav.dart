import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../pages/home_page.dart';
import '../pages/calendar_page.dart';
import '../pages/profile_page.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _index = 0;

  final List<Widget> _pages = const [HomePage(), CalendarPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _pages[_index],
      ),
      bottomNavigationBar: NavigationBar(
        height: 65,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(FeatherIcons.home),
            selectedIcon: Icon(FeatherIcons.home, color: Colors.indigo),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(FeatherIcons.calendar),
            selectedIcon: Icon(FeatherIcons.calendar, color: Colors.indigo),
            label: "Calendar",
          ),
          NavigationDestination(
            icon: Icon(FeatherIcons.user),
            selectedIcon: Icon(FeatherIcons.user, color: Colors.indigo),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
