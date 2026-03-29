import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokedex_tracker/theme/app_theme.dart';
import 'package:pokedex_tracker/screens/pokedex_screen.dart';
import 'package:pokedex_tracker/services/storage_service.dart';
import 'package:pokedex_tracker/services/pokedex_data_service.dart';
import 'package:pokedex_tracker/services/pokedex_silent_refresh_service.dart';
import 'package:pokedex_tracker/screens/detail/detail_shared.dart'
    show initBilingualMode, initDefaultSprite;
import 'package:pokedex_tracker/screens/disclaimer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Aumentar cache de imagens: 256MB e 1000 entradas
  PaintingBinding.instance.imageCache.maximumSize = 1000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 256 * 1024 * 1024;

  // Limpar cache legado do PokemonCacheService (pkcache_*)
  await _clearLegacyCacheIfNeeded();

  final savedThemeId = await StorageService().getThemeId();
  appThemeController.setTheme(savedThemeId, _themeModeFromId(savedThemeId));

  await initBilingualMode();
  await initDefaultSprite();

  // Carrega dados locais instantaneamente antes de mostrar qualquer tela
  await PokedexDataService.instance.load();

  // Verificar se o disclaimer já foi aceito
  final disclaimerSeen = await StorageService().isDisclaimerSeen();

  runApp(PokedexTrackerApp(showDisclaimer: !disclaimerSeen));

  // Verificação silenciosa em background — sem impacto visual
  PokedexSilentRefreshService.instance.startInBackground();
}

Future<void> _clearLegacyCacheIfNeeded() async {
  const sentinelKey = 'legacy_cache_cleared_v1';
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(sentinelKey) == true) return;

  final legacyKeys =
      prefs.getKeys().where((k) => k.startsWith('pkcache_')).toList();
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

// ─── APP ─────────────────────────────────────────────────────────

class PokedexTrackerApp extends StatelessWidget {
  final bool showDisclaimer;
  const PokedexTrackerApp({super.key, this.showDisclaimer = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appThemeController,
      builder: (_, __) => MaterialApp(
        title: 'DexCurator',
        debugShowCheckedModeBanner: false,
        theme: appThemeController.lightTheme,
        darkTheme: appThemeController.darkTheme,
        themeMode: appThemeController.themeMode,
        home: showDisclaimer
            ? const _DisclaimerGate()
            : const _LastDexLoader(),
      ),
    );
  }
}

// ─── DISCLAIMER GATE ─────────────────────────────────────────────
// Exibe o disclaimer no primeiro acesso e redireciona para a Pokédex
// após o usuário confirmar.

class _DisclaimerGate extends StatelessWidget {
  const _DisclaimerGate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: DisclaimerScreen(isFromSettings: false),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── LAST DEX LOADER ─────────────────────────────────────────────
// Restaura a última Pokédex visitada pelo usuário.

class _LastDexLoader extends StatefulWidget {
  const _LastDexLoader();

  @override
  State<_LastDexLoader> createState() => _LastDexLoaderState();
}

class _LastDexLoaderState extends State<_LastDexLoader> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lastId = await StorageService().getLastPokedexId();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PokedexScreen(
          pokedexId: lastId ?? 'national',
          pokedexName: lastId == null ? 'Nacional' : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}
