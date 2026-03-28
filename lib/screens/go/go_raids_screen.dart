import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokedex_tracker/screens/detail/detail_shared.dart'
    show PokeballLoader, TypeBadge, ptType;
import 'package:pokedex_tracker/services/pokedex_data_service.dart';
import 'package:pokedex_tracker/theme/type_colors.dart';

class GoRaidsScreen extends StatefulWidget {
  const GoRaidsScreen({super.key});
  @override State<GoRaidsScreen> createState() => _GoRaidsScreenState();
}

class _GoRaidsScreenState extends State<GoRaidsScreen> {
  List<_RaidBoss> _raids   = [];
  bool            _loading = true;
  String?         _error;

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
      final raids = _parseLeekDuck(res.body);
      if (raids.isEmpty) throw Exception('Sem dados');
      if (mounted) setState(() { _raids = raids; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error   = 'Não foi possível carregar as raids';
        _loading = false;
      });
    }
  }

  List<_RaidBoss> _parseLeekDuck(String html) {
    final raids = <_RaidBoss>[];
    final tierMap = <String, int>{
      '1-Star Raids': 1,
      '3-Star Raids': 3,
      '5-Star Raids': 5,
      'Mega Raids':   6,
    };

    final h2Pattern = RegExp(
      r'<h2[^>]*>([\s\S]*?)<\/h2>([\s\S]*?)(?=<h2|$)',
      caseSensitive: false,
    );

    bool inShadow = false;

    for (final match in h2Pattern.allMatches(html)) {
      final header  = _strip(match.group(1) ?? '').trim();
      final content = match.group(2) ?? '';

      if (header.toLowerCase().contains('shadow raid')) {
        inShadow = true;
        continue;
      }

      int? tier;
      for (final e in tierMap.entries) {
        if (header.contains(e.key)) { tier = e.value; break; }
      }
      if (tier == null) continue;

      final bossPattern = RegExp(
        r'<img[^>]+src="([^"]*(?:pm\d|poke_capture)[^"]*)"[^>]*>\s*'
        r'([\s\S]*?)(?=<img[^>]+src="[^"]*(?:pm\d|poke_capture)[^"]*"|$)',
        caseSensitive: false,
      );

      for (final bm in bossPattern.allMatches(content)) {
        final imgSrc   = bm.group(1) ?? '';
        final bossHtml = bm.group(2) ?? '';

        final idFromPm   = RegExp(r'pm(\d+)\.').firstMatch(imgSrc);
        final idFromPoke = RegExp(r'poke_capture_(\d+)').firstMatch(imgSrc);
        final idStr      = idFromPm?.group(1) ?? idFromPoke?.group(1) ?? '0';
        final pokeId     = int.tryParse(idStr) ?? 0;

        final nameMatch = RegExp(r'>([A-Za-zÀ-ú][^<\n]+?)<')
            .allMatches(bossHtml)
            .firstWhere(
              (m) => m.group(1)!.trim().isNotEmpty
                  && !m.group(1)!.contains('CP')
                  && !RegExp(r'^\d').hasMatch(m.group(1)!.trim()),
              orElse: () => RegExp(r'x').firstMatch('') as RegExpMatch,
            );
        // Remover "Shadow " do nome — a coluna já indica isso
        var name = (nameMatch.group(1)?.trim() ?? '')
            .replaceFirst(RegExp(r'^Shadow\s+', caseSensitive: false), '');
        if (name.isEmpty || pokeId == 0) continue;

        final cpMatch = RegExp(r'CP\s*([\d,]+)\s*-\s*([\d,]+)')
            .firstMatch(bossHtml);
        final minCp = int.tryParse(
            (cpMatch?.group(1) ?? '').replaceAll(',', '')) ?? 0;
        final maxCp = int.tryParse(
            (cpMatch?.group(2) ?? '').replaceAll(',', '')) ?? 0;

        raids.add(_RaidBoss(
          id: pokeId, name: name, tier: tier,
          isShadow: inShadow, minCp: minCp, maxCp: maxCp,
        ));
      }
    }
    return raids;
  }

  String _strip(String html) =>
      html.replaceAll(RegExp(r'<[^>]+>'), '').trim();

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
              onPressed: _loadRaids),
        ],
      ),
      body: _loading
          ? Center(child: PokeballLoader())
          : _raids.isEmpty
              ? _EmptyState(
                  message: _error ?? 'Nenhum raid ativo no momento',
                  onRetry: _loadRaids)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    ..._buildSections(),
                    const SizedBox(height: 8),
                    Text('Fonte: LeekDuck.com',
                      style: TextStyle(fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme.onSurfaceVariant
                            .withOpacity(0.5)),
                      textAlign: TextAlign.center),
                  ],
                ),
    );
  }

  List<Widget> _buildSections() {
    final widgets = <Widget>[];

    // Raids normais: 1★ → 3★ → 5★ → Mega
    bool normalHeaderAdded = false;
    for (final tier in [1, 3, 5, 6]) {
      final list = _raids.where((r) => r.tier == tier && !r.isShadow).toList();
      if (list.isEmpty) continue;
      if (!normalHeaderAdded) {
        widgets.add(_SectionDivider(label: 'RAIDS', color: const Color(0xFF1565C0)));
        widgets.add(const SizedBox(height: 12));
        normalHeaderAdded = true;
      }
      widgets.add(_TierHeader(tier: tier, isShadow: false));
      widgets.add(const SizedBox(height: 10));
      widgets.add(_RaidGrid(bosses: list));
      widgets.add(const SizedBox(height: 20));
    }

    // Shadow raids: 1★ → 3★ → 5★ → Mega
    bool shadowHeaderAdded = false;
    for (final tier in [1, 3, 5, 6]) {
      final list = _raids.where((r) => r.tier == tier && r.isShadow).toList();
      if (list.isEmpty) continue;
      if (!shadowHeaderAdded) {
        widgets.add(_SectionDivider(
            label: 'SHADOW RAIDS', color: const Color(0xFF6A1FAB)));
        widgets.add(const SizedBox(height: 12));
        shadowHeaderAdded = true;
      }
      widgets.add(_TierHeader(tier: tier, isShadow: true));
      widgets.add(const SizedBox(height: 10));
      widgets.add(_RaidGrid(bosses: list));
      widgets.add(const SizedBox(height: 20));
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
  final int    minCp;
  final int    maxCp;
  const _RaidBoss({
    required this.id, required this.name, required this.tier,
    required this.isShadow, required this.minCp, required this.maxCp,
  });
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
        child: Text(label,
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            letterSpacing: 1.2, color: color)),
      ),
      Expanded(child: Divider(color: color.withOpacity(0.3), thickness: 1)),
    ]);
  }
}

// ─── Header de tier ───────────────────────────────────────────────

class _TierHeader extends StatelessWidget {
  final int tier; final bool isShadow;
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
  const _RaidGrid({required this.bosses});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: bosses.length,
      itemBuilder: (context, i) => _RaidCard(boss: bosses[i]),
    );
  }
}

// ─── Card de pokémon ──────────────────────────────────────────────

class _RaidCard extends StatelessWidget {
  final _RaidBoss boss;
  const _RaidCard({required this.boss});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final svc    = PokedexDataService.instance;
    final types  = svc.getTypes(boss.id);

    // Cor de fundo baseada no tipo primário
    final typeColor = types.isNotEmpty
        ? TypeColors.fromType(ptType(types[0]))
        : scheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? typeColor.withOpacity(0.12)
        : typeColor.withOpacity(0.08);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: typeColor.withOpacity(0.25), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          // Sprite
          Image.asset(
            'assets/sprites/artwork/${boss.id}.webp',
            width: 64, height: 64, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => SizedBox(
              width: 64, height: 64,
              child: Icon(Icons.catching_pokemon,
                color: scheme.onSurfaceVariant.withOpacity(0.4), size: 36)),
          ),
          const SizedBox(height: 6),
          // Nome
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(boss.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, height: 1.2)),
          ),
          const SizedBox(height: 5),
          // Tipos
          if (types.isNotEmpty)
            Wrap(
              spacing: 3, runSpacing: 3,
              alignment: WrapAlignment.center,
              children: types.map((t) => _TypePill(type: t)).toList(),
            ),
          const SizedBox(height: 5),
          // CP range
          if (boss.minCp > 0)
            Text(
              'CP ${boss.minCp}–${boss.maxCp}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Pill de tipo (compacto para o card) ──────────────────────────

class _TypePill extends StatelessWidget {
  final String type;
  const _TypePill({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = TypeColors.fromType(ptType(type));
    final nameMap = const {
      'normal': 'Normal', 'fire': 'Fogo', 'water': 'Água',
      'electric': 'Elétrico', 'grass': 'Planta', 'ice': 'Gelo',
      'fighting': 'Lutador', 'poison': 'Veneno', 'ground': 'Terreno',
      'flying': 'Voador', 'psychic': 'Psíquico', 'bug': 'Inseto',
      'rock': 'Pedra', 'ghost': 'Fantasma', 'dragon': 'Dragão',
      'dark': 'Sombrio', 'steel': 'Aço', 'fairy': 'Fada',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(nameMap[type] ?? type,
        style: const TextStyle(
          fontSize: 8, fontWeight: FontWeight.w600,
          color: Colors.white)),
    );
  }
}

// ─── Estado vazio ─────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _EmptyState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.event_busy_outlined, size: 64,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
      const SizedBox(height: 16),
      Text(message, textAlign: TextAlign.center,
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: onRetry,
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6))),
        child: const Text('Tentar novamente')),
    ],
  ));
}
