import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokedex_tracker/screens/detail/detail_shared.dart'
    show PokeballLoader, ptType;
import 'package:pokedex_tracker/services/pokedex_data_service.dart';
import 'package:pokedex_tracker/theme/type_colors.dart';

// PENDÊNCIA — Créditos/Fontes (registrado em 6.4 do doc de projeto):
// - Raids Ativas: dados via scraping de leekduck.com
//   LeekDuck é a fonte mais completa e atualizada para raids do Pokémon GO,
//   cobrindo shadow raids, nome do evento e datas de início/fim.
//   Quando a tela de Créditos for implementada, incluir LeekDuck como fonte.

class GoRaidsScreen extends StatefulWidget {
  const GoRaidsScreen({super.key});
  @override State<GoRaidsScreen> createState() => _GoRaidsScreenState();
}

class _GoRaidsScreenState extends State<GoRaidsScreen> {
  List<_RaidBoss> _raids      = [];
  _EventInfo?     _event;
  bool            _loading    = true;
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

      final html  = res.body;
      final raids = _parseRaids(html);
      final event = _parseEvent(html);

      if (raids.isEmpty) throw Exception('Sem dados');
      if (mounted) setState(() {
        _raids   = raids;
        _event   = event;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _error   = 'Não foi possível carregar as raids';
        _loading = false;
      });
    }
  }

  // ── Parser de raids ───────────────────────────────────────────────
  List<_RaidBoss> _parseRaids(String html) {
    final raids   = <_RaidBoss>[];
    final tierMap = {
      '1-Star Raids': 1, '3-Star Raids': 3,
      '5-Star Raids': 5, 'Mega Raids':   6,
    };

    final h2 = RegExp(
      r'<h2[^>]*>([\s\S]*?)<\/h2>([\s\S]*?)(?=<h2|$)',
      caseSensitive: false,
    );

    bool inShadow = false;

    for (final m in h2.allMatches(html)) {
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

      final bossRx = RegExp(
        r'<img[^>]+src="([^"]*(?:pm\d|poke_capture)[^"]*)"[^>]*>\s*'
        r'([\s\S]*?)(?=<img[^>]+src="[^"]*(?:pm\d|poke_capture)[^"]*"|$)',
        caseSensitive: false,
      );

      for (final bm in bossRx.allMatches(content)) {
        final img     = bm.group(1) ?? '';
        final chunk   = bm.group(2) ?? '';

        final pmId    = RegExp(r'pm(\d+)\.').firstMatch(img);
        final pokeId  = RegExp(r'poke_capture_(\d+)').firstMatch(img);
        final id      = int.tryParse(
            pmId?.group(1) ?? pokeId?.group(1) ?? '0') ?? 0;
        if (id == 0) continue;

        final nameM = RegExp(r'>([A-Za-zÀ-ú][^<\n]+?)<')
            .allMatches(chunk)
            .firstWhere(
              (x) => x.group(1)!.trim().isNotEmpty
                  && !x.group(1)!.contains('CP')
                  && !RegExp(r'^\d').hasMatch(x.group(1)!.trim()),
              orElse: () => RegExp(r'x').firstMatch('') as RegExpMatch,
            );
        var name = (nameM.group(1)?.trim() ?? '')
            .replaceFirst(RegExp(r'^Shadow\s+', caseSensitive: false), '');
        if (name.isEmpty) continue;

        final cpM  = RegExp(r'CP\s*([\d,]+)\s*-\s*([\d,]+)').firstMatch(chunk);
        final minCp = int.tryParse((cpM?.group(1) ?? '').replaceAll(',', '')) ?? 0;
        final maxCp = int.tryParse((cpM?.group(2) ?? '').replaceAll(',', '')) ?? 0;

        raids.add(_RaidBoss(
          id: id, name: name, tier: tier,
          isShadow: inShadow, minCp: minCp, maxCp: maxCp,
        ));
      }
    }
    return raids;
  }

  // ── Parser de evento atual ────────────────────────────────────────
  _EventInfo? _parseEvent(String html) {
    // LeekDuck exibe o evento no topo: nome + datas de início/fim
    final nameM = RegExp(
      r'<h[12][^>]*class="[^"]*event[^"]*"[^>]*>([\s\S]*?)<\/h[12]>',
      caseSensitive: false,
    ).firstMatch(html);

    final startM = RegExp(
      r'(?:start|starts?)[^:]*:\s*([A-Za-z]+ \d{1,2},?\s*\d{4}[^<\n]*)',
      caseSensitive: false,
    ).firstMatch(html);

    final endM = RegExp(
      r'(?:end|ends?)[^:]*:\s*([A-Za-z]+ \d{1,2},?\s*\d{4}[^<\n]*)',
      caseSensitive: false,
    ).firstMatch(html);

    final name  = nameM != null ? _strip(nameM.group(1) ?? '') : null;
    final start = startM?.group(1)?.trim();
    final end   = endM?.group(1)?.trim();

    if (name == null || name.isEmpty) return null;
    return _EventInfo(name: name, start: start, end: end);
  }

  String _strip(String s) => s.replaceAll(RegExp(r'<[^>]+>'), '').trim();

  // ── Build ─────────────────────────────────────────────────────────
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
                    if (_event != null) ...[
                      _EventBanner(event: _event!),
                      const SizedBox(height: 16),
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
        widgets.add(_SectionDivider(
            label: 'RAIDS', color: const Color(0xFF1565C0)));
        widgets.add(const SizedBox(height: 12));
        normalAdded = true;
      }
      widgets.add(_TierHeader(tier: tier, isShadow: false));
      widgets.add(const SizedBox(height: 10));
      widgets.add(_RaidGrid(bosses: list));
      widgets.add(const SizedBox(height: 20));
    }

    bool shadowAdded = false;
    for (final tier in [1, 3, 5, 6]) {
      final list = _raids.where((r) => r.tier == tier && r.isShadow).toList();
      if (list.isEmpty) continue;
      if (!shadowAdded) {
        widgets.add(_SectionDivider(
            label: 'SHADOW RAIDS', color: const Color(0xFF6A1FAB)));
        widgets.add(const SizedBox(height: 12));
        shadowAdded = true;
      }
      widgets.add(_TierHeader(tier: tier, isShadow: true));
      widgets.add(const SizedBox(height: 10));
      widgets.add(_RaidGrid(bosses: list));
      widgets.add(const SizedBox(height: 20));
    }

    return widgets;
  }
}

// ─── Modelos ──────────────────────────────────────────────────────

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
      child: Text(label, style: TextStyle(
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
        crossAxisCount:   3,
        crossAxisSpacing: 8,
        mainAxisSpacing:  8,
        childAspectRatio: 0.72,
      ),
      itemCount: bosses.length,
      itemBuilder: (_, i) => _RaidCard(boss: bosses[i]),
    );
  }
}

// ─── Card de pokémon ──────────────────────────────────────────────

class _RaidCard extends StatelessWidget {
  final _RaidBoss boss;
  const _RaidCard({required this.boss});

  @override
  Widget build(BuildContext context) {
    final scheme    = Theme.of(context).colorScheme;
    final svc       = PokedexDataService.instance;
    final types     = svc.getTypes(boss.id);
    final typeColor = types.isNotEmpty
        ? TypeColors.fromType(ptType(types[0]))
        : scheme.primary;
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? typeColor.withOpacity(0.12)
            : typeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: typeColor.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Image.asset(
            'assets/sprites/artwork/${boss.id}.webp',
            width: 64, height: 64, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => SizedBox(width: 64, height: 64,
              child: Icon(Icons.catching_pokemon,
                color: scheme.onSurfaceVariant.withOpacity(0.4), size: 36)),
          ),
          const SizedBox(height: 6),
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
          if (types.isNotEmpty)
            Wrap(
              spacing: 3, runSpacing: 3,
              alignment: WrapAlignment.center,
              children: types.map((t) => _TypePill(type: t)).toList(),
            ),
          const SizedBox(height: 5),
          if (boss.minCp > 0)
            Text('CP ${boss.minCp}–${boss.maxCp}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Pill de tipo compacto ────────────────────────────────────────

class _TypePill extends StatelessWidget {
  final String type;
  const _TypePill({required this.type});

  static const _names = {
    'normal': 'Normal', 'fire': 'Fogo', 'water': 'Água',
    'electric': 'Elétrico', 'grass': 'Planta', 'ice': 'Gelo',
    'fighting': 'Lutador', 'poison': 'Veneno', 'ground': 'Terreno',
    'flying': 'Voador', 'psychic': 'Psíquico', 'bug': 'Inseto',
    'rock': 'Pedra', 'ghost': 'Fantasma', 'dragon': 'Dragão',
    'dark': 'Sombrio', 'steel': 'Aço', 'fairy': 'Fada',
  };

  @override
  Widget build(BuildContext context) {
    final color = TypeColors.fromType(ptType(type));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(_names[type] ?? type,
        style: const TextStyle(
          fontSize: 8, fontWeight: FontWeight.w600, color: Colors.white)),
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
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: onRetry,
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6))),
        child: const Text('Tentar novamente')),
    ],
  ));
}
