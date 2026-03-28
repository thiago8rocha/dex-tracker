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
//   LeekDuck é a fonte mais confiável para raids do Pokémon GO.
//   Quando a tela de Créditos for implementada, incluir LeekDuck como fonte.

// ─── Pokémon com shiny disponível no GO (base estática, mar/2026) ─
// Complementa detecção pelo HTML do LeekDuck.
const Set<int> _goShinyAvailable = {
  // 1 estrela
  246, 345, 524, 744,
  // 3 estrelas
  68, 450, 641,
  // 5 estrelas
  889, 894,
  // Mega
  229,
  // Shadow
  380,
  // Regionais
  618,
};

class GoRaidsScreen extends StatefulWidget {
  const GoRaidsScreen({super.key});
  @override
  State<GoRaidsScreen> createState() => _GoRaidsScreenState();
}

class _GoRaidsScreenState extends State<GoRaidsScreen> {
  List<_RaidBoss>  _raids  = [];
  List<_EventInfo> _events = [];
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

      final html   = res.body;
      final raids  = _parseRaids(html);
      final events = _parseEvents(html);

      if (raids.isEmpty) throw Exception('Sem dados');
      if (mounted) setState(() {
        _raids   = raids;
        _events  = events;
        _loading = false;
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
      final header  = _strip(m.group(1) ?? '').trim();
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

      // Data de fim do bloco
      final endsM = RegExp(
        r'Ends:\s*([A-Za-z]+\s+\d{1,2},?\s*\d{4}[^<\n]*)',
        caseSensitive: false,
      ).firstMatch(content);
      final endsStr = endsM?.group(1)?.trim();

      final bossRx = RegExp(
        r'<img[^>]+src="([^"]*(?:pm\d|poke_capture)[^"]*)"[^>]*>'
        r'([\s\S]*?)(?=<img[^>]+src="[^"]*(?:pm\d|poke_capture)[^"]*"|$)',
        caseSensitive: false,
      );

      for (final bm in bossRx.allMatches(content)) {
        final img   = bm.group(1) ?? '';
        final chunk = bm.group(2) ?? '';

        final pmId   = RegExp(r'pm(\d+)\.').firstMatch(img);
        final pokeId = RegExp(r'poke_capture_(\d+)').firstMatch(img);
        final id     = int.tryParse(pmId?.group(1) ?? pokeId?.group(1) ?? '0') ?? 0;
        if (id == 0) continue;

        final isMega     = img.contains('.fS.') || img.contains('.fMEGA.')
            || img.toLowerCase().contains('mega');
        final isRegional = img.contains('.fA.') || img.contains('.fG.')
            || img.contains('.fH.') || img.contains('.fGAL.')
            || img.toLowerCase().contains('galarian')
            || img.toLowerCase().contains('alolan');

        // Nome base (sem prefixo Shadow)
        final nameM = RegExp(r'>([A-Za-zÀ-ú][^<\n]+?)<')
            .allMatches(chunk)
            .firstWhere(
              (x) => x.group(1)!.trim().isNotEmpty
                  && !x.group(1)!.contains('CP')
                  && !RegExp(r'^\d').hasMatch(x.group(1)!.trim()),
              orElse: () => RegExp(r'x').firstMatch('') as RegExpMatch,
            );
        final baseName = (nameM.group(1)?.trim() ?? '')
            .replaceFirst(RegExp(r'^Shadow\s+', caseSensitive: false), '');
        if (baseName.isEmpty) continue;

        // CP — unboosted e boosted (weather)
        final cpMatches = RegExp(r'CP\s*([\d,]+)\s*[-–]\s*([\d,]+)')
            .allMatches(chunk).toList();
        final minCp      = cpMatches.isNotEmpty
            ? int.tryParse(cpMatches[0].group(1)!.replaceAll(',', '')) ?? 0 : 0;
        final maxCp      = cpMatches.isNotEmpty
            ? int.tryParse(cpMatches[0].group(2)!.replaceAll(',', '')) ?? 0 : 0;
        final minCpBoost = cpMatches.length > 1
            ? int.tryParse(cpMatches[1].group(1)!.replaceAll(',', '')) ?? 0 : 0;
        final maxCpBoost = cpMatches.length > 1
            ? int.tryParse(cpMatches[1].group(2)!.replaceAll(',', '')) ?? 0 : 0;

        // Shiny — detecta no HTML ou via lista estática
        final hasShiny = chunk.toLowerCase().contains('shiny')
            || chunk.contains('icon-shiny')
            || _goShinyAvailable.contains(id);

        raids.add(_RaidBoss(
          id: id, name: baseName, tier: tier,
          isShadow: inShadow, isMega: isMega, isRegional: isRegional,
          minCp: minCp, maxCp: maxCp,
          minCpBoost: minCpBoost, maxCpBoost: maxCpBoost,
          shinyAvailable: hasShiny, endsDate: endsStr,
        ));
      }
    }
    return raids;
  }

  // ── Parser de eventos ──────────────────────────────────────────
  List<_EventInfo> _parseEvents(String html) {
    final events   = <_EventInfo>[];
    final endsRx   = RegExp(r'Ends:\s*([A-Za-z]+\s+\d{1,2},?\s*\d{4}[^<\n]*)', caseSensitive: false);
    final startsRx = RegExp(r'Starts?:\s*([A-Za-z]+\s+\d{1,2},?\s*\d{4}[^<\n]*)', caseSensitive: false);

    final h1Rx = RegExp(
      r'<h[12][^>]*class="[^"]*event[^"]*"[^>]*>([\s\S]*?)<\/h[12]>',
      caseSensitive: false,
    );
    for (final m in h1Rx.allMatches(html)) {
      final name = _strip(m.group(1) ?? '').trim();
      if (name.isEmpty) continue;
      final after = html.substring(m.end, math.min(m.end + 500, html.length));
      events.add(_EventInfo(
        name: name,
        start: startsRx.firstMatch(after)?.group(1)?.trim(),
        end:   endsRx.firstMatch(after)?.group(1)?.trim(),
      ));
    }
    return events;
  }

  String _strip(String s) => s.replaceAll(RegExp(r'<[^>]+>'), '').trim();

  // ── Navegação para detalhe ─────────────────────────────────────
  Future<void> _openDetail(BuildContext ctx, _RaidBoss boss) async {
    final svc   = PokedexDataService.instance;
    final types = svc.getTypes(boss.id);

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
    String spriteUrl(String t) {
      switch (t) {
        case 'pixel':   return 'assets/sprites/pixel/${boss.id}.webp';
        case 'home':    return 'assets/sprites/home/${boss.id}.webp';
        default:        return 'assets/sprites/artwork/${boss.id}.webp';
      }
    }
    const base = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon';

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
      spriteUrl:           spriteUrl(spriteType),
      spriteShinyUrl:      '$base/other/official-artwork/shiny/${boss.id}.png',
      spritePixelUrl:      spriteUrl('pixel'),
      spritePixelShinyUrl: '$base/shiny/${boss.id}.png',
      spritePixelFemaleUrl: null,
      spriteHomeUrl:       spriteUrl('home'),
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
                  children: [
                    if (_events.isNotEmpty) ...[
                      ..._events.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _EventBanner(event: e),
                      )),
                      const SizedBox(height: 8),
                    ],
                    ..._buildSections(),
                  ],
                ),
    );
  }

  List<Widget> _buildSections() {
    final widgets = <Widget>[];

    bool normalAdded = false;
    for (final tier in [1, 3, 5, 6]) {
      final list = _raids.where((r) => r.tier == tier && !r.isShadow).toList();
      if (list.isEmpty) continue;
      if (!normalAdded) {
        widgets.add(_SectionDivider(label: 'RAIDS', color: const Color(0xFF1565C0)));
        widgets.add(const SizedBox(height: 12));
        normalAdded = true;
      }
      widgets.add(_TierHeader(tier: tier, isShadow: false));
      widgets.add(const SizedBox(height: 10));
      widgets.add(_RaidGrid(bosses: list, onTap: _openDetail));
      widgets.add(const SizedBox(height: 20));
    }

    bool shadowAdded = false;
    for (final tier in [1, 3, 5, 6]) {
      final list = _raids.where((r) => r.tier == tier && r.isShadow).toList();
      if (list.isEmpty) continue;
      if (!shadowAdded) {
        widgets.add(_SectionDivider(label: 'SHADOW RAIDS', color: const Color(0xFF6A1FAB)));
        widgets.add(const SizedBox(height: 12));
        shadowAdded = true;
      }
      widgets.add(_TierHeader(tier: tier, isShadow: true));
      widgets.add(const SizedBox(height: 10));
      widgets.add(_RaidGrid(bosses: list, onTap: _openDetail));
      widgets.add(const SizedBox(height: 20));
    }

    return widgets;
  }
}

// ─── Modelos ──────────────────────────────────────────────────────

class _RaidBoss {
  final int     id;
  final String  name;
  final int     tier;
  final bool    isShadow;
  final bool    isMega;
  final bool    isRegional;
  final int     minCp;
  final int     maxCp;
  final int     minCpBoost;
  final int     maxCpBoost;
  final bool    shinyAvailable;
  final String? endsDate;

  const _RaidBoss({
    required this.id, required this.name, required this.tier,
    required this.isShadow, required this.isMega, required this.isRegional,
    required this.minCp, required this.maxCp,
    required this.minCpBoost, required this.maxCpBoost,
    required this.shinyAvailable, this.endsDate,
  });

  /// Nome de exibição — reconstrói "Shadow" / "Mega" de forma controlada
  String get displayName {
    var n = name;
    if (isMega)   n = 'Mega $n';
    if (isShadow) n = 'Shadow $n';
    return n;
  }
}

class _EventInfo {
  final String  name;
  final String? start;
  final String? end;
  const _EventInfo({required this.name, this.start, this.end});
}

// ─── Banner do evento ─────────────────────────────────────────────

class _EventBanner extends StatelessWidget {
  final _EventInfo event;
  const _EventBanner({required this.event});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(event.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        if (event.start != null || event.end != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            if (event.start != null)
              Text('Início: ${event.start}',
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            if (event.start != null && event.end != null)
              Text('  ·  ',
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            if (event.end != null)
              Text('Fim: ${event.end}',
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ]),
        ],
      ]),
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
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: c)),
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
        childAspectRatio: 0.62,
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
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final boss   = widget.boss;
    final scheme = Theme.of(context).colorScheme;
    final svc    = PokedexDataService.instance;
    final types  = svc.getTypes(boss.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color1 = types.isNotEmpty
        ? TypeColors.fromType(ptType(types[0])) : scheme.primary;
    final color2 = types.length > 1
        ? TypeColors.fromType(ptType(types[1])) : color1;
    final bgOp = isDark ? 0.15 : 0.10;

    return GestureDetector(
      onTap: _loading ? null : () async {
        setState(() => _loading = true);
        await widget.onTap(context, boss);
        if (mounted) setState(() => _loading = false);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: types.length > 1
                ? [color1.withOpacity(bgOp), color2.withOpacity(bgOp)]
                : [color1.withOpacity(bgOp), color1.withOpacity(bgOp * 0.5)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color1.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            // ── Conteúdo
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sprite
                  SizedBox(
                    height: 64,
                    child: _loading
                        ? Center(
                            child: SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: color1),
                            ),
                          )
                        : Image.asset(
                            'assets/sprites/artwork/${boss.id}.webp',
                            width: 64, height: 64, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => SizedBox(
                              width: 64, height: 64,
                              child: Icon(Icons.catching_pokemon,
                                  color: scheme.onSurfaceVariant.withOpacity(0.4),
                                  size: 36),
                            ),
                          ),
                  ),

                  const SizedBox(height: 5),

                  // Nome com prefixos (Shadow / Mega)
                  Text(
                    boss.displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
                  ),

                  const SizedBox(height: 5),

                  // Tipos com ícone PNG
                  if (types.isNotEmpty)
                    Wrap(
                      spacing: 3, runSpacing: 3,
                      alignment: WrapAlignment.center,
                      children: types.map((t) => _TypeBadge(type: t)).toList(),
                    ),

                  const SizedBox(height: 5),

                  // CP unboosted
                  if (boss.minCp > 0) ...[
                    Text(
                      'CP ${boss.minCp}–${boss.maxCp}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface),
                    ),
                    // CP boosted (ícone sol)
                    if (boss.minCpBoost > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wb_sunny_outlined,
                              size: 9, color: Color(0xFFF9A825)),
                          const SizedBox(width: 2),
                          Text(
                            '${boss.minCpBoost}–${boss.maxCpBoost}',
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFF9A825)),
                          ),
                        ],
                      ),
                  ],

                  // Data de fim
                  if (boss.endsDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Até ${_fmtDate(boss.endsDate!)}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 9, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),

            // ── Ícone shiny canto superior direito
            if (boss.shinyAvailable)
              Positioned(
                top: 4, right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      size: 12, color: Color(0xFFFFC107)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// "March 31, 2026, 8:00 PM" → "31/03"
  String _fmtDate(String raw) {
    const months = {
      'january': '01', 'february': '02', 'march': '03',    'april': '04',
      'may': '05',     'june': '06',     'july': '07',     'august': '08',
      'september': '09','october': '10', 'november': '11', 'december': '12',
    };
    final m = RegExp(r'([A-Za-z]+)\s+(\d{1,2})').firstMatch(raw);
    if (m == null) return raw;
    final mo  = months[m.group(1)!.toLowerCase()] ?? '??';
    final day = m.group(2)!.padLeft(2, '0');
    return '$day/$mo';
  }
}

// ─── Badge de tipo com ícone PNG ──────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/types/$type.png',
            width: 11, height: 11,
            errorBuilder: (_, __, ___) => const SizedBox(width: 11, height: 11),
          ),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

// ─── Estado vazio ─────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String   message;
  final VoidCallback onRetry;
  const _EmptyState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined,
                size: 64,
                color: Theme.of(context)
                    .colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
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
