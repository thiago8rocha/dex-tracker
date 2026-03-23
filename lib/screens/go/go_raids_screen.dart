import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GoRaidsScreen extends StatefulWidget {
  const GoRaidsScreen({super.key});
  @override State<GoRaidsScreen> createState() => _GoRaidsScreenState();
}

class _GoRaidsScreenState extends State<GoRaidsScreen> {
  List<_RaidBoss> _raids = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadRaids(); }

  Future<void> _loadRaids() async {
    try {
      final res = await http.get(
        Uri.parse('https://pokemon-go-api.github.io/pokemon-go-api/api/raidBoss.json'),
        headers: {'User-Agent': 'Mozilla/5.0 (Android; PokopiaTracker)'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data as Map).values.toList();
        final raids = <_RaidBoss>[];
        for (final item in list) {
          if (item is Map) {
            raids.add(_RaidBoss.fromJson(item as Map<String, dynamic>));
          }
        }
        // Ordenar por tier (5→1)
        raids.sort((a, b) => b.tier.compareTo(a.tier));
        if (mounted) setState(() { _raids = raids; _loading = false; });
      } else {
        if (mounted) setState(() { _error = 'Erro ao carregar raids'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Sem conexão'; _loading = false; });
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _raids.isEmpty
              ? _EmptyState(
                  message: _error ?? 'Nenhum evento ativo no momento',
                  onRetry: () { setState(() { _loading = true; _error = null; }); _loadRaids(); },
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final tier in [5, 4, 3, 2, 1, 6]) ...[
                      if (_raids.any((r) => r.tier == tier)) ...[
                        _TierHeader(tier: tier),
                        const SizedBox(height: 8),
                        ..._raids.where((r) => r.tier == tier).map(
                          (r) => _RaidTile(boss: r, scheme: scheme)),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ],
                ),
    );
  }
}

// ─── Modelos ──────────────────────────────────────────────────────

class _RaidBoss {
  final String name;
  final int    tier;
  final int    id;
  final bool   isMega;
  final bool   isShadow;

  _RaidBoss({required this.name, required this.tier, required this.id,
      required this.isMega, required this.isShadow});

  factory _RaidBoss.fromJson(Map<String, dynamic> j) {
    // A pokemon-go-api pode variar o formato — tratar os dois mais comuns
    final nameRaw = (j['pokemon_name'] ?? j['name'] ?? '') as String;
    final level   = j['level'] ?? j['raid_level'] ?? j['tier'] ?? 0;
    final tid     = (j['pokemon_id'] ?? j['id'] ?? 0) as int;
    int tier;
    if (level is String) {
      tier = int.tryParse(level.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    } else {
      tier = (level as num).toInt();
    }
    final isMega   = nameRaw.toLowerCase().contains('mega');
    final isShadow = nameRaw.toLowerCase().contains('shadow') ||
                     (j['type'] as String? ?? '').contains('shadow');
    return _RaidBoss(name: nameRaw, tier: tier, id: tid,
        isMega: isMega, isShadow: isShadow);
  }
}

// ─── Widgets ──────────────────────────────────────────────────────

class _TierHeader extends StatelessWidget {
  final int tier;
  const _TierHeader({required this.tier});

  static const Map<int, _TierMeta> _meta = {
    6: _TierMeta('Mega',     Color(0xFF9C27B0), 'Mega Raids'),
    5: _TierMeta('5★',       Color(0xFFE65100), 'Raids Lendários'),
    4: _TierMeta('4★',       Color(0xFF1565C0), 'Raids Difíceis'),
    3: _TierMeta('3★',       Color(0xFF2E7D32), 'Raids Normais'),
    2: _TierMeta('2★',       Color(0xFF795548), 'Raids Fáceis'),
    1: _TierMeta('1★',       Color(0xFF546E7A), 'Raids Iniciante'),
  };

  @override
  Widget build(BuildContext context) {
    final m = _meta[tier] ?? const _TierMeta('?', Color(0xFF888888), 'Raids');
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: m.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: m.color.withOpacity(0.4)),
        ),
        child: Text(m.label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: m.color)),
      ),
      const SizedBox(width: 8),
      Text(m.title, style: TextStyle(fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}

class _TierMeta {
  final String label; final Color color; final String title;
  const _TierMeta(this.label, this.color, this.title);
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
            width: 48, height: 48, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => SizedBox(
              width: 48, height: 48,
              child: Icon(Icons.catching_pokemon, color: scheme.onSurfaceVariant, size: 28)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(boss.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          if (boss.isMega || boss.isShadow)
            Row(children: [
              if (boss.isMega) _Badge('Mega', const Color(0xFF9C27B0)),
              if (boss.isShadow) _Badge('Shadow', const Color(0xFF7B1FA2)),
            ]),
        ])),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge(this.label, this.color);
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 4, top: 3),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
  );
}

class _EmptyState extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _EmptyState({required this.message, required this.onRetry});
  @override Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.event_busy_outlined, size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
      const SizedBox(height: 16),
      Text(message, style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 16),
      OutlinedButton(onPressed: onRetry,
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6))),
        child: const Text('Tentar novamente')),
    ],
  ));
}
