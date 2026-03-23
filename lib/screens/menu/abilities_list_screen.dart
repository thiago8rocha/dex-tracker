import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pokedex_tracker/translations.dart';
import 'package:pokedex_tracker/screens/menu/ability_detail_screen.dart';

class AbilitiesListScreen extends StatefulWidget {
  const AbilitiesListScreen({super.key});
  @override State<AbilitiesListScreen> createState() => _AbilitiesListScreenState();
}

class _AbilitiesListScreenState extends State<AbilitiesListScreen> {
  List<_AbilityEntry> _all      = [];
  List<_AbilityEntry> _filtered = [];
  bool                _loading  = true;
  String              _search   = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/ability_map.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;

    final entries = map.entries.map((e) {
      final v    = e.value as Map<String, dynamic>;
      final main = (v['main'] as List<dynamic>).cast<int>();
      final hidden = (v['hidden'] as List<dynamic>).cast<int>();
      return _AbilityEntry(
        nameEn:      e.key,
        description: v['desc'] as String? ?? '',
        mainIds:     main,
        hiddenIds:   hidden,
      );
    }).toList()..sort((a, b) =>
        translateAbility(a.nameEn).compareTo(translateAbility(b.nameEn)));

    if (mounted) setState(() {
      _all      = entries;
      _filtered = entries;
      _loading  = false;
    });
  }

  void _applySearch(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _search   = q;
      _filtered = q.isEmpty ? _all : _all.where((a) {
        final pt = translateAbility(a.nameEn).toLowerCase();
        return a.nameEn.toLowerCase().contains(lower) || pt.contains(lower) ||
               a.description.toLowerCase().contains(lower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habilidades'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(children: [
        // Contador + busca
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            onChanged: _applySearch,
            decoration: InputDecoration(
              hintText: 'Buscar habilidade...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixText: '${_filtered.length}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: scheme.outlineVariant)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: scheme.outlineVariant)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
        ),

        // Lista
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(child: Text('Nenhuma habilidade encontrada',
                      style: TextStyle(color: scheme.onSurfaceVariant)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: scheme.outlineVariant.withOpacity(0.5)),
                      itemBuilder: (ctx, i) => _AbilityTile(
                        entry: _filtered[i],
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => AbilityDetailScreen(entry: _filtered[i]),
                        )),
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ─── Tile da lista ────────────────────────────────────────────────
class _AbilityTile extends StatelessWidget {
  final _AbilityEntry entry;
  final VoidCallback  onTap;
  const _AbilityTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final namePt  = translateAbility(entry.nameEn);
    final total   = entry.mainIds.length + entry.hiddenIds.length;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(namePt,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (entry.description.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(entry.description,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          )),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$total', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
            Text('pokémon', style: TextStyle(fontSize: 9,
                color: scheme.onSurfaceVariant.withOpacity(0.6))),
          ]),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 16,
              color: scheme.onSurfaceVariant.withOpacity(0.4)),
        ]),
      ),
    );
  }
}

// ─── Modelo público (partilhado com AbilityDetailScreen) ──────────
class AbilityEntry {
  final String      nameEn;
  final String      description;
  final List<int>   mainIds;
  final List<int>   hiddenIds;

  const AbilityEntry({
    required this.nameEn,
    required this.description,
    required this.mainIds,
    required this.hiddenIds,
  });
}

typedef _AbilityEntry = AbilityEntry;
