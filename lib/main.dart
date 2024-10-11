// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shopping_list/Widgets/grocery_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Define a seed color for dynamic theming
    const Color seedColor = Color(0xFF93E5FA); // A vibrant turquoise

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Groceries',
      theme: ThemeData(
        // Enable Material 3 for modern design
        useMaterial3: true,
        // Create a color scheme from the seed color
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light, // Light theme for better visibility
          primary: seedColor,
          secondary: Colors.amber,
         // background: Colors.white,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
        ),
        // Make the scaffold background transparent
        scaffoldBackgroundColor: Colors.transparent,
        // Define a modern text theme
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
          // Add more text styles as needed
        ),
        // Customize AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // Make AppBar transparent
          elevation: 0, // Remove shadow
          iconTheme: IconThemeData(color: Colors.black87), // Icon color
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Customize elevated buttons for a modern look
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: seedColor, // Button background color
            foregroundColor: Colors.white, // Button text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Customize input decorations for text fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.8), // Semi-transparent for visibility
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[600]),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
        // Customize card theme to stand out against the background
        cardTheme: CardTheme(
          color: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.black26,
        ),
        // FloatingActionButton theme
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // Define other theme customizations as needed
      ),
      home: const GroceryList(),
    );
  }
}
