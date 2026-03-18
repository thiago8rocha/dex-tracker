import 'package:flutter/material.dart';
import 'package:pokedex_tracker/theme/app_theme.dart';

void main() {
  runApp(const PokedexTrackerApp());
}

class PokedexTrackerApp extends StatelessWidget {
  const PokedexTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokedex Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Placeholder(), // trocar pela HomeScreen depois
    );
  }
}