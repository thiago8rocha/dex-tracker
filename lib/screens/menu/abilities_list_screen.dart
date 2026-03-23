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
  bool                _searching = false;
  String              _search   = '';
  int?                _genFilter; // null = todas as gerações
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/ability_map.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;

    final entries = map.entries.map((e) {
      final v      = e.value as Map<String, dynamic>;
      final main   = (v['main']   as List<dynamic>).cast<int>();
      final hidden = (v['hidden'] as List<dynamic>).cast<int>();
      // Usar effect_short se disponível (script expandido), senão desc
      final desc = (v['effect_short'] as String?)?.isNotEmpty == true
          ? v['effect_short'] as String
          : v['desc'] as String? ?? '';
      return _AbilityEntry(
        nameEn:      e.key,
        description: desc,
        mainIds:     main,
        hiddenIds:   hidden,
        gen:         (v['gen'] as int?) ?? 1,
        effectLong:  v['effect_long'] as String? ?? '',
        flavor:      v['flavor']      as String? ?? '',
      );
    }).toList()
      ..sort((a, b) => translateAbility(a.nameEn).compareTo(translateAbility(b.nameEn)));

    if (mounted) setState(() { _all = entries; _applyFilters(); _loading = false; });
  }

  void _applyFilters() {
    var list = _all;
    if (_genFilter != null) {
      list = list.where((a) => a.gen == _genFilter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((a) {
        final pt = translateAbility(a.nameEn).toLowerCase();
        return a.nameEn.toLowerCase().contains(q) || pt.contains(q) ||
               a.description.toLowerCase().contains(q);
      }).toList();
    }
    _filtered = list;
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _search = '';
        _searchCtrl.clear();
        _applyFilters();
      }
    });
  }

  void _showGenFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _GenFilterSheet(
        selected: _genFilter,
        onSelect: (gen) {
          Navigator.pop(context);
          setState(() { _genFilter = gen; _applyFilters(); });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() { _search = v; _applyFilters(); }),
                decoration: const InputDecoration(
                  hintText: 'Buscar habilidade...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
              )
            : const Text('Habilidades'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          Badge(
            isLabelVisible: _genFilter != null,
            child: IconButton(
              icon: const Icon(Icons.filter_list_outlined),
              onPressed: _showGenFilter,
            ),
          ),
        ],
      ),
      body: Column(children: [
        // Chip de geração ativa
        if (_genFilter != null)
          Container(
            color: scheme.surfaceContainerLow,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(children: [
              Text('Geração $_genFilter',
                  style: TextStyle(fontSize: 12,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() { _genFilter = null; _applyFilters(); }),
                child: Icon(Icons.close, size: 14,
                    color: scheme.onSurfaceVariant),
              ),
            ]),
          ),

        // Contador
        if (!_searching)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              Text('${_filtered.length} habilidades',
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ]),
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
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: scheme.outlineVariant.withOpacity(0.5)),
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
    final scheme = Theme.of(context).colorScheme;
    final namePt = translateAbility(entry.nameEn);

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
                    style: TextStyle(fontSize: 12,
                        color: scheme.onSurfaceVariant, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          )),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 16,
              color: scheme.onSurfaceVariant.withOpacity(0.4)),
        ]),
      ),
    );
  }
}

// ─── Filtro de geração ────────────────────────────────────────────
class _GenFilterSheet extends StatelessWidget {
  final int?                 selected;
  final void Function(int?) onSelect;
  const _GenFilterSheet({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Filtrar por geração',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8,
          children: [
            _GenChip(label: 'Todas', value: null,
                selected: selected == null, onTap: () => onSelect(null)),
            for (int g = 1; g <= 9; g++)
              _GenChip(label: 'Gen $g', value: g,
                  selected: selected == g, onTap: () => onSelect(g)),
          ],
        ),
      ]),
    );
  }
}

class _GenChip extends StatelessWidget {
  final String label; final int? value;
  final bool selected; final VoidCallback onTap;
  const _GenChip({required this.label, required this.value,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1)),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurface)),
      ),
    );
  }
}

// ─── Modelo público ───────────────────────────────────────────────
class AbilityEntry {
  final String    nameEn;
  final String    description;
  final List<int> mainIds;
  final List<int> hiddenIds;
  final int       gen;
  final String    effectLong;
  final String    flavor;

  const AbilityEntry({
    required this.nameEn,
    required this.description,
    required this.mainIds,
    required this.hiddenIds,
    required this.gen,
    this.effectLong = '',
    this.flavor     = '',
  });
}

typedef _AbilityEntry = AbilityEntry;
