import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokedex_tracker/models/pokemon.dart';
import 'package:pokedex_tracker/screens/detail/detail_shared.dart'
    show PokeballLoader, ptType, defaultSpriteNotifier;
import 'package:pokedex_tracker/screens/go/go_detail_screen.dart';
import 'package:pokedex_tracker/services/pokeapi_service.dart';
import 'package:pokedex_tracker/services/pokedex_data_service.dart';
import 'package:pokedex_tracker/services/storage_service.dart';
import 'package:pokedex_tracker/theme/type_colors.dart';

// PENDÊNCIA — Créditos/Fontes (registrado em 6.4 do doc de projeto):
// - Raids Ativas: dados via scraping de leekduck.com/raid-bosses/
//   Quando a tela de Créditos for implementada, incluir LeekDuck como fonte.

// ─── Mapa EN → chave lowercase para assets/types/ ─────────────────
const _typeKeyMap = {
  'Normal':'normal','Fire':'fire','Water':'water','Electric':'electric',
  'Grass':'grass','Ice':'ice','Fighting':'fighting','Poison':'poison',
  'Ground':'ground','Flying':'flying','Psychic':'psychic','Bug':'bug',
  'Rock':'rock','Ghost':'ghost','Dragon':'dragon','Dark':'dark',
  'Steel':'steel','Fairy':'fairy',
};

// ─── Sprites de formas alternativas ───────────────────────────────
// Complementa o bundle local (assets/sprites/artwork/1–1025.webp).
// Usa o mesmo padrão do projeto: PokeAPI official-artwork via GitHub raw.
// URL base: https://raw.githubusercontent.com/PokeAPI/sprites/master/
//           sprites/pokemon/other/official-artwork/{pokeapi_form_id}.png
//
// A MESMA URL é usada no card E na tela de detalhe, garantindo que o
// Flutter ImageCache reutilize a imagem já baixada — sem recarregamento.
//
// Chave: "{species_id}_{FORMA_TAG}" onde FORMA_TAG vem da URL do LeekDuck
// ex: pm618.fGALARIAN.icon.png → "618_GALARIAN"
const _formaArtwork = <String, String>{
  // ── Regionais ────────────────────────────────────────────────
  '618_GALARIAN': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10172.png', // Galarian Stunfisk
  '105_ALOLA':    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10104.png', // Alolan Marowak
  '52_ALOLA':     'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10101.png', // Alolan Meowth
  '52_GALARIAN':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10161.png', // Galarian Meowth
  '83_GALARIAN':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10162.png', // Galarian Farfetch'd
  '77_GALARIAN':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10159.png', // Galarian Ponyta
  '199_GALARIAN': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10182.png', // Galarian Slowking
  '27_ALOLA':     'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10091.png', // Alolan Sandshrew
  '37_ALOLA':     'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10093.png', // Alolan Vulpix
  '50_ALOLA':     'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10097.png', // Alolan Diglett
  '74_ALOLA':     'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10100.png', // Alolan Geodude
  '88_ALOLA':     'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10102.png', // Alolan Grimer
  '100_GALARIAN': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10164.png', // Galarian Zapdos (Articuno=10163, Moltres=10165)
  '144_GALARIAN': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10163.png', // Galarian Articuno
  '146_GALARIAN': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10165.png', // Galarian Moltres
  // ── Megas ────────────────────────────────────────────────────
  '3_MEGA':    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10033.png', // Mega Venusaur
  '6_MEGAX':   'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10034.png', // Mega Charizard X
  '6_MEGAY':   'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10035.png', // Mega Charizard Y
  '9_MEGA':    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10036.png', // Mega Blastoise
  '15_MEGA':   'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10041.png', // Mega Beedrill
  '18_MEGA':   'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10068.png', // Mega Pidgeot
  '65_MEGA':   'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10043.png', // Mega Alakazam
  '80_MEGA':   'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10026.png', // Mega Slowbro
  '94_MEGA':   'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10044.png', // Mega Gengar
  '115_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10045.png', // Mega Kangaskhan
  '127_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10046.png', // Mega Pinsir
  '130_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10047.png', // Mega Gyarados
  '142_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10048.png', // Mega Aerodactyl
  '181_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10055.png', // Mega Ampharos
  '208_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10056.png', // Mega Steelix
  '212_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10057.png', // Mega Scizor
  '214_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10058.png', // Mega Heracross
  '229_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10051.png', // Mega Houndoom
  '248_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10060.png', // Mega Tyranitar
  '254_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10061.png', // Mega Sceptile
  '257_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10062.png', // Mega Blaziken
  '260_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10063.png', // Mega Swampert
  '282_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10065.png', // Mega Gardevoir
  '302_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10067.png', // Mega Sableye
  '303_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10066.png', // Mega Mawile
  '306_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10069.png', // Mega Aggron
  '308_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10070.png', // Mega Medicham
  '310_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10071.png', // Mega Manectric
  '319_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10072.png', // Mega Sharpedo
  '323_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10073.png', // Mega Camerupt
  '334_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10074.png', // Mega Altaria
  '354_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10075.png', // Mega Banette
  '359_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10076.png', // Mega Absol
  '362_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10077.png', // Mega Glalie
  '373_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10089.png', // Mega Salamence
  '376_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10078.png', // Mega Metagross
  '380_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10079.png', // Mega Latias
  '381_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10080.png', // Mega Latios
  '384_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10090.png', // Mega Rayquaza
  '428_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10085.png', // Mega Lopunny
  '445_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10088.png', // Mega Garchomp
  '448_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10087.png', // Mega Lucario
  '460_MEGA':  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10086.png', // Mega Abomasnow
  // ── Primals ──────────────────────────────────────────────────
  '382_PRIMAL': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10252.png', // Primal Kyogre
  '383_PRIMAL': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/10253.png', // Primal Groudon
};

// ─── Shiny disponível no GO (base estática, mar/2026) ─────────────
const Set<int> _goShinyAvailable = {
  246, 345, 618, 744,
  68, 450, 962,
  894, 229,
  380, 147, 131,
};

class GoRaidsScreen extends StatefulWidget {
  const GoRaidsScreen({super.key});
  @override
  State<GoRaidsScreen> createState() => _GoRaidsScreenState();
}

class _GoRaidsScreenState extends State<GoRaidsScreen> {
  List<_RaidBoss> _raids       = [];
  _EventInfo?     _eventNormal;
  _EventInfo?     _eventShadow;
  bool    _loading = true;
  String? _error;

  final _api     = PokeApiService();
  final _storage = StorageService();
  final Map<int, Map<String, dynamic>?> _statsCache = {};

  @override
  void initState() { super.initState(); _loadRaids(); }

  Future<void> _loadRaids() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse('https://leekduck.com/raid-bosses/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Android 14; Mobile) AppleWebKit/537.36',
          'Accept': 'text/html',
        },
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      final html = res.body;

      // Dividir: normal = tudo antes de "## Shadow Raids", shadow = depois
      final parts     = html.split(RegExp(r'<h2[^>]*>Shadow Raids', caseSensitive: false));
      final normalHtml = parts[0];
      final shadowHtml = parts.length > 1 ? parts[1] : '';

      final raids       = _parseRaids(html);
      final eventNormal = _parseEvent(normalHtml);
      final eventShadow = _parseEvent(shadowHtml);

      if (raids.isEmpty) throw Exception('Sem dados');
      if (mounted) setState(() {
        _raids       = raids;
        _eventNormal = eventNormal;
        _eventShadow = eventShadow;
        _loading     = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _error   = 'Não foi possível carregar as raids';
        _loading = false;
      });
    }
  }

  // ── Parser de raids ────────────────────────────────────────────
  List<_RaidBoss> _parseRaids(String html) {
    final raids   = <_RaidBoss>[];
    final tierMap = {
      '1-Star Raids': 1, '3-Star Raids': 3,
      '5-Star Raids': 5, 'Mega Raids':   6,
    };

    final h2Rx = RegExp(
      r'<h2[^>]*>([\s\S]*?)<\/h2>([\s\S]*?)(?=<h2|$)',
      caseSensitive: false,
    );

    bool inShadow = false;

    for (final m in h2Rx.allMatches(html)) {
      final header  = _stripTags(m.group(1) ?? '').trim();
      final content = m.group(2) ?? '';

      if (header.toLowerCase().contains('shadow raid')) {
        inShadow = true;
        continue;
      }

      int? tier;
      for (final e in tierMap.entries) {
        if (header.contains(e.key)) { tier = e.value; break; }
      }
      if (tier == null) continue;

      final bossRx = RegExp(
        r'<img[^>]+src="([^"]*(?:pm\d|poke_capture)[^"]*)"[^>]*>'
        r'([\s\S]*?)(?=<img[^>]+src="[^"]*(?:pm\d|poke_capture)[^"]*"|$)',
        caseSensitive: false,
      );

      for (final bm in bossRx.allMatches(content)) {
        final imgSrc = bm.group(1) ?? '';
        final chunk  = bm.group(2) ?? '';

        // ID da URL da imagem
        final pmId   = RegExp(r'pm(\d+)\.').firstMatch(imgSrc);
        final pokeId = RegExp(r'poke_capture_(\d+)').firstMatch(imgSrc);
        final id     = int.tryParse(
            pmId?.group(1) ?? pokeId?.group(1) ?? '0') ?? 0;
        if (id == 0) continue;

        // Forma: extraída de pm618.fGALARIAN.icon.png → "GALARIAN"
        final formaMatch = RegExp(r'\.f([A-Za-z_]+)\.icon', caseSensitive: false)
            .firstMatch(imgSrc);
        final formaTag   = formaMatch?.group(1)?.toUpperCase();
        final isMega     = formaTag != null && formaTag.startsWith('MEGA');
        final isRegional = formaTag != null && !isMega;

        // Sprite: lookup no mapa de formas; fallback = bundle local
        // A MESMA string é usada no card e no detalhe → ImageCache hit garantido
        final formaKey  = formaTag != null ? '${id}_$formaTag' : null;
        final formaUrl  = formaKey != null ? _formaArtwork[formaKey] : null;

        // Nome: texto antes da primeira <img de tipo
        final rawName  = _stripTags(chunk.split('<img')[0]).trim();
        final baseName = rawName
            .replaceFirst(RegExp(r'^(Shadow|Mega)\s+', caseSensitive: false), '')
            .trim();
        if (baseName.isEmpty) continue;

        // Tipos: atributo title="Rock"
        final types = RegExp(r'title="([A-Za-z]+)"')
            .allMatches(chunk)
            .map((t) => _typeKeyMap[t.group(1)] ?? '')
            .where((t) => t.isNotEmpty)
            .toList();

        // Shiny
        final hasShiny = chunk.toLowerCase().contains('shiny')
            || _goShinyAvailable.contains(id);

        raids.add(_RaidBoss(
          id: id, name: baseName, tier: tier,
          isShadow: inShadow, isMega: isMega, isRegional: isRegional,
          formaUrl: formaUrl,
          types: types,
          shinyAvailable: hasShiny,
        ));
      }
    }
    return raids;
  }

  // ── Parser de evento ───────────────────────────────────────────
  // Retorna apenas o nome do evento.
  _EventInfo? _parseEvent(String html) {
    final stripped = html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ');

    final m = RegExp(
      r'Selected Event\s+Ongoing\s+([\s\S]*?)(?=Selected Event|##|\Z)',
      caseSensitive: false,
    ).firstMatch(stripped);

    if (m == null) return null;

    final lines = (m.group(1) ?? '')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty
            && !RegExp(r'^Starts?:', caseSensitive: false).hasMatch(l)
            && !RegExp(r'^Ends?:', caseSensitive: false).hasMatch(l))
        .toList();

    final name = lines.isNotEmpty ? lines[0] : null;
    if (name == null || name.length < 4) return null;
    return _EventInfo(name: name);
  }

  String _stripTags(String s) => s.replaceAll(RegExp(r'<[^>]+>'), '').trim();

  // ── Navegação para detalhe ─────────────────────────────────────
  Future<void> _openDetail(BuildContext ctx, _RaidBoss boss) async {
    final bundleTypes = PokedexDataService.instance.getTypes(boss.id);
    final types = boss.types.isNotEmpty ? boss.types : bundleTypes;

    if (!_statsCache.containsKey(boss.id)) {
      final apiData = await _api.fetchPokemon(boss.id)
          .timeout(const Duration(seconds: 4), onTimeout: () => null);
      _statsCache[boss.id] = apiData;
    }
    final apiData = _statsCache[boss.id];

    int statVal(String name) {
      final rawStats = apiData?['stats'] as List<dynamic>?;
      if (rawStats == null) return 0;
      final s = rawStats.firstWhere(
        (s) => s['stat']['name'] == name,
        orElse: () => null,
      );
      return (s?['base_stat'] as int?) ?? 0;
    }

    final spriteType = defaultSpriteNotifier.value;
    String bundleAsset(String t) {
      switch (t) {
        case 'pixel': return 'assets/sprites/pixel/${boss.id}.webp';
        case 'home':  return 'assets/sprites/home/${boss.id}.webp';
        default:      return 'assets/sprites/artwork/${boss.id}.webp';
      }
    }
    const base = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon';

    // Para formas: usa formaUrl (mesma usada no card → ImageCache hit, sem recarregamento)
    // Para base: usa bundle local
    final mainSprite = boss.formaUrl ?? bundleAsset(spriteType);

    final pokemon = Pokemon(
      id:                  boss.id,
      entryNumber:         boss.id,
      name:                boss.name,
      types:               types.isNotEmpty ? types : ['normal'],
      baseHp:              statVal('hp'),
      baseAttack:          statVal('attack'),
      baseDefense:         statVal('defense'),
      baseSpAttack:        statVal('special-attack'),
      baseSpDefense:       statVal('special-defense'),
      baseSpeed:           statVal('speed'),
      spriteUrl:           mainSprite,
      spriteShinyUrl:      '$base/other/official-artwork/shiny/${boss.id}.png',
      spritePixelUrl:      bundleAsset('pixel'),
      spritePixelShinyUrl: '$base/shiny/${boss.id}.png',
      spritePixelFemaleUrl: null,
      spriteHomeUrl:       bundleAsset('home'),
      spriteHomeShinyUrl:  '$base/other/home/shiny/${boss.id}.png',
      spriteHomeFemaleUrl: null,
    );

    if (!ctx.mounted) return;
    bool caught = await _storage.isCaught('pokémon_go', boss.id);
    if (!ctx.mounted) return;

    Navigator.push(
      ctx,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => GoDetailScreen(
          pokemon: pokemon,
          caught: caught,
          onToggleCaught: () async {
            caught = !caught;
            await _storage.setCaught('pokémon_go', boss.id, caught);
          },
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 180),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raids Ativas'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadRaids,
          ),
        ],
      ),
      body: _loading
          ? Center(child: PokeballLoader())
          : _raids.isEmpty
              ? _EmptyState(
                  message: _error ?? 'Nenhum raid ativo no momento',
                  onRetry: _loadRaids,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: _buildBody(),
                ),
    );
  }

  List<Widget> _buildBody() {
    final widgets = <Widget>[];

    // Evento normal antes das raids normais
    if (_eventNormal != null) {
      widgets.add(_EventBanner(event: _eventNormal!));
      widgets.add(const SizedBox(height: 12));
    }

    // Raids normais
    if (_raids.any((r) => !r.isShadow)) {
      widgets.add(_SectionDivider(label: 'RAIDS', color: const Color(0xFF1565C0)));
      widgets.add(const SizedBox(height: 12));
      for (final tier in [1, 3, 5, 6]) {
        final list = _raids.where((r) => r.tier == tier && !r.isShadow).toList();
        if (list.isEmpty) continue;
        widgets.add(_TierHeader(tier: tier, isShadow: false));
        widgets.add(const SizedBox(height: 10));
        widgets.add(_RaidGrid(bosses: list, onTap: _openDetail));
        widgets.add(const SizedBox(height: 16));
      }
    }

    // Evento shadow antes das shadow raids
    if (_eventShadow != null) {
      widgets.add(const SizedBox(height: 4));
      widgets.add(_EventBanner(event: _eventShadow!));
      widgets.add(const SizedBox(height: 12));
    }

    // Shadow raids
    if (_raids.any((r) => r.isShadow)) {
      widgets.add(_SectionDivider(label: 'SHADOW RAIDS', color: const Color(0xFF6A1FAB)));
      widgets.add(const SizedBox(height: 12));
      for (final tier in [1, 3, 5, 6]) {
        final list = _raids.where((r) => r.tier == tier && r.isShadow).toList();
        if (list.isEmpty) continue;
        widgets.add(_TierHeader(tier: tier, isShadow: true));
        widgets.add(const SizedBox(height: 10));
        widgets.add(_RaidGrid(bosses: list, onTap: _openDetail));
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
  }
}

// ─── Modelos ──────────────────────────────────────────────────────

class _RaidBoss {
  final int          id;
  final String       name;
  final int          tier;
  final bool         isShadow;
  final bool         isMega;
  final bool         isRegional;
  final String?      formaUrl;      // URL artwork forma — null = usar bundle
  final List<String> types;
  final bool         shinyAvailable;

  const _RaidBoss({
    required this.id, required this.name, required this.tier,
    required this.isShadow, required this.isMega, required this.isRegional,
    this.formaUrl,
    required this.types, required this.shinyAvailable,
  });

  String get displayName {
    var n = name;
    if (isMega)   n = 'Mega $n';
    if (isShadow) n = 'Shadow $n';
    return n;
  }
}

class _EventInfo {
  final String name;
  const _EventInfo({required this.name});
}

// ─── Banner do evento ─────────────────────────────────────────────

class _EventBanner extends StatelessWidget {
  final _EventInfo event;
  const _EventBanner({required this.event});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Text(
        event.name,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Divisor de seção ─────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final String label;
  final Color  color;
  const _SectionDivider({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Divider(color: color.withOpacity(0.3), thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            letterSpacing: 1.2, color: color)),
      ),
      Expanded(child: Divider(color: color.withOpacity(0.3), thickness: 1)),
    ]);
  }
}

// ─── Header de tier ───────────────────────────────────────────────

class _TierHeader extends StatelessWidget {
  final int tier;
  final bool isShadow;
  const _TierHeader({required this.tier, required this.isShadow});

  static const _meta = {
    6: ('Mega / Primal', Color(0xFF9C27B0)),
    5: ('5 Estrelas',    Color(0xFFE65100)),
    3: ('3 Estrelas',    Color(0xFF2E7D32)),
    1: ('1 Estrela',     Color(0xFF546E7A)),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _meta[tier] ?? ('Raid', const Color(0xFF888888));
    final c = isShadow ? const Color(0xFF6A1FAB) : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

// ─── Grid de pokémon ──────────────────────────────────────────────

class _RaidGrid extends StatelessWidget {
  final List<_RaidBoss> bosses;
  final Future<void> Function(BuildContext, _RaidBoss) onTap;
  const _RaidGrid({required this.bosses, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,
        crossAxisSpacing: 8,
        mainAxisSpacing:  8,
        childAspectRatio: 0.82,
      ),
      itemCount: bosses.length,
      itemBuilder: (ctx, i) => _RaidCard(boss: bosses[i], onTap: onTap),
    );
  }
}

// ─── Card de pokémon ──────────────────────────────────────────────

class _RaidCard extends StatefulWidget {
  final _RaidBoss boss;
  final Future<void> Function(BuildContext, _RaidBoss) onTap;
  const _RaidCard({required this.boss, required this.onTap});

  @override
  State<_RaidCard> createState() => _RaidCardState();
}

class _RaidCardState extends State<_RaidCard> {
  bool _navigating = false;

  @override
  Widget build(BuildContext context) {
    final boss   = widget.boss;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bundleTypes  = PokedexDataService.instance.getTypes(boss.id);
    final displayTypes = boss.types.isNotEmpty ? boss.types : bundleTypes;

    final color1 = displayTypes.isNotEmpty
        ? TypeColors.fromType(ptType(displayTypes[0])) : scheme.primary;
    final color2 = displayTypes.length > 1
        ? TypeColors.fromType(ptType(displayTypes[1])) : color1;
    final bgOp = isDark ? 0.15 : 0.10;

    // Sprite:
    // - formas (mega/regional): Image.network com URL PokeAPI — mesma URL do detalhe
    // - base: Image.asset do bundle local — sem tráfego de rede
    Widget spriteWidget() {
      if (_navigating) {
        return Center(
          child: SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: color1),
          ),
        );
      }
      if (boss.formaUrl != null) {
        return Image.network(
          boss.formaUrl!,
          width: 64, height: 64, fit: BoxFit.contain,
          // Pré-carrega para o detalhe — Flutter mantém no ImageCache
          cacheWidth: 256, cacheHeight: 256,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/sprites/artwork/${boss.id}.webp',
            width: 64, height: 64, fit: BoxFit.contain,
          ),
        );
      }
      return Image.asset(
        'assets/sprites/artwork/${boss.id}.webp',
        width: 64, height: 64, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.catching_pokemon,
          color: scheme.onSurfaceVariant.withOpacity(0.4), size: 36,
        ),
      );
    }

    return GestureDetector(
      onTap: _navigating ? null : () async {
        setState(() => _navigating = true);
        await widget.onTap(context, boss);
        if (mounted) setState(() => _navigating = false);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: displayTypes.length > 1
                ? [color1.withOpacity(bgOp), color2.withOpacity(bgOp)]
                : [color1.withOpacity(bgOp), color1.withOpacity(bgOp * 0.5)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color1.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 64, width: double.infinity,
                    child: spriteWidget(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    boss.displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
                  ),
                  const SizedBox(height: 5),
                  // Tipos: empilhados, largura mínima para uniformidade
                  if (displayTypes.isNotEmpty)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: displayTypes.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: _TypeBadge(type: t),
                      )).toList(),
                    ),
                ],
              ),
            ),
            // Ícone shiny discreto
            if (boss.shinyAvailable)
              const Positioned(
                top: 5, right: 5,
                child: Icon(Icons.auto_awesome,
                    size: 12, color: Color(0xFFFFC107)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge de tipo com ícone PNG ──────────────────────────────────
// Largura mínima fixa → todos os badges têm o mesmo tamanho.
// "Psíquico" e "Fantasma" (8 chars) são os mais longos — minWidth acomoda.

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  static const _names = {
    'normal':   'Normal',   'fire':     'Fogo',    'water':    'Água',
    'electric': 'Elétrico', 'grass':    'Planta',  'ice':      'Gelo',
    'fighting': 'Lutador',  'poison':   'Veneno',  'ground':   'Terreno',
    'flying':   'Voador',   'psychic':  'Psíquico','bug':      'Inseto',
    'rock':     'Pedra',    'ghost':    'Fantasma','dragon':   'Dragão',
    'dark':     'Sombrio',  'steel':    'Aço',     'fairy':    'Fada',
  };

  @override
  Widget build(BuildContext context) {
    final color = TypeColors.fromType(ptType(type));
    final label = _names[type] ?? type;
    return Container(
      height: 18,
      // minWidth garante que todos os badges tenham a mesma largura mínima,
      // mas o badge pode crescer para acomodar labels mais longos ("Psíquico").
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/types/$type.png',
            width: 10, height: 10,
            errorBuilder: (_, __, ___) =>
                const SizedBox(width: 10, height: 10),
          ),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600,
                  color: Colors.white, height: 1.0)),
        ],
      ),
    );
  }
}

// ─── Estado vazio ─────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _EmptyState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined, size: 64,
                color: Theme.of(context)
                    .colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6))),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
}
