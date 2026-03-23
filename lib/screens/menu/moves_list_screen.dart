import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokedex_tracker/theme/type_colors.dart';
import 'package:pokedex_tracker/screens/detail/detail_shared.dart'
    show ptType, typeIconAsset, typeTextColor, neutralBg, kApiBase;
import 'package:pokedex_tracker/services/storage_service.dart';
import 'package:pokedex_tracker/services/pokeapi_service.dart';
import 'package:pokedex_tracker/services/dex_bundle_service.dart';
import 'package:pokedex_tracker/translations.dart';
import 'package:pokedex_tracker/screens/menu/move_detail_screen.dart';

// ─── Modelo público (partilhado com move_detail_screen) ───────────
class MoveEntry {
  final String nameEn;
  final String url;
  String typeEn   = '';
  String category = '';
  int?   power;
  int?   accuracy;
  int?   pp;
  MoveEntry({required this.nameEn, required this.url});
}

// ─── Lista de jogos para seletor ─────────────────────────────────
class _GameDef {
  final String id;
  final String label;
  const _GameDef({required this.id, required this.label});
}

const _kGames = [
  _GameDef(id: 'scarlet___violet',              label: 'Scarlet / Violet'),
  _GameDef(id: 'sword___shield',                label: 'Sword / Shield'),
  _GameDef(id: 'legends_arceus',                label: 'Legends: Arceus'),
  _GameDef(id: 'brilliant_diamond___shining_pearl', label: 'BD / Shining Pearl'),
  _GameDef(id: 'ultra_sun___ultra_moon',        label: 'Ultra Sun / Ultra Moon'),
  _GameDef(id: 'sun___moon',                    label: 'Sun / Moon'),
  _GameDef(id: 'lets_go_pikachu___eevee',       label: "Let's Go Pikachu / Eevee"),
  _GameDef(id: 'black_2___white_2',             label: 'Black 2 / White 2'),
  _GameDef(id: 'black___white',                 label: 'Black / White'),
  _GameDef(id: 'heartgold___soulsilver',        label: 'HeartGold / SoulSilver'),
  _GameDef(id: 'platinum',                      label: 'Platinum'),
  _GameDef(id: 'diamond___pearl',               label: 'Diamond / Pearl'),
  _GameDef(id: 'omega_ruby___alpha_sapphire',   label: 'Omega Ruby / Alpha Sapphire'),
  _GameDef(id: 'emerald',                       label: 'Emerald'),
  _GameDef(id: 'ruby___sapphire',               label: 'Ruby / Sapphire'),
  _GameDef(id: 'firered___leafgreen_(gba)',      label: 'FireRed / LeafGreen'),
  _GameDef(id: 'x___y',                         label: 'X / Y'),
  _GameDef(id: 'crystal',                       label: 'Crystal'),
  _GameDef(id: 'gold___silver',                 label: 'Gold / Silver'),
  _GameDef(id: 'yellow',                        label: 'Yellow'),
  _GameDef(id: 'red___blue',                    label: 'Red / Blue'),
  _GameDef(id: 'nacional',                      label: 'Nacional'),
];

// ─── Tela principal ───────────────────────────────────────────────
class MovesListScreen extends StatefulWidget {
  const MovesListScreen({super.key});
  @override State<MovesListScreen> createState() => _MovesListScreenState();
}

class _MovesListScreenState extends State<MovesListScreen> {
  List<MoveEntry> _allMoves  = [];
  List<MoveEntry> _filtered  = [];
  bool            _loading   = true;
  String          _search    = '';
  String?         _typeFilter;
  String?         _catFilter;
  String          _activeGameId    = 'scarlet___violet';
  String          _activeGameLabel = 'Scarlet / Violet';

  // Cache compartilhado passado para a tela de detalhe
  final Map<String, Map<String, dynamic>> _detailCache = {};

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    final lastDex = await StorageService().getLastPokedexId();
    if (lastDex != null &&
        !lastDex.startsWith('pokopia') &&
        lastDex != 'pokémon_go') {
      final game = _kGames.firstWhere(
          (g) => g.id == lastDex,
          orElse: () => _kGames.first);
      _activeGameId    = game.id;
      _activeGameLabel = game.label;
    }
    _loadMoves();
  }

  Future<void> _loadMoves() async {
    setState(() { _loading = true; _allMoves = []; _filtered = []; });

    final sections = PokeApiService.pokedexSections[_activeGameId] ?? [];
    final allIds   = <int>{};
    for (final s in sections) {
      final entries = await DexBundleService.instance.loadSection(s.apiName);
      if (entries != null) {
        for (final e in entries) allIds.add(e['speciesId']!);
      }
    }
    if (allIds.isEmpty && _activeGameId == 'nacional') {
      for (int i = 1; i <= 1025; i++) allIds.add(i);
    }

    // Coletar moves de todos os pokémon do jogo
    final moveMap = <String, MoveEntry>{};
    final ids     = allIds.toList()..sort();

    // Lotes de 15 em paralelo
    for (int i = 0; i < ids.length; i += 15) {
      if (!mounted) return;
      final batch = ids.skip(i).take(15).toList();
      await Future.wait(batch.map((id) => _fetchPokemonMoves(id, moveMap)));
      if (mounted) setState(() {
        _allMoves = moveMap.values.toList()
          ..sort((a, b) {
            final ptA = translateMove(a.nameEn);
            final ptB = translateMove(b.nameEn);
            return ptA.compareTo(ptB);
          });
        _applyFilters();
        _loading = false;
      });
    }

    // Após ter a lista completa, pré-carregar os detalhes (tipo/categoria)
    // em background para preencher os cards
    _prefetchDetails(moveMap.values.toList());
  }

  Future<void> _fetchPokemonMoves(int id, Map<String, MoveEntry> map) async {
    try {
      final res = await http.get(Uri.parse('$kApiBase/pokemon/$id'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final data  = jsonDecode(res.body) as Map<String, dynamic>;
      final moves = data['moves'] as List<dynamic>? ?? [];
      for (final m in moves) {
        final nameEn = m['move']['name'] as String;
        final url    = m['move']['url'] as String;
        if (!map.containsKey(nameEn)) map[nameEn] = MoveEntry(nameEn: nameEn, url: url);
      }
    } catch (_) {}
  }

  // Pré-carrega detalhes dos moves em batches — preenche tipo/cat/poder
  Future<void> _prefetchDetails(List<MoveEntry> moves) async {
    final uncached = moves.where((m) => m.typeEn.isEmpty).toList();
    for (int i = 0; i < uncached.length; i += 20) {
      if (!mounted) return;
      final batch = uncached.skip(i).take(20).toList();
      await Future.wait(batch.map((m) => _loadDetail(m.url)));
      if (mounted) setState(() {}); // re-render com dados novos
    }
  }

  Future<Map<String, dynamic>?> _loadDetail(String url) async {
    if (_detailCache.containsKey(url)) {
      _applyDetailToEntries(url, _detailCache[url]!);
      return _detailCache[url];
    }
    try {
      final res = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        _detailCache[url] = d;
        _applyDetailToEntries(url, d);
        return d;
      }
    } catch (_) {}
    return null;
  }

  void _applyDetailToEntries(String url, Map<String, dynamic> d) {
    for (final e in _allMoves) {
      if (e.url == url) {
        e.typeEn   = d['type']?['name'] as String? ?? '';
        e.category = d['damage_class']?['name'] as String? ?? '';
        e.power    = d['power'] as int?;
        e.accuracy = d['accuracy'] as int?;
        e.pp       = d['pp'] as int?;
      }
    }
  }

  void _applyFilters() {
    var list = _allMoves;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((m) {
        final pt = translateMove(m.nameEn).toLowerCase();
        return m.nameEn.toLowerCase().contains(q) || pt.contains(q);
      }).toList();
    }
    if (_typeFilter != null) list = list.where((m) => m.typeEn == _typeFilter).toList();
    if (_catFilter  != null) list = list.where((m) => m.category == _catFilter).toList();
    _filtered = list;
  }

  void _changeGame(_GameDef game) {
    setState(() {
      _activeGameId    = game.id;
      _activeGameLabel = game.label;
      _typeFilter = null;
      _catFilter  = null;
      _search     = '';
    });
    _loadMoves();
  }

  void _showGamePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _GamePickerSheet(
        selected: _activeGameId,
        onSelect: (g) { Navigator.pop(context); _changeGame(g); },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _FilterSheet(
        selectedType: _typeFilter,
        selectedCat:  _catFilter,
        onApply: (type, cat) => setState(() {
          _typeFilter = type;
          _catFilter  = cat;
          _applyFilters();
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme    = Theme.of(context).colorScheme;
    final hasFilter = _typeFilter != null || _catFilter != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Golpes'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Badge(isLabelVisible: hasFilter,
                child: const Icon(Icons.filter_list_outlined)),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(children: [
        // Seletor de jogo
        InkWell(
          onTap: _showGamePicker,
          child: Container(
            color: scheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Icon(Icons.videogame_asset_outlined,
                  size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(_activeGameLabel,
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant)),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 14, color: scheme.onSurfaceVariant),
              const Spacer(),
              Text('${_filtered.length} golpes',
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ]),
          ),
        ),

        // Busca
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            onChanged: (v) => setState(() { _search = v; _applyFilters(); }),
            decoration: InputDecoration(
              hintText: 'Buscar golpe...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: scheme.outlineVariant)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: scheme.outlineVariant)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
        ),

        // Chips de filtro ativos
        if (hasFilter)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(children: [
              if (_typeFilter != null) _ActiveChip(
                label: ptType(_typeFilter!),
                onRemove: () => setState(() { _typeFilter = null; _applyFilters(); }),
              ),
              if (_catFilter != null) ...[
                const SizedBox(width: 6),
                _ActiveChip(
                  label: _catFilter == 'physical' ? 'Físico'
                      : _catFilter == 'special' ? 'Especial' : 'Status',
                  onRemove: () => setState(() { _catFilter = null; _applyFilters(); }),
                ),
              ],
            ]),
          ),

        // Lista
        Expanded(
          child: _loading && _filtered.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(child: Text('Nenhum golpe encontrado',
                      style: TextStyle(color: scheme.onSurfaceVariant)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) => _MoveCard(
                        entry: _filtered[i],
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => MoveDetailScreen(
                            entry:        _filtered[i],
                            activeGameId: _activeGameId,
                            detailCache:  _detailCache,
                            loadDetail:   _loadDetail,
                          ),
                        )),
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ─── Card de golpe ────────────────────────────────────────────────
class _MoveCard extends StatelessWidget {
  final MoveEntry    entry;
  final VoidCallback onTap;
  const _MoveCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme   = Theme.of(context).colorScheme;
    final namePt   = translateMove(entry.nameEn);
    final typeEn   = entry.typeEn;
    final typePt   = typeEn.isNotEmpty ? ptType(typeEn) : '';
    final typeColor = typeEn.isNotEmpty
        ? TypeColors.fromType(typePt) : scheme.surfaceContainerHighest;
    final catName  = entry.category;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: scheme.outlineVariant, width: 0.5),
        ),
        child: Column(children: [
          // Linha superior: nome + stats
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 6),
            child: Row(children: [
              Expanded(child: Text(namePt,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
              _Stat('POD',  entry.power    != null ? '${entry.power}'    : '—'),
              const SizedBox(width: 10),
              _Stat('PREC', entry.accuracy != null ? '${entry.accuracy}%': '—'),
              const SizedBox(width: 10),
              _Stat('PP',   entry.pp       != null ? '${entry.pp}'       : '—'),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 14,
                  color: scheme.onSurfaceVariant.withOpacity(0.4)),
            ]),
          ),
          // Linha inferior: tipo + categoria
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(children: [
              if (typeEn.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor, borderRadius: BorderRadius.circular(4)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset(typeIconAsset(typeEn), width: 11, height: 11,
                        errorBuilder: (_, __, ___) => const SizedBox()),
                    const SizedBox(width: 4),
                    Text(typePt, style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: typeTextColor(typeColor))),
                  ]),
                )
              else
                Container(width: 52, height: 20,
                    decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 8),
              if (catName.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/categories/$catName.png', width: 16, height: 16,
                    errorBuilder: (_, __, ___) => const SizedBox()),
                const SizedBox(width: 4),
                Text(catName == 'physical' ? 'Físico'
                    : catName == 'special' ? 'Especial' : 'Status',
                    style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat(this.label, this.value);
  @override Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      Text(label, style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
    ]);
  }
}

class _ActiveChip extends StatelessWidget {
  final String label; final VoidCallback onRemove;
  const _ActiveChip({required this.label, required this.onRemove});
  @override Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 11, color: scheme.onPrimaryContainer)),
        const SizedBox(width: 4),
        GestureDetector(onTap: onRemove,
          child: Icon(Icons.close, size: 13, color: scheme.onPrimaryContainer)),
      ]),
    );
  }
}

// ─── Sheet: seletor de jogo ───────────────────────────────────────
class _GamePickerSheet extends StatelessWidget {
  final String selected;
  final void Function(_GameDef) onSelect;
  const _GamePickerSheet({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text('Selecionar jogo',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      ),
      const Divider(height: 1),
      Flexible(child: ListView.builder(
        shrinkWrap: true,
        itemCount: _kGames.length,
        itemBuilder: (_, i) {
          final g = _kGames[i];
          return ListTile(
            dense: true,
            title: Text(g.label, style: const TextStyle(fontSize: 13)),
            trailing: g.id == selected
                ? Icon(Icons.check, color: scheme.primary, size: 18)
                : null,
            onTap: () => onSelect(g),
          );
        },
      )),
      const SizedBox(height: 16),
    ]);
  }
}

// ─── Sheet: filtros ───────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final String? selectedType, selectedCat;
  final void Function(String? type, String? cat) onApply;
  const _FilterSheet({required this.selectedType, required this.selectedCat,
      required this.onApply});
  @override State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _type, _cat;
  static const _types = [
    'normal','fighting','flying','poison','ground','rock',
    'bug','ghost','steel','fire','water','grass',
    'electric','psychic','ice','dragon','dark','fairy',
  ];

  @override void initState() { super.initState(); _type = widget.selectedType; _cat = widget.selectedCat; }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Filtrar golpes',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton(
              onPressed: () => setState(() { _type = null; _cat = null; }),
              child: const Text('Limpar')),
        ]),
        const SizedBox(height: 10),
        Text('TIPO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: _types.map((t) {
          final sel = _type == t;
          final tc  = TypeColors.fromType(ptType(t));
          return GestureDetector(
            onTap: () => setState(() => _type = sel ? null : t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? tc : tc.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: sel ? tc : tc.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset(typeIconAsset(t), width: 11, height: 11,
                    errorBuilder: (_, __, ___) => const SizedBox()),
                const SizedBox(width: 4),
                Text(ptType(t), style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: sel ? typeTextColor(tc) : tc)),
              ]),
            ),
          );
        }).toList()),
        const SizedBox(height: 14),
        Text('CATEGORIA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Row(children: [
          for (final cat in ['physical', 'special', 'status']) ...[
            _CatBtn(cat: cat, sel: _cat == cat,
                onTap: () => setState(() => _cat = _cat == cat ? null : cat)),
            const SizedBox(width: 8),
          ],
        ]),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity,
          child: OutlinedButton(
            onPressed: () { Navigator.pop(context); widget.onApply(_type, _cat); },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              side: BorderSide(color: scheme.primary, width: 2)),
            child: const Text('Aplicar'),
          )),
      ]),
    );
  }
}

class _CatBtn extends StatelessWidget {
  final String cat; final bool sel; final VoidCallback onTap;
  const _CatBtn({required this.cat, required this.sel, required this.onTap});
  static const _c = {'physical': Color(0xFFE24B4A), 'special': Color(0xFF9C27B0), 'status': Color(0xFF888888)};
  static const _l = {'physical': 'Físico', 'special': 'Especial', 'status': 'Status'};
  @override Widget build(BuildContext context) {
    final color = _c[cat]!;
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: sel ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: sel ? color
            : Theme.of(context).colorScheme.outlineVariant, width: sel ? 2 : 1)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset('assets/categories/$cat.png', width: 15, height: 15,
            errorBuilder: (_, __, ___) => const SizedBox()),
        const SizedBox(width: 5),
        Text(_l[cat]!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: sel ? color : Theme.of(context).colorScheme.onSurface)),
      ]),
    ));
  }
}
