/// Task Screen - Comprehensive task management interface
/// This file contains the main task management screen with full CRUD operations,
/// progress tracking, and advanced task management features

import 'package:flutter/material.dart';
import 'task_model.dart';
import 'task_database.dart';

/// Main task management screen widget
/// Provides interface for viewing, creating, editing, and managing tasks
class TaskScreen extends StatefulWidget {
  /// Constructor for TaskScreen widget
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

/// State class for TaskScreen containing all task management logic
class _TaskScreenState extends State<TaskScreen> {
  // Data lists for different task states
  List<Task> activeTasks = []; // Tasks currently in progress
  List<Task> completedTasks = []; // Tasks that have been completed

  // UI state for showing/hiding completed tasks
  bool showCompleted = false;

  /// Initialize state and load tasks when widget is created
  @override
  void initState() {
    super.initState();
    _loadTasks(); // Load initial task data
  }

  /// Loads tasks from database and updates UI state
  /// Separates active and completed tasks for different display sections
  Future<void> _loadTasks() async {
    // Fetch tasks by status from database
    final active = await TaskDatabase.getTasksByStatus(TaskStatus.inProgress);
    final completed = await TaskDatabase.getTasksByStatus(TaskStatus.completed);

    // Update UI state with fresh data
    setState(() {
      activeTasks = active;
      completedTasks = completed;
    });
  }

  /// Shows dialog for creating a new task
  /// Handles task creation flow and database insertion
  Future<void> _showCreateTaskDialog() async {
    // Show modal dialog and wait for result
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => const CreateTaskDialog(),
    );

    // If user created a task, save it to database
    if (result != null) {
      await TaskDatabase.insertTask(result);
      _loadTasks(); // Refresh task list
      _showSuccessSnackBar('Task "${result.title}" created successfully!');
    }
  }

  /// Shows dialog for editing an existing task
  /// Handles task editing flow and database updates
  Future<void> _showEditTaskDialog(Task task) async {
    // Show modal dialog pre-populated with task data
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => EditTaskDialog(task: task),
    );

    // If user made changes, update database
    if (result != null) {
      await TaskDatabase.updateTask(result);
      _loadTasks(); // Refresh task list
      _showSuccessSnackBar('Task "${result.title}" updated successfully!');
    }
  }

  /// Updates daily progress for a task
  /// Implements habit tracking with streak logic and daily limits
  Future<void> _updateTaskProgress(Task task) async {
    // Prevent multiple progress updates in the same day
    if (task.progressUpdatedToday) {
      _showErrorSnackBar('Progress already updated today!');
      return;
    }

    // Update progress in database
    await TaskDatabase.updateTaskProgress(task.id!);
    _loadTasks(); // Refresh to show new progress

    // Show progress feedback with streak information
    final updatedTask = await TaskDatabase.getTaskById(task.id!);
    if (updatedTask != null) {
      _showSuccessSnackBar(
        'Progress updated! Day ${updatedTask.currentProgress}/${updatedTask.goalDays} (Streak: ${updatedTask.streak})',
      );
    }
  }

  /// Marks a task as completed
  /// Moves task from active to completed state with celebration feedback
  Future<void> _markTaskCompleted(Task task) async {
    await TaskDatabase.updateTaskStatus(task.id!, TaskStatus.completed);
    _loadTasks(); // Refresh task lists
    _showSuccessSnackBar('Task "${task.title}" completed! 🎉');
  }

  /// Permanently deletes a task after user confirmation
  /// Shows confirmation dialog to prevent accidental deletions
  Future<void> _deleteTask(Task task) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Are you sure you want to delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    // If user confirmed deletion, remove from database
    if (confirmed == true) {
      await TaskDatabase.deleteTask(task.id!);
      _loadTasks(); // Refresh task list
      _showSuccessSnackBar('Task "${task.title}" deleted');
    }
  }

  /// Shows green success message to user
  /// Used for positive feedback on successful operations
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// Shows red error message to user
  /// Used for error feedback and validation messages
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Builds the main UI for the task management screen
  /// Contains task lists, toggle controls, and floating action button
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with screen title and visibility controls
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          // Toggle button for showing/hiding completed tasks
          IconButton(
            onPressed: () {
              setState(() {
                showCompleted = !showCompleted;
              });
            },
            icon: Icon(showCompleted ? Icons.visibility_off : Icons.visibility),
            tooltip: showCompleted ? 'Hide Completed' : 'Show Completed',
          ),
        ],
      ),

      // Main content with pull-to-refresh functionality
      body: RefreshIndicator(
        onRefresh: _loadTasks, // Refresh data when user pulls down
        child: Column(
          children: [
            // Active Tasks Section - Main content area
            Expanded(
              child:
                  activeTasks.isEmpty
                      ? _buildEmptyState() // Show empty state if no tasks
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activeTasks.length,
                        itemBuilder: (context, index) {
                          // Build custom task card for each active task
                          return TaskCard(
                            task: activeTasks[index],
                            onProgressUpdate:
                                () => _updateTaskProgress(activeTasks[index]),
                            onComplete:
                                () => _markTaskCompleted(activeTasks[index]),
                            onEdit:
                                () => _showEditTaskDialog(activeTasks[index]),
                            onDelete: () => _deleteTask(activeTasks[index]),
                          );
                        },
                      ),
            ),

            // Completed Tasks Section - Optional expandable section
            if (showCompleted && completedTasks.isNotEmpty) ...[
              // Section header for completed tasks
              Container(
                width: double.infinity,
                color: Colors.grey[100],
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Completed Tasks (${completedTasks.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              // Fixed height list for completed tasks
              SizedBox(
                height: 200, // Limited height to prevent overwhelming UI
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: completedTasks.length,
                  itemBuilder: (context, index) {
                    // Build simplified card for completed tasks
                    return CompletedTaskCard(
                      task: completedTasks[index],
                      onDelete: () => _deleteTask(completedTasks[index]),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),

      // Floating Action Button for creating new tasks
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        child: const Icon(Icons.add),
        tooltip: 'Create New Task',
      ),
    );
  }

  /// Builds empty state UI when no tasks exist
  /// Provides helpful guidance for first-time users
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large icon for visual appeal
          Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          // Primary message
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          // Helpful instruction for users
          Text(
            'Tap the + button to create your first task',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

/// Custom widget for displaying active task cards
/// Shows comprehensive task information with interactive elements for progress tracking
class TaskCard extends StatelessWidget {
  // Task data to display
  final Task task;

  // Callback functions for user interactions
  final VoidCallback
  onProgressUpdate; // Called when user updates daily progress
  final VoidCallback onComplete; // Called when user marks task as complete
  final VoidCallback onEdit; // Called when user wants to edit task
  final VoidCallback onDelete; // Called when user wants to delete task

  /// Constructor requiring task data and callback functions
  const TaskCard({
    super.key,
    required this.task,
    required this.onProgressUpdate,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  /// Builds the task card UI with all task information and controls
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2, // Subtle shadow for depth
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with title, category, and menu
            Row(
              children: [
                // Category emoji icon
                Text(task.categoryIcon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),

                // Task title and category information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main task title
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Category label
                      Text(
                        task.categoryDisplayName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // More options menu (edit/delete)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder:
                      (context) => [
                        // Edit option
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        // Delete option with red styling
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),

            // Task description section (if exists)
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],

            const SizedBox(height: 12),

            // Progress tracking section
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress text and streak indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Progress counter
                          Text(
                            'Progress: ${task.currentProgress}/${task.goalDays} days',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Streak badge (shown only if streak > 0)
                          if (task.streak > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '🔥 ${task.streak}', // Fire emoji with streak count
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Visual progress bar
                      LinearProgressIndicator(
                        value: task.progressPercentage,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          // Green when completed, blue when in progress
                          task.progressPercentage >= 1.0
                              ? Colors.green
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons section
            Row(
              children: [
                // Daily progress update button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        task.progressUpdatedToday
                            ? null // Disabled if already updated today
                            : onProgressUpdate,
                    icon: Icon(
                      task.progressUpdatedToday
                          ? Icons
                              .check_circle // Check icon when done
                          : Icons
                              .add_circle_outline, // Plus icon when available
                    ),
                    label: Text(
                      task.progressUpdatedToday
                          ? 'Done Today'
                          : 'Progress Today',
                    ),
                    style: ElevatedButton.styleFrom(
                      // Gray styling when disabled, blue when active
                      backgroundColor:
                          task.progressUpdatedToday
                              ? Colors.grey[300]
                              : Colors.blue,
                      foregroundColor:
                          task.progressUpdatedToday
                              ? Colors.grey[600]
                              : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Mark as complete button
                ElevatedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check),
                  label: const Text('Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simplified widget for displaying completed task cards
/// Shows basic task information with delete option only
class CompletedTaskCard extends StatelessWidget {
  // Task data to display
  final Task task;

  // Callback for delete action
  final VoidCallback onDelete;

  /// Constructor requiring task data and delete callback
  const CompletedTaskCard({
    super.key,
    required this.task,
    required this.onDelete,
  });

  /// Builds simplified card UI for completed tasks
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        // Completed status indicator
        leading: const Icon(Icons.check_circle, color: Colors.green),

        // Task title with strikethrough to indicate completion
        title: Text(
          task.title,
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey,
          ),
        ),

        // Task details: category and progress summary
        subtitle: Text(
          '${task.categoryIcon} ${task.categoryDisplayName} • ${task.currentProgress}/${task.goalDays} days',
          style: const TextStyle(fontSize: 12),
        ),

        // Delete button
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
        ),
      ),
    );
  }
}

/// Modal dialog for creating new tasks
/// Provides form interface for entering task details
class CreateTaskDialog extends StatefulWidget {
  /// Constructor for create task dialog
  const CreateTaskDialog({super.key});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

/// State class for create task dialog containing form logic
class _CreateTaskDialogState extends State<CreateTaskDialog> {
  // Form input controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final goalDaysController = TextEditingController(
    text: '30',
  ); // Default 30 days

  // Selected category with default value
  TaskCategory selectedCategory = TaskCategory.other;

  /// Clean up controllers when dialog is disposed
  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    goalDaysController.dispose();
    super.dispose();
  }

  /// Builds the create task dialog UI
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Task'),

      // Scrollable content for form fields
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Task title input (required)
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title *',
                border: OutlineInputBorder(),
              ),
              autofocus: true, // Auto-focus for immediate typing
            ),
            const SizedBox(height: 16),

            // Task description input (optional)
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2, // Allow multi-line descriptions
            ),
            const SizedBox(height: 16),

            // Category selection dropdown
            DropdownButtonFormField<TaskCategory>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              // Build dropdown items from all available categories
              items:
                  TaskCategory.values.map((category) {
                    final task = Task(
                      title: '',
                      description: '',
                      category: category,
                    );
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Text(task.categoryIcon), // Category emoji
                          const SizedBox(width: 8),
                          Text(task.categoryDisplayName), // Category name
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Goal days input
            TextField(
              controller: goalDaysController,
              decoration: const InputDecoration(
                labelText: 'Goal (days)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number, // Numeric keyboard
            ),
          ],
        ),
      ),

      // Dialog action buttons
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        // Create button (validates input)
        ElevatedButton(
          onPressed: () {
            // Validate that title is not empty
            if (titleController.text.trim().isNotEmpty) {
              // Create new task with form data
              final task = Task(
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                category: selectedCategory,
                goalDays: int.tryParse(goalDaysController.text) ?? 30,
              );
              Navigator.pop(context, task); // Return created task
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Modal dialog for editing existing tasks
/// Pre-populates form with current task data for modification
class EditTaskDialog extends StatefulWidget {
  // Task to be edited
  final Task task;

  /// Constructor requiring the task to edit
  const EditTaskDialog({super.key, required this.task});

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

/// State class for edit task dialog containing form logic
class _EditTaskDialogState extends State<EditTaskDialog> {
  // Form input controllers (late initialized with current task data)
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController goalDaysController;
  late TaskCategory selectedCategory;

  /// Initialize controllers with existing task data
  @override
  void initState() {
    super.initState();
    // Pre-populate form fields with current task values
    titleController = TextEditingController(text: widget.task.title);
    descriptionController = TextEditingController(
      text: widget.task.description,
    );
    goalDaysController = TextEditingController(
      text: widget.task.goalDays.toString(),
    );
    selectedCategory = widget.task.category;
  }

  /// Clean up controllers when dialog is disposed
  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    goalDaysController.dispose();
    super.dispose();
  }

  /// Builds the edit task dialog UI (similar to create dialog)
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Task'),

      // Scrollable content for form fields
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Task title input (required, pre-populated)
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Task description input (optional, pre-populated)
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Category selection dropdown (pre-selected)
            DropdownButtonFormField<TaskCategory>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              // Build dropdown items from all available categories
              items:
                  TaskCategory.values.map((category) {
                    final task = Task(
                      title: '',
                      description: '',
                      category: category,
                    );
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Text(task.categoryIcon), // Category emoji
                          const SizedBox(width: 8),
                          Text(task.categoryDisplayName), // Category name
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Goal days input (pre-populated)
            TextField(
              controller: goalDaysController,
              decoration: const InputDecoration(
                labelText: 'Goal (days)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),

      // Dialog action buttons
      actions: [
        // Cancel button (discards changes)
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        // Save button (validates and applies changes)
        ElevatedButton(
          onPressed: () {
            // Validate that title is not empty
            if (titleController.text.trim().isNotEmpty) {
              // Create updated task using copyWith method
              final updatedTask = widget.task.copyWith(
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                category: selectedCategory,
                goalDays:
                    int.tryParse(goalDaysController.text) ??
                    widget.task.goalDays, // Fallback to original value
              );
              Navigator.pop(context, updatedTask); // Return updated task
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
