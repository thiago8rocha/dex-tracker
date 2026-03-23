import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      // Scraping do LeekDuck — fonte primária e sempre atualizada
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
        _error   = 'Não foi possível carregar os raids';
        _loading = false;
      });
    }
  }

  // ── Parser do HTML do LeekDuck ────────────────────────────────────
  // Estrutura: <h2>1-Star Raids</h2> ... <h2>3-Star Raids</h2> ...
  // Cada boss: nome vem como texto do próximo elemento após a imagem
  List<_RaidBoss> _parseLeekDuck(String html) {
    final raids = <_RaidBoss>[];

    // Encontrar seções por header
    // O padrão é: ## TIER Raids ... lista de pokémon ... ## próximo tier
    // Vamos usar regex para extrair os blocos de cada tier

    // Mapeamento de label do LeekDuck → tier interno
    final tierMap = <String, int>{
      '1-Star Raids':    1,
      '2-Star Raids':    2,
      '3-Star Raids':    3,
      '4-Star Raids':    4,
      '5-Star Raids':    5,
      'Mega Raids':      6,
    };

    // Dividir HTML em seções por header h2
    // Padrão: <h2...>LABEL</h2> (conteúdo) <h2>próximo</h2>
    final h2Pattern = RegExp(
      r'<h2[^>]*>([\s\S]*?)<\/h2>([\s\S]*?)(?=<h2|$)',
      caseSensitive: false,
    );

    bool inShadowSection = false;

    for (final match in h2Pattern.allMatches(html)) {
      final headerRaw = match.group(1) ?? '';
      final header    = _stripHtml(headerRaw).trim();
      final content   = match.group(2) ?? '';

      // Detectar seção Shadow
      if (header.toLowerCase().contains('shadow raid')) {
        inShadowSection = true;
        continue;
      }

      int? tier;
      for (final entry in tierMap.entries) {
        if (header.contains(entry.key)) {
          tier = entry.value;
          break;
        }
      }
      if (tier == null) continue;

      // Extrair pokémon desta seção
      // Cada item tem padrão: <img...> [nome] [tipos] [CP]
      // O nome vem em texto simples após a imagem do pokémon
      // Regex: extrai imagem (src com pm ou poke_capture) + texto seguinte
      final bossPattern = RegExp(
        r'<img[^>]+src="([^"]*(?:pm\d|poke_capture)[^"]*)"[^>]*>\s*'
        r'([\s\S]*?)(?=<img[^>]+src="[^"]*(?:pm\d|poke_capture)[^"]*"|$)',
        caseSensitive: false,
      );

      for (final bossMatch in bossPattern.allMatches(content)) {
        final imgSrc   = bossMatch.group(1) ?? '';
        final bossHtml = bossMatch.group(2) ?? '';

        // Extrair ID nacional da URL da imagem
        // Exemplos:
        // pm127.icon.png → 127
        // pm889.fHERO.icon.png → 889
        // pm80.fMEGA.icon.png → 80
        // poke_capture_0824_000... → 824
        final idFromPm   = RegExp(r'pm(\d+)\.').firstMatch(imgSrc);
        final idFromPoke = RegExp(r'poke_capture_(\d+)').firstMatch(imgSrc);
        final idStr      = idFromPm?.group(1) ?? idFromPoke?.group(1) ?? '0';
        final pokeId     = int.tryParse(idStr) ?? 0;

        // Extrair nome — primeiro texto não-vazio após a imagem
        final nameMatch = RegExp(r'>([A-Za-zÀ-ú][^<\n]+?)<')
            .allMatches(bossHtml)
            .firstWhere(
              (m) => m.group(1)!.trim().isNotEmpty
                  && !m.group(1)!.contains('CP')
                  && !RegExp(r'^\d').hasMatch(m.group(1)!.trim()),
              orElse: () => RegExp(r'x').firstMatch('') as RegExpMatch,
            );
        final name = nameMatch.group(1)?.trim() ?? '';
        if (name.isEmpty || pokeId == 0) continue;

        // Extrair range de CP (sem boost)
        final cpMatch = RegExp(r'CP\s*([\d,]+)\s*-\s*([\d,]+)')
            .firstMatch(bossHtml);
        final minCp = int.tryParse(
            (cpMatch?.group(1) ?? '').replaceAll(',', '')) ?? 0;
        final maxCp = int.tryParse(
            (cpMatch?.group(2) ?? '').replaceAll(',', '')) ?? 0;

        raids.add(_RaidBoss(
          id:       pokeId,
          name:     name,
          tier:     tier,
          isShadow: inShadowSection,
          minCp:    minCp,
          maxCp:    maxCp,
        ));
      }
    }

    return raids;
  }

  String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]+>'), '').trim();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raids Ativos'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _loadRaids),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _raids.isEmpty
              ? _EmptyState(
                  message: _error ?? 'Nenhum raid ativo no momento',
                  onRetry: _loadRaids)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ..._buildSections(scheme),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Fonte: LeekDuck.com',
                        style: TextStyle(fontSize: 10,
                            color: scheme.onSurfaceVariant.withOpacity(0.5)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
    );
  }

  List<Widget> _buildSections(ColorScheme scheme) {
    final widgets = <Widget>[];
    for (final tier in [6, 5, 4, 3, 2, 1]) {
      for (final shadow in [false, true]) {
        final list = _raids
            .where((r) => r.tier == tier && r.isShadow == shadow)
            .toList();
        if (list.isEmpty) continue;
        widgets.add(_TierHeader(tier: tier, isShadow: shadow, count: list.length));
        widgets.add(const SizedBox(height: 8));
        for (final b in list) widgets.add(_RaidTile(boss: b, scheme: scheme));
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
  final int    minCp;
  final int    maxCp;

  const _RaidBoss({
    required this.id, required this.name, required this.tier,
    required this.isShadow, required this.minCp, required this.maxCp,
  });
}

// ─── Widgets ──────────────────────────────────────────────────────

class _TierHeader extends StatelessWidget {
  final int tier; final bool isShadow; final int count;
  const _TierHeader({required this.tier, required this.isShadow, required this.count});

  static const _meta = {
    6: ('Mega / Primal', Color(0xFF9C27B0)),
    5: ('5 Estrelas',    Color(0xFFE65100)),
    4: ('4 Estrelas',    Color(0xFF1565C0)),
    3: ('3 Estrelas',    Color(0xFF2E7D32)),
    2: ('2 Estrelas',    Color(0xFF795548)),
    1: ('1 Estrela',     Color(0xFF546E7A)),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _meta[tier] ?? ('Raid', const Color(0xFF888888));
    final c   = isShadow ? const Color(0xFF6A1FAB) : color;
    final lbl = isShadow ? 'Shadow $label' : label;
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.4)),
        ),
        child: Text(lbl, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: c)),
      ),
      const SizedBox(width: 8),
      Text('$count boss${count > 1 ? 'es' : ''}',
          style: TextStyle(fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}

class _RaidTile extends StatelessWidget {
  final _RaidBoss boss; final ColorScheme scheme;
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
        Image.asset(
          'assets/sprites/artwork/${boss.id}.webp',
          width: 52, height: 52, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => SizedBox(width: 52, height: 52,
            child: Icon(Icons.catching_pokemon,
                color: scheme.onSurfaceVariant.withOpacity(0.4), size: 30)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(boss.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            if (boss.isShadow)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1FAB).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Shadow',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: Color(0xFF6A1FAB))),
              ),
          ]),
          if (boss.minCp > 0)
            Text('CP: ${boss.minCp} – ${boss.maxCp}',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ])),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _EmptyState({required this.message, required this.onRetry});
  @override Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.event_busy_outlined, size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
      const SizedBox(height: 16),
      Text(message, textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 16),
      OutlinedButton(onPressed: onRetry,
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6))),
        child: const Text('Tentar novamente')),
    ],
  ));
}
