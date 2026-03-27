import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pokedex_tracker/models/pokemon.dart';
import 'package:pokedex_tracker/services/pokedex_data_service.dart';
import 'package:pokedex_tracker/theme/type_colors.dart';
import 'package:pokedex_tracker/screens/detail/detail_shared.dart';

// ─── DADOS ESTÁTICOS DO GO ────────────────────────────────────────

const Map<int, String> _goRegionals = {
  83: 'Ásia', 115: 'Austrália/NZ', 122: 'Europa', 128: 'América do Norte',
  214: 'América do Sul', 222: 'Trópicos', 313: 'Europa/Ásia/AU',
  314: 'Américas/África', 324: 'Ásia do Sul', 335: 'América do Norte/Ásia',
  336: 'América do Sul/Europa', 337: 'Américas', 338: 'Europa/Ásia/AU',
  357: 'África/Mediterrâneo', 369: 'Austrália/NZ', 417: 'América do Norte/Rússia',
  422: 'Atlântico', 423: 'Pacífico', 441: 'Hemisfério Sul', 455: 'América do Norte',
  480: 'Ásia-Pacífico', 481: 'Europa', 482: 'Américas',
  511: 'Ásia-Pacífico', 513: 'Américas', 515: 'Europa/África',
  538: 'América do Norte', 539: 'Ásia/Austrália', 556: 'América do Sul',
  561: 'Egito/Grécia',
};

const Set<int> _goLegendaryRaid = {
  144, 145, 146, 150, 243, 244, 245, 249, 250,
  377, 378, 379, 380, 381, 382, 383, 384,
  480, 481, 482, 483, 484, 485, 486, 487, 488,
  638, 639, 640, 641, 642, 643, 644, 645, 646,
  716, 717, 718, 785, 786, 787, 788,
};

const Set<int> _goMythical = {
  151, 251, 385, 386, 489, 490, 491, 492, 493,
  494, 647, 648, 649, 719, 720, 721,
};

const Map<int, String> _goEggs = {
  10: '2km', 13: '2km', 16: '2km', 19: '2km', 21: '2km', 27: '2km',
  1: '5km', 4: '5km', 7: '5km', 25: '5km', 129: '5km',
  147: '10km', 246: '10km', 443: '10km', 610: '10km', 621: '10km',
};

class _EvoReq {
  final int candy;
  final String? extra;
  const _EvoReq(this.candy, {this.extra});
}

const Map<int, _EvoReq> _goEvoReqs = {
  2: _EvoReq(25), 3: _EvoReq(100),
  5: _EvoReq(25), 6: _EvoReq(100),
  8: _EvoReq(25), 9: _EvoReq(100),
  11: _EvoReq(12), 12: _EvoReq(50),
  14: _EvoReq(12), 15: _EvoReq(50),
  17: _EvoReq(12), 18: _EvoReq(50),
  20: _EvoReq(50), 22: _EvoReq(50), 24: _EvoReq(50),
  26: _EvoReq(50), 28: _EvoReq(50),
  30: _EvoReq(25), 31: _EvoReq(100),
  33: _EvoReq(25), 34: _EvoReq(100),
  36: _EvoReq(50), 38: _EvoReq(50), 40: _EvoReq(50), 42: _EvoReq(50),
  44: _EvoReq(25),
  45: _EvoReq(100, extra: 'Pedra Solar'),
  47: _EvoReq(50), 49: _EvoReq(50), 51: _EvoReq(50), 53: _EvoReq(50),
  55: _EvoReq(50), 57: _EvoReq(50), 59: _EvoReq(50),
  61: _EvoReq(25), 62: _EvoReq(100),
  64: _EvoReq(25), 65: _EvoReq(100),
  67: _EvoReq(25), 68: _EvoReq(100),
  70: _EvoReq(25), 71: _EvoReq(100),
  73: _EvoReq(50), 75: _EvoReq(25), 76: _EvoReq(100),
  78: _EvoReq(50), 80: _EvoReq(50), 82: _EvoReq(50),
  85: _EvoReq(50), 87: _EvoReq(50), 89: _EvoReq(50), 91: _EvoReq(50),
  93: _EvoReq(25), 94: _EvoReq(100, extra: 'Pedra de Sinnoh'),
  97: _EvoReq(50), 99: _EvoReq(50), 101: _EvoReq(50), 103: _EvoReq(50),
  105: _EvoReq(50), 110: _EvoReq(50), 112: _EvoReq(50),
  117: _EvoReq(50), 119: _EvoReq(50), 121: _EvoReq(50),
  124: _EvoReq(50), 125: _EvoReq(50), 126: _EvoReq(50),
  130: _EvoReq(400),
  134: _EvoReq(25), 135: _EvoReq(25), 136: _EvoReq(25),
  139: _EvoReq(50), 141: _EvoReq(50), 143: _EvoReq(50),
  153: _EvoReq(25), 154: _EvoReq(100),
  156: _EvoReq(25), 157: _EvoReq(100),
  159: _EvoReq(25), 160: _EvoReq(100),
  162: _EvoReq(50), 164: _EvoReq(50), 166: _EvoReq(50), 168: _EvoReq(50),
  170: _EvoReq(25), 171: _EvoReq(50), 178: _EvoReq(50),
  182: _EvoReq(50, extra: 'Pedra Solar'),
  184: _EvoReq(50),
  186: _EvoReq(100, extra: 'Pedra do Rei'),
  188: _EvoReq(25), 189: _EvoReq(100),
  192: _EvoReq(50, extra: 'Pedra Solar'),
  196: _EvoReq(25, extra: 'Espeon: 10km Buddy + evoluir de dia'),
  197: _EvoReq(25, extra: 'Umbreon: 10km Buddy + evoluir de noite'),
  199: _EvoReq(50, extra: 'Pedra do Rei'),
  202: _EvoReq(50), 205: _EvoReq(50),
  208: _EvoReq(50, extra: 'Casaco de Metal'),
  210: _EvoReq(50),
  212: _EvoReq(50, extra: 'Casaco de Metal'),
  214: _EvoReq(50), 215: _EvoReq(50), 219: _EvoReq(50), 221: _EvoReq(50),
  224: _EvoReq(50), 226: _EvoReq(50), 229: _EvoReq(50),
  230: _EvoReq(100, extra: 'Escama de Dragão'),
  232: _EvoReq(50),
  233: _EvoReq(50, extra: 'Módulo de Upgrade'),
  237: _EvoReq(50), 241: _EvoReq(50),
  256: _EvoReq(25), 257: _EvoReq(100),
  259: _EvoReq(25), 260: _EvoReq(100),
  262: _EvoReq(50), 264: _EvoReq(50),
  267: _EvoReq(12), 269: _EvoReq(50), 272: _EvoReq(50), 275: _EvoReq(50),
  277: _EvoReq(12), 279: _EvoReq(50), 282: _EvoReq(50), 284: _EvoReq(50),
  286: _EvoReq(50), 291: _EvoReq(50), 295: _EvoReq(50), 297: _EvoReq(50),
  301: _EvoReq(50), 303: _EvoReq(50), 306: _EvoReq(50), 308: _EvoReq(50),
  310: _EvoReq(50), 315: _EvoReq(25), 319: _EvoReq(50), 323: _EvoReq(50),
  330: _EvoReq(50), 334: _EvoReq(50), 340: _EvoReq(50), 342: _EvoReq(50),
  344: _EvoReq(50), 346: _EvoReq(50), 348: _EvoReq(50),
  350: _EvoReq(100, extra: 'Caminhar 20km como Buddy'),
  354: _EvoReq(50), 357: _EvoReq(50), 362: _EvoReq(50),
  365: _EvoReq(50), 368: _EvoReq(50), 370: _EvoReq(50), 373: _EvoReq(50),
  376: _EvoReq(50),
  398: _EvoReq(50), 400: _EvoReq(50),
  402: _EvoReq(25), 404: _EvoReq(25), 405: _EvoReq(100),
  407: _EvoReq(100, extra: 'Pedra Solar'),
  409: _EvoReq(50), 411: _EvoReq(50), 414: _EvoReq(50), 416: _EvoReq(50),
  419: _EvoReq(100), 421: _EvoReq(50), 424: _EvoReq(50), 426: _EvoReq(50),
  430: _EvoReq(50), 432: _EvoReq(50), 435: _EvoReq(50), 437: _EvoReq(50),
  441: _EvoReq(50), 448: _EvoReq(50), 450: _EvoReq(50), 452: _EvoReq(50),
  454: _EvoReq(50), 457: _EvoReq(50), 460: _EvoReq(100),
  461: _EvoReq(100, extra: 'Pedra de Sinnoh'),
  462: _EvoReq(100, extra: 'Pedra de Sinnoh ou Módulo de Isca Magnética'),
  463: _EvoReq(100, extra: 'Pedra de Sinnoh'),
  464: _EvoReq(100, extra: 'Pedra de Sinnoh'),
  465: _EvoReq(100, extra: 'Pedra de Sinnoh'),
  466: _EvoReq(100, extra: 'Pedra de Sinnoh'),
  467: _EvoReq(100, extra: 'Pedra de Sinnoh'),
  468: _EvoReq(100, extra: 'Pedra de Sinnoh'),
  469: _EvoReq(100, extra: 'Pedra de Sinnoh'),
  470: _EvoReq(25, extra: 'Módulo de Isca Musgosa'),
  471: _EvoReq(25, extra: 'Módulo de Isca Glacial'),
  472: _EvoReq(100, extra: 'Pedra de Sinnoh'),
  473: _EvoReq(100, extra: 'Pedra de Sinnoh'),
  474: _EvoReq(100, extra: 'Módulo de Upgrade'),
  503: _EvoReq(50), 505: _EvoReq(50), 508: _EvoReq(50), 510: _EvoReq(50),
  512: _EvoReq(50), 514: _EvoReq(50), 516: _EvoReq(50), 518: _EvoReq(50),
  521: _EvoReq(50), 523: _EvoReq(50), 525: _EvoReq(25),
  526: _EvoReq(100, extra: 'Pedra de Unova'),
  528: _EvoReq(50),
  530: _EvoReq(50, extra: 'Pedra de Unova'),
  534: _EvoReq(50), 537: _EvoReq(50), 542: _EvoReq(50), 545: _EvoReq(50),
  547: _EvoReq(50, extra: 'Módulo de Isca Floral'),
  549: _EvoReq(50, extra: 'Pedra de Unova'),
  553: _EvoReq(50, extra: 'Pedra de Unova'),
  560: _EvoReq(50, extra: 'Pedra de Unova'),
  579: _EvoReq(50, extra: 'Pedra de Unova'),
  589: _EvoReq(50, extra: 'Pedra de Unova + troca com Shelmet'),
  591: _EvoReq(50),
  617: _EvoReq(50, extra: 'Pedra de Unova + troca com Karrablast'),
  658: _EvoReq(50), 673: _EvoReq(50),
  675: _EvoReq(50, extra: 'Capturar 32 Pokémon tipo Sombrio como Buddy'),
  683: _EvoReq(50, extra: 'Usar Incenso'),
  686: _EvoReq(50, extra: 'Dar 25 doces ao Buddy'),
  700: _EvoReq(25, extra: 'Sylveon: 70 Corações com Buddy'),
  706: _EvoReq(100, extra: 'Tempo chuvoso ou neblinoso'),
};

String? _goRegional(int id) => _goRegionals[id];

List<String> _goObtain(int id) {
  if (_goLegendaryRaid.contains(id)) return ['Raid de 5 estrelas (Lendário)'];
  if (_goMythical.contains(id))      return ['Evento especial (pesquisa)'];
  final m = <String>[];
  if (_goRegionals.containsKey(id)) {
    m.add('Selvagem — exclusivo de ${_goRegionals[id]}');
  } else {
    m.add('Selvagem');
  }
  if (_goEggs.containsKey(id)) m.add('Ovo de ${_goEggs[id]}');
  return m;
}

// ─── TELA PRINCIPAL ───────────────────────────────────────────────

class GoDetailScreen extends StatefulWidget {
  final Pokemon pokemon;
  final bool caught;
  final VoidCallback onToggleCaught;
  final String? prevName; final int? prevId;
  final String? nextName; final int? nextId;
  final VoidCallback? onPrev; final VoidCallback? onNext;

  const GoDetailScreen({
    super.key,
    required this.pokemon, required this.caught, required this.onToggleCaught,
    this.prevName, this.prevId, this.nextName, this.nextId,
    this.onPrev, this.onNext,
  });

  @override
  State<GoDetailScreen> createState() => _GoDetailScreenState();
}

class _GoDetailScreenState extends State<GoDetailScreen>
    with SingleTickerProviderStateMixin {
  late bool _caught;
  late TabController _tabController;
  List<Map<String, dynamic>> _forms = [];
  bool _loadingForms = true;
  static const _tabs = ['Sobre', 'Status', 'Formas'];

  @override
  void initState() {
    super.initState();
    _caught = widget.caught;
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadForms();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadForms() async {
    try {
      final raw = await rootBundle.loadString('assets/data/forms_map.json');
      final map = json.decode(raw) as Map<String, dynamic>;
      final id  = widget.pokemon.id.toString();
      final svc = PokedexDataService.instance;
      final list = (map[id] as List<dynamic>? ?? []).map((v) {
        final m   = v as Map<String, dynamic>;
        final pid = m['id'] as int;
        return <String, dynamic>{
          'name': m['name'], 'id': pid,
          'types': svc.getTypes(pid).isNotEmpty
              ? svc.getTypes(pid) : svc.getTypes(widget.pokemon.id),
          'isDefault': m['isDefault'] ?? false, 'game': null,
        };
      }).toList();
      if (mounted) setState(() { _forms = list; _loadingForms = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingForms = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          DetailHeader(
            pokemon: widget.pokemon,
            caught: _caught,
            onToggleCaught: () {
              setState(() => _caught = !_caught);
              widget.onToggleCaught();
            },
            prevName: widget.prevName, prevId: widget.prevId,
            nextName: widget.nextName, nextId: widget.nextId,
            onPrev: widget.onPrev, onNext: widget.onNext,
          ),
        ],
        body: Column(children: [
          Material(
            elevation: 0,
            child: TabBar(
              controller: _tabController,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(child: TabBarView(
            controller: _tabController,
            children: [
              _GoSobreTab(pokemon: widget.pokemon),
              _GoStatusTab(pokemon: widget.pokemon),
              FormsTab(forms: _forms, loading: _loadingForms),
            ],
          )),
        ]),
      ),
    );
  }
}

// ─── ABA SOBRE ───────────────────────────────────────────────────

class _GoSobreTab extends StatelessWidget {
  final Pokemon pokemon;
  const _GoSobreTab({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final svc      = PokedexDataService.instance;
    final id       = pokemon.id;
    final types    = pokemon.types;
    final category = svc.getCategory(id);
    final flavors  = svc.getFlavorTexts(id);
    const rocketColor = Color(0xFF7B1FA2);

    String flavorText = '';
    if (flavors.isNotEmpty) {
      final g = flavors.lastWhere(
        (g) => (g['textPt'] as String? ?? '').isNotEmpty,
        orElse: () => flavors.last,
      );
      flavorText = g['textPt'] as String? ?? g['textEn'] as String? ?? '';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [

        if (category.isNotEmpty)
          Text(category, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),

        if (flavorText.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(flavorText, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, height: 1.5)),
        ],

        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (int i = 0; i < types.length; i++) ...[
            TypeBadge(type: types[i]),
            if (i < types.length - 1) const SizedBox(width: 8),
          ],
        ]),
        const SizedBox(height: 20),

        SectionCard(
          title: 'DISPONIBILIDADE',
          pokemonTypes: types,
          child: Column(children: [
            IntrinsicHeight(child: Row(children: [
              _availCell(context, 'Shiny', 'Disponível', const Color(0xFF34C759)),
              VerticalDivider(width: 1, thickness: 0.5, color: neutralBorder(context)),
              _availCell(context, 'Shadow', 'Disponível', rocketColor),
            ])),
            Divider(height: 1, thickness: 0.5, color: neutralBorder(context)),
            IntrinsicHeight(child: Row(children: [
              _regionalCell(context, id),
              VerticalDivider(width: 1, thickness: 0.5, color: neutralBorder(context)),
              _availCell(context, 'Lucky', 'Via troca', const Color(0xFFFFCC00)),
            ])),
          ]),
        ),

        const SizedBox(height: 16),

        SectionCard(
          title: 'COMO OBTER',
          pokemonTypes: types,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _goObtain(id).map((method) {
              IconData icon; Color color;
              if (method.contains('Lendário')) {
                icon = Icons.auto_awesome; color = const Color(0xFFE65100);
              } else if (method.contains('Ovo')) {
                icon = Icons.egg_outlined; color = const Color(0xFF1565C0);
              } else if (method.contains('Evento')) {
                icon = Icons.event_outlined; color = const Color(0xFF00897B);
              } else if (method.contains('exclusivo')) {
                icon = Icons.location_on_outlined; color = const Color(0xFFE65100);
              } else {
                icon = Icons.catching_pokemon_outlined; color = const Color(0xFF4a9020);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 10),
                  Expanded(child: Text(method,
                    style: const TextStyle(fontSize: 13))),
                ]),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),
        _GoEvoSection(pokemon: pokemon),

      ]),
    );
  }

  Widget _availCell(BuildContext ctx, String label, String value, Color color) =>
    Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10,
          color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: color)),
      ]),
    ));

  Widget _regionalCell(BuildContext ctx, int id) {
    final r = _goRegional(id);
    return _availCell(ctx, 'Regional',
      r ?? 'Global',
      r != null ? const Color(0xFFE65100) : const Color(0xFF34C759));
  }
}

// ─── SEÇÃO EVOLUÇÃO GO ────────────────────────────────────────────

class _GoEvoSection extends StatelessWidget {
  final Pokemon pokemon;
  const _GoEvoSection({required this.pokemon});

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final chain = PokedexDataService.instance.getEvoChain(pokemon.id);
    if (chain.length <= 1) return const SizedBox();

    final hasExtra = chain.skip(1).any(
      (e) => (_goEvoReqs[e['id'] as int]?.extra) != null,
    );

    return SectionCard(
      title: 'EVOLUÇÃO NO GO',
      pokemonTypes: pokemon.types,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cadeia visual
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (int i = 0; i < chain.length; i++) ...[
              _EvoNode(entry: chain[i]),
              if (i < chain.length - 1) ...[
                const SizedBox(width: 6),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_forward_ios,
                    size: 12, color: Colors.grey),
                  _CandyChip(targetId: chain[i + 1]['id'] as int),
                ]),
                const SizedBox(width: 6),
              ],
            ],
          ]),
        ),
        // Requisitos especiais
        if (hasExtra) ...[
          const SizedBox(height: 12),
          ...chain.skip(1).where((e) =>
            (_goEvoReqs[e['id'] as int]?.extra) != null,
          ).map((e) {
            final req  = _goEvoReqs[e['id'] as int]!;
            final name = _cap(e['name'] as String? ?? '');
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline,
                  size: 14, color: Color(0xFF1565C0)),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  '$name: ${req.extra}',
                  style: const TextStyle(fontSize: 12, height: 1.4),
                )),
              ]),
            );
          }),
        ],
      ]),
    );
  }
}

class _EvoNode extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _EvoNode({required this.entry});

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final id   = entry['id'] as int;
    final name = _cap(entry['name'] as String? ?? '');
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Image.asset('assets/sprites/artwork/$id.webp',
        width: 56, height: 56, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(width: 56, height: 56)),
      const SizedBox(height: 4),
      SizedBox(width: 64, child: Text(name,
        style: const TextStyle(fontSize: 10),
        textAlign: TextAlign.center, maxLines: 2,
        overflow: TextOverflow.ellipsis)),
    ]);
  }
}

class _CandyChip extends StatelessWidget {
  final int targetId;
  const _CandyChip({required this.targetId});

  @override
  Widget build(BuildContext context) {
    final req = _goEvoReqs[targetId];
    if (req == null) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63).withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.3)),
      ),
      child: Text('${req.candy} doces',
        style: const TextStyle(fontSize: 9,
          color: Color(0xFFE91E63), fontWeight: FontWeight.w600)),
    );
  }
}

// ─── ABA STATUS GO ───────────────────────────────────────────────

class _GoStatusTab extends StatefulWidget {
  final Pokemon pokemon;
  const _GoStatusTab({required this.pokemon});

  @override
  State<_GoStatusTab> createState() => _GoStatusTabState();
}

class _GoStatusTabState extends State<_GoStatusTab>
    with SingleTickerProviderStateMixin {

  int _goAtk = 0, _goDef = 0, _goSta = 0;
  bool _loaded = false;
  late TabController _tabController;

  static Map<String, dynamic>? _statsData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadStats() async {
    // Cache estático — carrega o JSON uma única vez em toda a sessão
    try {
      _statsData ??= json.decode(
        await rootBundle.loadString('assets/data/pokemon_stats.json'),
      ) as Map<String, dynamic>;
      final s = _statsData![widget.pokemon.id.toString()] as Map<String, dynamic>?;
      if (s != null && mounted) {
        setState(() {
          _goAtk = (s['go_atk'] as num).toInt();
          _goDef = (s['go_def'] as num).toInt();
          _goSta = (s['go_sta'] as num).toInt();
          _loaded = true;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() {
      _goAtk = widget.pokemon.baseAttack;
      _goDef = widget.pokemon.baseDefense;
      _goSta = (widget.pokemon.baseHp * 1.75 + 50).floor();
      _loaded = true;
    });
  }

  int get _maxCp {
    if (_goAtk == 0) return 0;
    const cpm = 0.7903;
    double sq(num n) {
      if (n <= 0) return 0;
      double x = n.toDouble();
      for (int i = 0; i < 30; i++) x = (x + n / x) / 2;
      return x;
    }
    final cp = ((_goAtk + 15) * sq(_goDef + 15) *
        sq(_goSta + 15) * cpm * cpm / 10).floor();
    return cp < 10 ? 10 : cp;
  }

  Map<String, double> _effectiveness() {
    const table = <String, Map<String, double>>{
      'normal':   {'fighting': 2, 'ghost': 0},
      'fire':     {'water': 2, 'ground': 2, 'rock': 2, 'fire': .5,
                   'grass': .5, 'ice': .5, 'bug': .5, 'steel': .5, 'fairy': .5},
      'water':    {'electric': 2, 'grass': 2, 'fire': .5,
                   'water': .5, 'ice': .5, 'steel': .5},
      'electric': {'ground': 2, 'electric': .5, 'flying': .5, 'steel': .5},
      'grass':    {'fire': 2, 'ice': 2, 'poison': 2, 'flying': 2, 'bug': 2,
                   'water': .5, 'electric': .5, 'grass': .5, 'ground': .5},
      'ice':      {'fire': 2, 'fighting': 2, 'rock': 2, 'steel': 2, 'ice': .5},
      'fighting': {'flying': 2, 'psychic': 2, 'fairy': 2,
                   'bug': .5, 'rock': .5, 'dark': .5, 'ghost': 0},
      'poison':   {'ground': 2, 'psychic': 2,
                   'grass': .5, 'fighting': .5, 'poison': .5, 'bug': .5, 'fairy': .5,
                   'steel': 0},
      'ground':   {'water': 2, 'grass': 2, 'ice': 2,
                   'poison': .5, 'rock': .5, 'electric': 0},
      'flying':   {'electric': 2, 'ice': 2, 'rock': 2,
                   'grass': .5, 'fighting': .5, 'bug': .5, 'ground': 0},
      'psychic':  {'bug': 2, 'ghost': 2, 'dark': 2,
                   'fighting': .5, 'psychic': .5},
      'bug':      {'fire': 2, 'flying': 2, 'rock': 2,
                   'grass': .5, 'fighting': .5, 'ground': .5},
      'rock':     {'water': 2, 'grass': 2, 'fighting': 2, 'ground': 2, 'steel': 2,
                   'normal': .5, 'fire': .5, 'poison': .5, 'flying': .5},
      'ghost':    {'ghost': 2, 'dark': 2,
                   'poison': .5, 'bug': .5, 'normal': 0, 'fighting': 0},
      'dragon':   {'ice': 2, 'dragon': 2, 'fairy': 2,
                   'fire': .5, 'water': .5, 'electric': .5, 'grass': .5},
      'dark':     {'fighting': 2, 'bug': 2, 'fairy': 2,
                   'ghost': .5, 'dark': .5, 'psychic': 0},
      'steel':    {'fire': 2, 'fighting': 2, 'ground': 2,
                   'normal': .5, 'grass': .5, 'ice': .5, 'flying': .5,
                   'psychic': .5, 'bug': .5, 'rock': .5, 'dragon': .5,
                   'steel': .5, 'fairy': .5, 'poison': 0},
      'fairy':    {'poison': 2, 'steel': 2,
                   'fighting': .5, 'bug': .5, 'dark': .5, 'dragon': 0},
    };
    const all = ['normal','fire','water','electric','grass','ice','fighting',
      'poison','ground','flying','psychic','bug','rock','ghost','dragon','dark','steel','fairy'];

    final types = widget.pokemon.types;
    final result = <String, double>{};
    for (final atk in all) {
      double m = 1;
      for (final def in types) {
        m *= (table[def] ?? {})[atk] ?? 1;
      }
      double go;
      if (m == 0 || m == .25) go = .391;
      else if (m == .5)  go = .625;
      else if (m == 2)   go = 1.6;
      else if (m == 4)   go = 2.56;
      else go = m;
      if (go != 1.0) result[atk] = go;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final p         = widget.pokemon;
    final types     = p.types;
    final typeColor = types.isNotEmpty
        ? TypeColors.fromType(ptType(types[0]))
        : Theme.of(context).colorScheme.primary;

    final eff  = _effectiveness();
    final quad = eff.entries.where((e) => e.value == 2.56).map((e) => e.key).toList()..sort();
    final frac = eff.entries.where((e) => e.value == 1.6).map((e) => e.key).toList()..sort();
    final half = eff.entries.where((e) => e.value == .625).map((e) => e.key).toList()..sort();
    final qurt = eff.entries.where((e) => e.value == .391).map((e) => e.key).toList()..sort();

    // Stats para as barras (mesmo padrão das outras telas)
    final stats = [
      _GoStatRow('Ataque GO',  _goAtk, const Color(0xFFE24B4A), 350),
      _GoStatRow('Defesa GO',  _goDef, const Color(0xFF378ADD), 350),
      _GoStatRow('Stamina GO', _goSta, const Color(0xFF5a9e5a), 500),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [

        SectionCard(
          title: 'STATS POKÉMON GO',
          pokemonTypes: types,
          child: Column(children: [
            if (!_loaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: PokeballLoader.small()))
            else ...[
              // Abas Base / Mínimo / Máximo (mesmo padrão visual)
              Row(children: [
                for (final e in [(0,'Base'),(1,'Mínimo'),(2,'Máximo')]) ...[
                  Expanded(child: GestureDetector(
                    onTap: () => _tabController.animateTo(e.$1),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (_, __) {
                        final active = _tabController.index == e.$1;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: active ? typeColor : typeColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: active ? typeColor : typeColor.withOpacity(0.35)),
                          ),
                          child: Text(e.$2, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: active ? typeTextColor(typeColor) : typeColor)),
                        );
                      },
                    ),
                  )),
                  if (e.$1 < 2) const SizedBox(width: 5),
                ],
              ]),
              const SizedBox(height: 14),
              // Barras de stat
              ...stats.map((s) => _GoStatBarRow(
                row: s, tabController: _tabController)),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'CP Máx. Nv.40: $_maxCp',
                    style: TextStyle(fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
              ),
            ],
          ]),
        ),

        const SizedBox(height: 16),

        SectionCard(
          title: 'EFETIVIDADE DE TIPOS',
          pokemonTypes: types,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (quad.isNotEmpty) ...[
              _effRow(context, 'Muito fraco a', '2.56×',
                const Color(0xFFB71C1C), quad),
              const SizedBox(height: 12),
            ],
            if (frac.isNotEmpty) ...[
              _effRow(context, 'Fraco a', '1.6×',
                const Color(0xFFE53935), frac),
              const SizedBox(height: 12),
            ],
            if (half.isNotEmpty) ...[
              _effRow(context, 'Resistente a', '0.625×',
                const Color(0xFF388E3C), half),
              const SizedBox(height: 12),
            ],
            if (qurt.isNotEmpty)
              _effRow(context, 'Muito resistente a', '0.391×',
                const Color(0xFF1B5E20), qurt),
          ]),
        ),

      ]),
    );
  }

  Widget _effRow(BuildContext ctx, String label, String mult,
      Color color, List<String> types) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 6),
        Text(mult, style: TextStyle(fontSize: 10,
          color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
      ]),
      const SizedBox(height: 6),
      Wrap(spacing: 4, runSpacing: 4,
        children: types.map((t) => TypeBadge(type: t)).toList()),
    ]);
  }
}

// Modelo de linha de stat GO
class _GoStatRow {
  final String label;
  final int value;
  final Color color;
  final int maxVal;
  const _GoStatRow(this.label, this.value, this.color, this.maxVal);
}

// Barra de stat GO com animação por aba (Base/Mínimo/Máximo)
class _GoStatBarRow extends StatelessWidget {
  final _GoStatRow row;
  final TabController tabController;
  const _GoStatBarRow({required this.row, required this.tabController});

  // Fórmulas GO (sem IVs, com IVs min, com IVs max)
  int _min() => row.value;              // base sem IVs
  int _max() => row.value + 15;         // base + IV máx

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final idx = tabController.index;
        final val = idx == 0 ? row.value
                  : idx == 1 ? _min()
                  : _max();
        final pct = (val / row.maxVal).clamp(0.0, 1.0);
        final scheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(width: 90,
              child: Text(row.label,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))),
            SizedBox(width: 36,
              child: Text('$val',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                textAlign: TextAlign.right)),
            const SizedBox(width: 8),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(row.color),
                ),
              ),
            )),
          ]),
        );
      },
    );
  }
}
