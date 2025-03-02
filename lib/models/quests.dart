import 'package:flutter/foundation.dart';

enum QuestDifficulty { easy, medium, hard, epic }

extension QuestDifficultyExtension on QuestDifficulty {
  String get name {
    return describeEnum(this);
  }

  static QuestDifficulty fromString(dynamic value) {
    if (value == null) return QuestDifficulty.medium;

    // Handle both String and QuestDifficulty inputs
    if (value is QuestDifficulty) return value;

    // Convert to lowercase string and match
    final stringValue = value.toString().toLowerCase();
    return QuestDifficulty.values.firstWhere(
          (e) => describeEnum(e).toLowerCase() == stringValue,
      orElse: () => QuestDifficulty.medium,
    );
  }
}

enum QuestStatus { active, completed, failed, archived }

extension QuestStatusExtension on QuestStatus {
  String get name {
    return describeEnum(this);
  }

  static QuestStatus fromString(dynamic value) {
    if (value == null) return QuestStatus.active;

    // Handle both String and QuestStatus inputs
    if (value is QuestStatus) return value;

    // Convert to lowercase string and match
    final stringValue = value.toString().toLowerCase();
    return QuestStatus.values.firstWhere(
          (e) => describeEnum(e).toLowerCase() == stringValue,
      orElse: () => QuestStatus.active,
    );
  }
}

class Quest {
  final String id;
  final String userId;
  final String title;
  final String description;
  final QuestDifficulty difficulty;
  final int experiencePoints;
  final QuestStatus status;
  final List<String> steps;
  final List<int> completedSteps;
  final DateTime createdAt;
  final DateTime dueDate;
  final DateTime? completedAt;

  Quest({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.experiencePoints,
    required this.status,
    required this.steps,
    required this.completedSteps,
    required this.createdAt,
    required this.dueDate,
    this.completedAt,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] ?? DateTime.now().toIso8601String(),
      userId: json['user_id'] ?? 'default_user',
      title: json['title'],
      description: json['description'],
      // Robust conversion of difficulty
      difficulty: json['difficulty'] is QuestDifficulty
          ? json['difficulty']
          : QuestDifficultyExtension.fromString(json['difficulty'] ?? 'medium'),
      experiencePoints: json['experience_points'] ?? 0,
      // Robust conversion of status
      status: QuestStatusExtension.fromString(json['status'] ?? QuestStatus.active),
      steps: List<String>.from(json['steps'] ?? []),
      completedSteps: List<int>.from(json['completed_steps'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : DateTime.now().add(Duration(days: 7)),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'difficulty': difficulty.name, // Store as string
      'experience_points': experiencePoints,
      'status': status.name, // Store as string
      'steps': steps,
      'completed_steps': completedSteps,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Quest copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    QuestDifficulty? difficulty,
    int? experiencePoints,
    QuestStatus? status,
    List<String>? steps,
    List<int>? completedSteps,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
  }) {
    return Quest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      status: status ?? this.status,
      steps: steps ?? this.steps,
      completedSteps: completedSteps ?? this.completedSteps,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

// Extension for additional computed properties
extension QuestExtension on Quest {
  bool get isOverdue {
    return status == QuestStatus.active &&
        DateTime.now().isAfter(dueDate);
  }

  double get progress {
    if (steps.isEmpty) return 0.0;
    if (completedSteps.length == steps.length) return 1.0;
    return completedSteps.length / steps.length;
  }

  bool canCompleteStep(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= steps.length) return false;
    return !completedSteps.contains(stepIndex);
  }
}