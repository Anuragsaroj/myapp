import 'package:flutter/material.dart';

class Badge {
  final String name;
  final String description;
  final IconData icon;
  final bool isEarned;
  final String unlockCriteria;
  final int progress;
  final int goal;

  Badge({
    required this.name,
    required this.description,
    required this.icon,
    this.isEarned = false,
    required this.unlockCriteria,
    required this.progress,
    required this.goal,
  });
}
