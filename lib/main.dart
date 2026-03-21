import 'package:flutter/material.dart';
import 'package:pokedex_tracker/theme/app_theme.dart';
import 'package:pokedex_tracker/screens/home_screen.dart';
import 'package:pokedex_tracker/services/storage_service.dart';
import 'package:pokedex_tracker/services/pokedex_data_service.dart';
import 'package:pokedex_tracker/services/pokedex_silent_refresh_service.dart';
import 'package:pokedex_tracker/screens/detail/detail_shared.dart'
    show initBilingualMode, initDefaultSprite;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedThemeId = await StorageService().getThemeId();
  appThemeController.setTheme(savedThemeId, _themeModeFromId(savedThemeId));

  await initBilingualMode();
  await initDefaultSprite();

  // Carrega dados locais instantaneamente antes de mostrar qualquer tela
  await PokedexDataService.instance.load();

  runApp(const PokedexTrackerApp());

  // Verificação silenciosa em background — sem impacto visual
  // Roda 1x por semana, aplica correções na próxima abertura do app
  PokedexSilentRefreshService.instance.startInBackground();
}

ThemeMode _themeModeFromId(String id) {
  if (id == 'system') return ThemeMode.system;
  const darkIds = <String>{'dark'};
  return darkIds.contains(id) ? ThemeMode.dark : ThemeMode.light;
}

class PokedexTrackerApp extends StatefulWidget {
  const PokedexTrackerApp({super.key});

  @override
  State<PokedexTrackerApp> createState() => _PokedexTrackerAppState();
}

class _PokedexTrackerAppState extends State<PokedexTrackerApp> {
  @override
  void initState() {
    super.initState();
    appThemeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    appThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokedex Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: appThemeController.themeMode,
      theme:     AppThemes.light(appThemeController.themeId),
      darkTheme: AppThemes.dark(appThemeController.themeId),
      home: const HomeScreen(),
    );
  }
}