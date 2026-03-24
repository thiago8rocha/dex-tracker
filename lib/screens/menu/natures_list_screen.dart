import 'package:flutter/material.dart';
import 'package:pokedex_tracker/screens/detail/detail_shared.dart'
    show BilingualTerm;

// ─── Dados das 25 natures ─────────────────────────────────────────
// Fonte: Bulbapedia / PokeAPI — nunca mudam entre gerações
class _Nature {
  final String nameEn;
  final String namePt;
  final String? increased; // stat aumentado (null = neutra)
  final String? decreased; // stat reduzido  (null = neutra)
  const _Nature(this.nameEn, this.namePt, this.increased, this.decreased);
  bool get isNeutral => increased == null;
}

const _natures = [
  _Nature('hardy',   'Forte',      null,      null),
  _Nature('lonely',  'Solitária',  'atk',     'def'),
  _Nature('brave',   'Corajosa',   'atk',     'spe'),
  _Nature('adamant', 'Firme',      'atk',     'spa'),
  _Nature('naughty', 'Levada',     'atk',     'spd'),
  _Nature('bold',    'Ousada',     'def',     'atk'),
  _Nature('docile',  'Dócil',      null,      null),
  _Nature('relaxed', 'Tranquila',  'def',     'spe'),
  _Nature('impish',  'Travessa',   'def',     'spa'),
  _Nature('lax',     'Descuidada', 'def',     'spd'),
  _Nature('timid',   'Tímida',     'spe',     'atk'),
  _Nature('hasty',   'Apressada',  'spe',     'def'),
  _Nature('serious', 'Séria',      null,      null),
  _Nature('jolly',   'Alegre',     'spe',     'spa'),
  _Nature('naive',   'Ingênua',    'spe',     'spd'),
  _Nature('modest',  'Modesta',    'spa',     'atk'),
  _Nature('mild',    'Suave',      'spa',     'def'),
  _Nature('quiet',   'Quieta',     'spa',     'spe'),
  _Nature('bashful', 'Acanhada',   null,      null),
  _Nature('rash',    'Impulsiva',  'spa',     'spd'),
  _Nature('calm',    'Calma',      'spd',     'atk'),
  _Nature('gentle',  'Gentil',     'spd',     'def'),
  _Nature('sassy',   'Insolente',  'spd',     'spe'),
  _Nature('careful', 'Cuidadosa',  'spd',     'spa'),
  _Nature('quirky',  'Estranha',   null,      null),
];

const _statLabel = {
  'atk': 'Ataque',
  'def': 'Defesa',
  'spa': 'Atq. Esp.',
  'spd': 'Def. Esp.',
  'spe': 'Velocidade',
};

// ─── Tela ─────────────────────────────────────────────────────────
class NaturesListScreen extends StatefulWidget {
  const NaturesListScreen({super.key});
  @override State<NaturesListScreen> createState() => _NaturesListScreenState();
}

class _NaturesListScreenState extends State<NaturesListScreen> {
  bool   _searching = false;
  String _search    = '';
  String? _filterStat; // filtrar por stat aumentado
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<_Nature> get _filtered {
    var list = _natures.toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((n) =>
          n.nameEn.contains(q) || n.namePt.toLowerCase().contains(q)).toList();
    }
    if (_filterStat != null) {
      list = list.where((n) => n.increased == _filterStat).toList();
    }
    return list;
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) { _search = ''; _searchCtrl.clear(); }
    });
  }

  void _showStatFilter() async {
    final stats = ['atk', 'def', 'spa', 'spd', 'spe'];
    final result = await showMenu<String?>(
      context: context,
      position: _filterButtonPosition(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          value: null,
          child: _menuItem(context, 'Todas', _filterStat == null)),
        ...stats.map((s) => PopupMenuItem(
          value: s,
          child: _menuItem(context, '+ ${_statLabel[s]}', _filterStat == s))),
      ],
    );
    if (mounted) setState(() => _filterStat = result);
  }

  Widget _menuItem(BuildContext ctx, String label, bool selected) => Row(children: [
    Expanded(child: Text(label, style: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal))),
    if (selected) Icon(Icons.check, size: 16,
        color: Theme.of(ctx).colorScheme.primary),
  ]);

  final GlobalKey _filterKey = GlobalKey();

  RelativeRect _filterButtonPosition() {
    final box = _filterKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return const RelativeRect.fromLTRB(0, 56, 0, 0);
    final pos = box.localToGlobal(Offset.zero);
    return RelativeRect.fromLTRB(
        pos.dx, pos.dy + box.size.height, pos.dx + box.size.width, 0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme   = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final filterLabel = _filterStat == null
        ? 'Todas as naturezas'
        : '+ ${_statLabel[_filterStat]}';

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                    hintText: 'Buscar natureza...', border: InputBorder.none),
                style: const TextStyle(fontSize: 16),
              )
            : const Text('Naturezas'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),

      body: Column(children: [
        // Dropdown de filtro por stat
        GestureDetector(
          key: _filterKey,
          onTap: _showStatFilter,
          child: Container(
            color: scheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(children: [
              Text(filterLabel, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: _filterStat != null
                      ? scheme.primary : scheme.onSurfaceVariant)),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 16,
                  color: _filterStat != null
                      ? scheme.primary : scheme.onSurfaceVariant),
            ]),
          ),
        ),

        // Lista
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => Divider(
              height: 1, color: scheme.outlineVariant.withOpacity(0.5)),
          itemBuilder: (ctx, i) => _NatureTile(nature: filtered[i]),
        )),
      ]),
    );
  }
}

// ─── Tile da natureza ─────────────────────────────────────────────
class _NatureTile extends StatelessWidget {
  final _Nature nature;
  const _NatureTile({required this.nature});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
      child: Row(children: [
        // Nome com BilingualTerm (mesmo comportamento que moves)
        Expanded(
          flex: 3,
          child: BilingualTerm(
            namePt: nature.namePt,
            nameEn: nature.nameEn,
            baseStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            secondaryStyle: const TextStyle(fontSize: 11),
          ),
        ),

        // Stats — só mostra para natures não-neutras
        if (!nature.isNeutral) ...[
          const SizedBox(width: 8),
          // Stat aumentado (verde + seta cima)
          _StatBadge(
            label: _statLabel[nature.increased]!,
            up: true,
            color: const Color(0xFF2E7D32),
            scheme: scheme,
          ),
          const SizedBox(width: 6),
          // Stat reduzido (vermelho + seta baixo)
          _StatBadge(
            label: _statLabel[nature.decreased]!,
            up: false,
            color: const Color(0xFFC62828),
            scheme: scheme,
          ),
        ] else
          // Neutra
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('Neutra', style: TextStyle(
                fontSize: 11, color: scheme.onSurfaceVariant.withOpacity(0.6))),
          ),
      ]),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String      label;
  final bool        up;
  final Color       color;
  final ColorScheme scheme;
  const _StatBadge({
    required this.label, required this.up,
    required this.color, required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.35), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 11, color: color,
        ),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
