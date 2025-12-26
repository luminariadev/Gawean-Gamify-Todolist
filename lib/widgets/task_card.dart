import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final int index;
  const TaskCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.tealAccent.withOpacity(0.2),
            Colors.tealAccent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(Icons.task, color: Colors.tealAccent.shade100),
        title: Text(
          'Tugas ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Deskripsi singkat tugas ini.'),
        trailing: const Icon(Icons.check_circle_outline),
        onTap: () {},
      ),
    );
  }
}
