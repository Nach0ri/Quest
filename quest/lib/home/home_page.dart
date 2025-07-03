/// Home Page - Main dashboard for the Quest Task Management Application
/// This file contains the home screen UI showing task progress, completed tasks,
/// and navigation to other sections of the app

import 'package:flutter/material.dart';
import '../task/task_screen.dart';
import '../task/task_model.dart';
import '../task/task_database.dart';

/// Home page widget serving as the main dashboard
/// Displays task progression, completed tasks, and app navigation
class HomePage extends StatefulWidget {
  /// Constructor for HomePage widget
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State class for HomePage containing all logic and UI management
class _HomePageState extends State<HomePage> {
  // UI state variables for expandable sections
  bool isTaskProgressionExpanded =
      true; // Controls Task Progression section visibility
  bool isTaskCompletedExpanded =
      true; // Controls Task Completed section visibility

  // Data lists for different task states
  List<Task> inProgressTasks = []; // Tasks currently in progress
  List<Task> completedTasks = []; // Tasks that have been completed

  /// Initialize state and load tasks when widget is first created
  @override
  void initState() {
    super.initState();
    _loadTasks(); // Load initial task data
  }

  /// Loads tasks from database and updates UI state
  /// Separates tasks by status for different display sections
  Future<void> _loadTasks() async {
    // Fetch tasks by status from database
    final inProgress = await TaskDatabase.getTasksByStatus(
      TaskStatus.inProgress,
    );
    final completed = await TaskDatabase.getTasksByStatus(TaskStatus.completed);

    // Update UI state with new data
    setState(() {
      inProgressTasks = inProgress;
      completedTasks = completed;
    });
  }

  /// Marks a task as completed and refreshes the task lists
  /// Shows success feedback to user via SnackBar
  Future<void> _markTaskAsCompleted(Task task) async {
    // Update task status in database
    await TaskDatabase.updateTaskStatus(task.id!, TaskStatus.completed);
    _loadTasks(); // Refresh the task lists

    // Show success message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${task.title}" marked as completed!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Moves a completed task back to in progress status
  /// Shows feedback to user and refreshes task lists
  Future<void> _markTaskAsInProgress(Task task) async {
    // Update task status back to in progress
    await TaskDatabase.updateTaskStatus(task.id!, TaskStatus.inProgress);
    _loadTasks(); // Refresh the task lists

    // Show feedback message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${task.title}" moved back to in progress!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Builds UI widget for displaying an in-progress task
  /// Shows task details with a completion button
  Widget _buildInProgressTask(Task task) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100], // Light background
        borderRadius: BorderRadius.circular(8), // Rounded corners
        border: Border.all(color: Colors.grey[300]!), // Subtle border
      ),
      child: Row(
        children: [
          // Task content section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task title
                Text(
                  task.title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                // Task description (if exists)
                if (task.description.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    task.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          // Mark as completed button
          IconButton(
            onPressed: () => _markTaskAsCompleted(task),
            icon: Icon(Icons.check_circle_outline, color: Colors.green),
            tooltip: 'Mark as completed',
          ),
        ],
      ),
    );
  }

  /// Builds UI widget for displaying a completed task
  /// Shows task with strikethrough text and undo option
  Widget _buildCompletedTask(Task task) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Completed checkmark icon
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          // Task content with strikethrough styling
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task title with strikethrough
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    decoration:
                        TextDecoration
                            .lineThrough, // Strike through completed tasks
                  ),
                ),
                // Task description with strikethrough (if exists)
                if (task.description.isNotEmpty)
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
          ),
          // Undo button to move back to in progress
          IconButton(
            onPressed: () => _markTaskAsInProgress(task),
            icon: Icon(Icons.undo, color: Colors.blue, size: 18),
            tooltip: 'Move back to in progress',
          ),
        ],
      ),
    );
  }

  /// Builds the main UI for the home page
  /// Contains header, task sections, and bottom navigation
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with personalized greeting
      appBar: AppBar(title: const Text('Hello Bruce')),

      // Main body content with scrollable sections
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with quote and upcoming events
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily quote or motivation
                Text('Quote: Tidy', style: TextStyle(fontSize: 20)),
                SizedBox(height: 4),
                // Upcoming events or reminders
                Text('Upcoming event', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),

          // Task Progression section with expandable content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              // Toggle expansion state when tapped
              onTap: () {
                setState(() {
                  isTaskProgressionExpanded = !isTaskProgressionExpanded;
                });
              },
              child: Row(
                children: [
                  // Section title with task count
                  Text(
                    'Task Progression (${inProgressTasks.length})',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  // Expand/collapse indicator icon
                  Icon(
                    isTaskProgressionExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Expandable task progression content
          if (isTaskProgressionExpanded)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    // Show empty state if no tasks in progress
                    if (inProgressTasks.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No tasks in progress. Tap the Tasks tab to create a new task!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    // Show list of in-progress tasks
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: inProgressTasks.length,
                          itemBuilder: (context, index) {
                            return _buildInProgressTask(inProgressTasks[index]);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Spacing between sections
          SizedBox(height: 20),

          // Task Completed section with expandable content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              // Toggle expansion state when tapped
              onTap: () {
                setState(() {
                  isTaskCompletedExpanded = !isTaskCompletedExpanded;
                });
              },
              child: Row(
                children: [
                  // Section title with completed task count
                  Text(
                    'Task Completed (${completedTasks.length})',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  // Expand/collapse indicator icon
                  Icon(
                    isTaskCompletedExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Expandable completed tasks content
          if (isTaskCompletedExpanded)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    // Show empty state if no completed tasks
                    if (completedTasks.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No completed tasks yet.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    // Show list of completed tasks
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: completedTasks.length,
                          itemBuilder: (context, index) {
                            return _buildCompletedTask(completedTasks[index]);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // Bottom navigation bar for app-wide navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // Dark theme for navigation bar
        backgroundColor: Colors.blueGrey[800],
        selectedItemColor: Colors.white, // Active tab color
        unselectedItemColor: Colors.blueGrey[300], // Inactive tab color
        selectedFontSize: 12,
        unselectedFontSize: 10,
        // Navigation items
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.check), label: 'Tasks'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lists'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 0, // Currently selected tab (Home)
        // Handle navigation tap events
        onTap: (index) async {
          // Navigate to specific screens based on tab selection
          if (index == 1) {
            // Navigate to Tasks screen and refresh when returning
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TaskScreen()),
            );
            // Refresh tasks when returning from task screen
            _loadTasks();
          }
          // TODO: Add navigation for other tabs (Calendar, Lists, Profile)
        },
      ),
    );
  }
}
