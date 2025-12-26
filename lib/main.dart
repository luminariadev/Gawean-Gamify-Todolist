import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'navigation/main_navbar.dart';
import 'pages/calendar_page.dart';

void main() => runApp(const Gawean());

class Gawean extends StatelessWidget {
  const Gawean({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskifyQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      home: const MainNavbar(),

      routes: {'/calendar': (context) => const CalendarPage()},
    );
  }
}
