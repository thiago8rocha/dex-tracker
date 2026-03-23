import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GoRaidsScreen extends StatefulWidget {
  const GoRaidsScreen({super.key});
  @override State<GoRaidsScreen> createState() => _GoRaidsScreenState();
}

class _GoRaidsScreenState extends State<GoRaidsScreen> {
  List<_RaidBoss> _raids      = [];
  bool            _loading    = true;
  String?         _error;
  String?         _lastUpdate;

  @override
  void initState() { super.initState(); _loadRaids(); }

  Future<void> _loadRaids() async {
    setState(() { _loading = true; _error = null; });

    // Tenta pokemon-go-api primeiro (atualizado via game master)
    // Depois fallback para pogoapi.net
    final raids = await _tryPokemonGoApi() ?? await _tryPogoApi();

    if (mounted) {
      setState(() {
        _raids   = raids ?? [];
        _loading = false;
        if (raids == null) _error = 'Não foi possível carregar os raids';
      });
    }
  }

  // ── Fonte 1: pokemon-go-api.github.io ────────────────────────────
  // Formato: { "lvl1": [...], "lvl3": [...], "lvl5": [...], "mega": [...],
  //           "shadow_lvl1": [...], "shadow_lvl5": [...], "ultra_beast": [...] }
  // Cada boss: { "pokemon": { "id": "ZAMAZENTA", "names": {"English": "Zamazenta"},
  //              "primaryType": {"type": "FIGHTING"}, "pokemonId": 889 }, "shiny": true }
  Future<List<_RaidBoss>?> _tryPokemonGoApi() async {
    try {
      final res = await http.get(
        Uri.parse('https://pokemon-go-api.github.io/pokemon-go-api/api/raidBoss.json'),
        headers: {'User-Agent': 'Mozilla/5.0 (Android; PokopiaTracker)'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body);
      if (body is! Map) return null;

      // Verificar se tem campo de data
      if (body['generatedAt'] != null) {
        _lastUpdate = body['generatedAt'].toString().substring(0, 10);
      }

      final raids = <_RaidBoss>[];

      // Mapeamento de chave → tier numérico
      const keyMap = {
        'lvl1': 1, 'lvl3': 3, 'lvl5': 5,
        'mega': 6, 'mega_legendary': 6,
        'ultra_beast': 5,
        'shadow_lvl1': 1, 'shadow_lvl3': 3, 'shadow_lvl5': 5,
      };

      for (final entry in keyMap.entries) {
        final key      = entry.key;
        final tier     = entry.value;
        final isShadow = key.contains('shadow');
        final bossList = body[key] as List<dynamic>? ?? [];

        for (final b in bossList) {
          if (b is! Map) continue;
          final poke  = b['pokemon'] as Map<String, dynamic>?;
          if (poke == null) continue;

          final names  = poke['names'] as Map<String, dynamic>? ?? {};
          final name   = names['English'] as String?
              ?? poke['id']?.toString() ?? '';
          final pokeId = (poke['pokemonId'] as num?)?.toInt()
              ?? (poke['dexNr'] as num?)?.toInt() ?? 0;
          final shiny  = b['shiny'] as bool? ?? false;

          raids.add(_RaidBoss(
            id:           pokeId,
            name:         name,
            tier:         tier,
            isShadow:     isShadow,
            possibleShiny: shiny,
          ));
        }
      }

      if (raids.isNotEmpty) return raids;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Fonte 2: pogoapi.net (fallback) ──────────────────────────────
  // Formato: { "current": { "1": [...], "5": [...] } }
  // Cada boss: { "id": 532, "name": "Timburr", "tier": 1, "possible_shiny": true }
  Future<List<_RaidBoss>?> _tryPogoApi() async {
    try {
      final res = await http.get(
        Uri.parse('https://pogoapi.net/api/v1/raid_bosses.json'),
        headers: {'User-Agent': 'Mozilla/5.0 (Android; PokopiaTracker)'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;

      final body    = jsonDecode(res.body) as Map<String, dynamic>;
      final current = body['current'] as Map<String, dynamic>? ?? {};
      if (current.isEmpty) return null;

      final raids = <_RaidBoss>[];
      for (final tierKey in current.keys) {
        final tier   = int.tryParse(tierKey) ?? 0;
        final bosses = current[tierKey] as List<dynamic>? ?? [];
        for (final b in bosses) {
          if (b is! Map) continue;
          raids.add(_RaidBoss(
            id:            (b['id'] as num?)?.toInt() ?? 0,
            name:           b['name'] as String? ?? '',
            tier:           tier,
            isShadow:       false,
            possibleShiny:  b['possible_shiny'] as bool? ?? false,
            minCp:          (b['min_unboosted_cp'] as num?)?.toInt(),
            maxCp:          (b['max_unboosted_cp'] as num?)?.toInt(),
          ));
        }
      }
      return raids.isNotEmpty ? raids : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raids Ativos'),
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
          ? const Center(child: CircularProgressIndicator())
          : _raids.isEmpty
              ? _EmptyState(message: _error ?? 'Nenhum raid ativo', onRetry: _loadRaids)
              : Column(children: [
                  // Banner de atualização
                  if (_lastUpdate != null)
                    Container(
                      width: double.infinity,
                      color: scheme.surfaceContainerLow,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Text(
                        'Atualizado em $_lastUpdate · Fonte: pokemon-go-api',
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  Expanded(child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _buildSections(scheme),
                  )),
                ]),
    );
  }

  List<Widget> _buildSections(ColorScheme scheme) {
    final widgets = <Widget>[];
    // Mega/Lendário primeiro (6), depois 5 → 1
    for (final tier in [6, 5, 4, 3, 2, 1]) {
      // Regular
      final regular = _raids.where((r) => r.tier == tier && !r.isShadow).toList();
      if (regular.isNotEmpty) {
        widgets.add(_TierHeader(tier: tier, isShadow: false, count: regular.length));
        widgets.add(const SizedBox(height: 8));
        for (final b in regular) widgets.add(_RaidTile(boss: b, scheme: scheme));
        widgets.add(const SizedBox(height: 16));
      }
      // Shadow
      final shadow = _raids.where((r) => r.tier == tier && r.isShadow).toList();
      if (shadow.isNotEmpty) {
        widgets.add(_TierHeader(tier: tier, isShadow: true, count: shadow.length));
        widgets.add(const SizedBox(height: 8));
        for (final b in shadow) widgets.add(_RaidTile(boss: b, scheme: scheme));
        widgets.add(const SizedBox(height: 16));
      }
    }
    return widgets;
  }
}

// ─── Modelo ───────────────────────────────────────────────────────

class _RaidBoss {
  final int    id;
  final String name;
  final int    tier;
  final bool   isShadow;
  final bool   possibleShiny;
  final int?   minCp;
  final int?   maxCp;

  const _RaidBoss({
    required this.id, required this.name, required this.tier,
    required this.isShadow, required this.possibleShiny,
    this.minCp, this.maxCp,
  });
}

// ─── Widgets ──────────────────────────────────────────────────────

class _TierHeader extends StatelessWidget {
  final int  tier;
  final bool isShadow;
  final int  count;
  const _TierHeader({required this.tier, required this.isShadow, required this.count});

  static const _labels = {
    6: ('Mega / Primal',  Color(0xFF9C27B0)),
    5: ('5 Estrelas',     Color(0xFFE65100)),
    4: ('4 Estrelas',     Color(0xFF1565C0)),
    3: ('3 Estrelas',     Color(0xFF2E7D32)),
    2: ('2 Estrelas',     Color(0xFF795548)),
    1: ('1 Estrela',      Color(0xFF546E7A)),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _labels[tier] ?? ('Raid', const Color(0xFF888888));
    final shadowColor    = const Color(0xFF7B1FA2);
    final displayColor   = isShadow ? shadowColor : color;
    final displayLabel   = isShadow ? 'Shadow $label' : label;

    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: displayColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: displayColor.withOpacity(0.4)),
        ),
        child: Text(displayLabel, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: displayColor)),
      ),
      const SizedBox(width: 8),
      Text('$count boss${count > 1 ? 'es' : ''}',
          style: TextStyle(fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}

class _RaidTile extends StatelessWidget {
  final _RaidBoss   boss;
  final ColorScheme scheme;
  const _RaidTile({required this.boss, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            'assets/sprites/artwork/${boss.id}.webp',
            width: 52, height: 52, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => SizedBox(width: 52, height: 52,
              child: Icon(Icons.catching_pokemon,
                  color: scheme.onSurfaceVariant.withOpacity(0.4), size: 30)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(boss.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            if (boss.possibleShiny)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.star_rounded, color: Color(0xFFFFCC00), size: 16)),
            if (boss.isShadow)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1FA2).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Shadow',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: Color(0xFF7B1FA2))),
              ),
          ]),
          if (boss.minCp != null && boss.maxCp != null)
            Text('CP: ${boss.minCp} – ${boss.maxCp}',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ])),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _EmptyState({required this.message, required this.onRetry});
  @override Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.event_busy_outlined, size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
      const SizedBox(height: 16),
      Text(message,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 16),
      OutlinedButton(onPressed: onRetry,
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6))),
        child: const Text('Tentar novamente')),
    ],
  ));
}
