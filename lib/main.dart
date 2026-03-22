import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokedex_tracker/theme/app_theme.dart';
import 'package:pokedex_tracker/screens/home_screen.dart';
import 'package:pokedex_tracker/services/storage_service.dart';
import 'package:pokedex_tracker/services/pokedex_data_service.dart';
import 'package:pokedex_tracker/screens/detail/detail_shared.dart'
    show initBilingualMode, initDefaultSprite;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Aumentar cache de imagens: 256MB e 1000 entradas
  // Evita re-decodificação de sprites ao navegar entre pokedexes
  PaintingBinding.instance.imageCache.maximumSize      = 1000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 256 * 1024 * 1024;

  // Limpar cache antigo do PokemonCacheService (prefixo pkcache_)
  // que causava OutOfMemoryError ao ser carregado pelo SharedPreferences.
  await _clearLegacyCacheIfNeeded();

  final savedThemeId = await StorageService().getThemeId();
  appThemeController.setTheme(savedThemeId, _themeModeFromId(savedThemeId));

  await initBilingualMode();
  await initDefaultSprite();

  // Carrega dados locais instantaneamente antes de mostrar qualquer tela
  await PokedexDataService.instance.load();

  runApp(const PokedexTrackerApp());
}

Future<void> _clearLegacyCacheIfNeeded() async {
  const sentinelKey = 'legacy_cache_cleared_v1';
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(sentinelKey) == true) return;

  final legacyKeys = prefs.getKeys()
      .where((k) => k.startsWith('pkcache_'))
      .toList();
  for (final k in legacyKeys) {
    await prefs.remove(k);
  }

  await prefs.setBool(sentinelKey, true);
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