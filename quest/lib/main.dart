/// Main entry point for the Quest Task Management Application
/// This file initializes the Flutter app and sets up the basic configuration
import 'package:flutter/material.dart';
import 'home/home_page.dart';

/// Entry point of the application
/// Initializes the Flutter app by running the MyApp widget
void main() {
  runApp(const MyApp());
}

/// Root widget of the application
/// This stateless widget serves as the main app configuration and theme setup
class MyApp extends StatelessWidget {
  /// Constructor for MyApp widget
  const MyApp({super.key});

  /// Builds the main application widget tree
  /// Sets up the MaterialApp with theme configuration and initial route
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Application title shown in app switcher
      title: 'Quest - Task Manager',
      // Disable debug banner in release builds
      debugShowCheckedModeBanner: false,
      // Application theme configuration
      theme: ThemeData(
        // Color scheme based on deep purple seed color
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Set HomePage as the initial route/screen
      home: const HomePage(),
    );
  }
}
