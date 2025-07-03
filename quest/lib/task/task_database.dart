/// Task Database - SQLite database management for Quest Task Management System
/// This file handles all database operations for tasks including CRUD operations,
/// progress tracking, and advanced queries for task management features

import 'package:sqflite/sqflite.dart';
import 'task_model.dart';

/// Static class providing database access and operations for tasks
/// Uses SQLite for local storage with automatic schema migrations
class TaskDatabase {
  // Private static database instance (singleton pattern)
  static Database? _db;

  /// Gets the database instance, creating it if it doesn't exist
  /// Implements singleton pattern for database connection management
  /// Handles database creation and schema migrations automatically
  static Future<Database> get database async {
    // Return existing database if already initialized
    if (_db != null) return _db!;

    // Create new database with schema and migration handling
    _db = await openDatabase(
      'task.db', // Database file name
      version: 3, // Current schema version - increment for migrations
      // Called when database is created for the first time
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            status TEXT DEFAULT 'inProgress',
            category TEXT DEFAULT 'other',
            createdAt INTEGER NOT NULL,
            goalDays INTEGER DEFAULT 30,
            currentProgress INTEGER DEFAULT 0,
            lastProgressDate INTEGER,
            streak INTEGER DEFAULT 0
          )
        ''');
      },

      // Called when database version is upgraded
      // Handles schema migrations for backward compatibility
      onUpgrade: (db, oldVersion, newVersion) {
        // Migration from version 1 to 2: Add status and createdAt columns
        if (oldVersion < 2) {
          db.execute(
            'ALTER TABLE tasks ADD COLUMN status TEXT DEFAULT "inProgress"',
          );
          db.execute(
            'ALTER TABLE tasks ADD COLUMN createdAt INTEGER DEFAULT 0',
          );
        }
        // Migration from version 2 to 3: Add category and progress tracking columns
        if (oldVersion < 3) {
          db.execute(
            'ALTER TABLE tasks ADD COLUMN category TEXT DEFAULT "other"',
          );
          db.execute(
            'ALTER TABLE tasks ADD COLUMN goalDays INTEGER DEFAULT 30',
          );
          db.execute(
            'ALTER TABLE tasks ADD COLUMN currentProgress INTEGER DEFAULT 0',
          );
          db.execute('ALTER TABLE tasks ADD COLUMN lastProgressDate INTEGER');
          db.execute('ALTER TABLE tasks ADD COLUMN streak INTEGER DEFAULT 0');
        }
      },
    );
    return _db!;
  }

  /// Inserts a new task into the database
  /// Uses REPLACE conflict algorithm to handle potential ID conflicts
  static Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all tasks from database ordered by creation date (newest first)
  /// Returns a list of Task objects converted from database maps
  static Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'createdAt DESC', // Sort by newest first
    );
    // Convert database maps to Task objects
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  /// Retrieves tasks filtered by status (in progress or completed)
  /// Used to separate active tasks from completed ones in the UI
  static Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'status = ?',
      whereArgs: [status.name], // Use enum name for filtering
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  /// Updates only the status of a specific task
  /// Used for marking tasks as completed or moving them back to in progress
  static Future<void> updateTaskStatus(int taskId, TaskStatus status) async {
    final db = await database;
    await db.update(
      'tasks',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Permanently deletes a task from the database
  /// Cannot be undone - consider soft delete for production use
  static Future<void> deleteTask(int taskId) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  /// Updates all fields of an existing task
  /// Used when editing task details like title, description, category, etc.
  static Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Retrieves a single task by its ID
  /// Returns null if task is not found
  /// Used for fetching specific task details
  static Future<Task?> getTaskById(int taskId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  /// Updates task progress for daily tracking
  /// Implements streak logic and prevents multiple updates per day
  /// This is the core method for habit tracking functionality
  static Future<void> updateTaskProgress(int taskId) async {
    final db = await database;
    final task = await getTaskById(taskId);
    if (task == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Prevent multiple progress updates in the same day
    if (task.progressUpdatedToday) {
      return; // Don't update twice in one day
    }

    // Increment progress counter
    int newProgress = task.currentProgress + 1;
    int newStreak = task.streak;

    // Calculate streak based on consecutive daily progress
    if (task.lastProgressDate != null) {
      final lastUpdate = DateTime(
        task.lastProgressDate!.year,
        task.lastProgressDate!.month,
        task.lastProgressDate!.day,
      );
      final daysDifference = today.difference(lastUpdate).inDays;

      if (daysDifference == 1) {
        // Consecutive day - increase streak
        newStreak = task.streak + 1;
      } else if (daysDifference > 1) {
        // Gap in progress - reset streak to 1
        newStreak = 1;
      }
    } else {
      // First progress update - start streak
      newStreak = 1;
    }

    // Update database with new progress values
    await db.update(
      'tasks',
      {
        'currentProgress': newProgress,
        'lastProgressDate': now.millisecondsSinceEpoch,
        'streak': newStreak,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Retrieves tasks filtered by category
  /// Used for category-based task organization and filtering
  static Future<List<Task>> getTasksByCategory(TaskCategory category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'category = ?',
      whereArgs: [category.name],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  /// Gets active tasks that still have progress to be made
  /// Excludes completed tasks and tasks that have reached their goal
  /// Sorted by last progress date to prioritize recently updated tasks
  static Future<List<Task>> getActiveTasksWithProgress() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'status = ? AND currentProgress < goalDays',
      whereArgs: [TaskStatus.inProgress.name],
      orderBy: 'lastProgressDate DESC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  /// Gets all tasks that had progress updated today
  /// Used for daily progress tracking and analytics
  /// Helps users see what they accomplished today
  static Future<List<Task>> getTasksWithProgressToday() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'lastProgressDate >= ? AND lastProgressDate < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'lastProgressDate DESC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }
}
