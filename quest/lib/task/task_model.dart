/// Task Model - Data structure and enums for the Quest Task Management System
/// This file contains the core data models and business logic for tasks

/// Enumeration representing the current status of a task
/// Tasks can be either in progress or completed
enum TaskStatus { inProgress, completed }

/// Enumeration representing different categories of tasks
/// Used for organizing and filtering tasks by type
enum TaskCategory { health, fitness, study, work, personal, habits, other }

/// Core Task model class representing a single task/quest
/// Contains all properties and methods related to task management
class Task {
  // Primary identifier for the task (auto-generated by database)
  final int? id;

  // Main title/name of the task
  final String title;

  // Optional detailed description of the task
  final String description;

  // Current status of the task (in progress or completed)
  final TaskStatus status;

  // Category classification for task organization
  final TaskCategory category;

  // Timestamp when the task was created
  final DateTime createdAt;

  // Total number of days to complete the task (e.g., 30 days)
  final int goalDays;

  // Current progress count (e.g., 5 out of 30 days completed)
  final int currentProgress;

  // Last date when progress was updated
  final DateTime? lastProgressDate;

  // Current streak of consecutive days with progress
  final int streak;

  /// Constructor for creating a new Task instance
  /// [title] and [description] are required, other fields have defaults
  Task({
    this.id,
    required this.title,
    required this.description,
    this.status = TaskStatus.inProgress,
    this.category = TaskCategory.other,
    DateTime? createdAt,
    this.goalDays = 30,
    this.currentProgress = 0,
    this.lastProgressDate,
    this.streak = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculates progress percentage as a decimal between 0.0 and 1.0
  /// Returns the ratio of current progress to goal days
  double get progressPercentage =>
      goalDays > 0 ? currentProgress / goalDays : 0.0;

  /// Checks if progress was updated today
  /// Compares the last progress date with current date
  bool get progressUpdatedToday {
    if (lastProgressDate == null) return false;
    final today = DateTime.now();
    final lastUpdate = lastProgressDate!;
    return today.year == lastUpdate.year &&
        today.month == lastUpdate.month &&
        today.day == lastUpdate.day;
  }

  /// Returns human-readable display name for the task category
  /// Used in UI components to show category labels
  String get categoryDisplayName {
    switch (category) {
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.fitness:
        return 'Fitness';
      case TaskCategory.study:
        return 'Study';
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.habits:
        return 'Habits';
      case TaskCategory.other:
        return 'Other';
    }
  }

  /// Returns emoji icon representing the task category
  /// Used in UI for visual category identification
  String get categoryIcon {
    switch (category) {
      case TaskCategory.health:
        return '🏥';
      case TaskCategory.fitness:
        return '💪';
      case TaskCategory.study:
        return '📚';
      case TaskCategory.work:
        return '💼';
      case TaskCategory.personal:
        return '👤';
      case TaskCategory.habits:
        return '🔄';
      case TaskCategory.other:
        return '📝';
    }
  }

  /// Converts Task object to Map for database storage
  /// All DateTime objects are converted to milliseconds since epoch
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'category': category.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'goalDays': goalDays,
      'currentProgress': currentProgress,
      'lastProgressDate': lastProgressDate?.millisecondsSinceEpoch,
      'streak': streak,
    };
  }

  /// Factory constructor to create Task from database Map
  /// Converts Map data from database back to Task object
  /// Handles enum parsing and date conversion from milliseconds
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      // Parse status enum from string, default to inProgress if invalid
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.inProgress,
      ),
      // Parse category enum from string, default to other if invalid
      category: TaskCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TaskCategory.other,
      ),
      // Convert milliseconds back to DateTime
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      goalDays: map['goalDays'] ?? 30,
      currentProgress: map['currentProgress'] ?? 0,
      // Handle nullable lastProgressDate
      lastProgressDate:
          map['lastProgressDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastProgressDate'])
              : null,
      streak: map['streak'] ?? 0,
    );
  }

  /// Creates a copy of the current Task with updated fields
  /// Allows immutable updates by creating new instance with modified properties
  /// Only specified fields are updated, others retain original values
  Task copyWith({
    int? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskCategory? category,
    DateTime? createdAt,
    int? goalDays,
    int? currentProgress,
    DateTime? lastProgressDate,
    int? streak,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      goalDays: goalDays ?? this.goalDays,
      currentProgress: currentProgress ?? this.currentProgress,
      lastProgressDate: lastProgressDate ?? this.lastProgressDate,
      streak: streak ?? this.streak,
    );
  }
}
