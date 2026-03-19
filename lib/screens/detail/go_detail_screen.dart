import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokedex_tracker/models/pokemon.dart';
import 'package:pokedex_tracker/screens/detail/detail_shared.dart';

class GoDetailScreen extends StatefulWidget {
  final Pokemon pokemon;
  final bool caught;
  final VoidCallback onToggleCaught;

  const GoDetailScreen({
    super.key,
    required this.pokemon,
    required this.caught,
    required this.onToggleCaught,
  });

  @override
  State<GoDetailScreen> createState() => _GoDetailScreenState();
}

class _GoDetailScreenState extends State<GoDetailScreen>
    with SingleTickerProviderStateMixin {

  late bool _caught;
  late TabController _tabController;

  List<Map<String, dynamic>> _forms = [];
  bool _loading = true;

  // Aba Calc. CP removida — agora está na calculadora standalone
  static const _tabs = ['Info', 'Status', 'Formas'];

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
      final r = await http.get(Uri.parse('$kApiBase/pokemon-species/${widget.pokemon.id}'));
      if (r.statusCode == 200 && mounted) {
        final species = json.decode(r.body) as Map<String, dynamic>;
        final varieties = species['varieties'] as List<dynamic>? ?? [];
        final forms = <Map<String, dynamic>>[];
        for (final v in varieties) {
          final url  = v['pokemon']['url'] as String;
          final name = v['pokemon']['name'] as String;
          try {
            final rf = await http.get(Uri.parse(url));
            if (rf.statusCode == 200) {
              final fd    = json.decode(rf.body) as Map<String, dynamic>;
              final types = (fd['types'] as List<dynamic>)
                  .map((t) => t['type']['name'] as String).toList();
              // Shadow e formas de evento também aparecem aqui como varieties
              forms.add({
                'name': name,
                'id': fd['id'] as int,
                'types': types,
                'isDefault': v['is_default'] as bool,
                'game': null,
              });
            }
          } catch (_) {}
        }
        if (mounted) setState(() { _forms = forms; _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
            onToggleCaught: () { setState(() => _caught = !_caught); widget.onToggleCaught(); },
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
              _GoInfoTab(pokemon: widget.pokemon),
              StatusTab(pokemon: widget.pokemon),
              FormsTab(forms: _forms, loading: _loading),
            ],
          )),
        ]),
      ),
    );
  }
}

// ─── ABA INFO GO ─────────────────────────────────────────────────

class _GoInfoTab extends StatefulWidget {
  final Pokemon pokemon;
  const _GoInfoTab({required this.pokemon});

  @override
  State<_GoInfoTab> createState() => _GoInfoTabState();
}

class _GoInfoTabState extends State<_GoInfoTab> {
  int _goAtk = 0, _goDef = 0, _goSta = 0;
  bool _loadingStats = true;

  // Busca os stats GO reais da pogoapi.net — valores precisos do game master
  Future<void> _loadGoStats() async {
    try {
      final r = await http.get(
        Uri.parse('https://pogoapi.net/api/v1/pokemon_stats.json'));
      if (r.statusCode == 200 && mounted) {
        final list = json.decode(r.body) as List<dynamic>;
        for (final p in list) {
          if ((p['id'] as int) == widget.pokemon.id) {
            setState(() {
              _goAtk = (p['base_attack'] as num).toInt();
              _goDef = (p['base_defense'] as num).toInt();
              _goSta = (p['base_stamina'] as num).toInt();
              _loadingStats = false;
            });
            return;
          }
        }
      }
    } catch (_) {}
    // Fallback: estimativa simples se a API falhar
    if (mounted) setState(() {
      _goAtk = widget.pokemon.baseAttack;
      _goDef = widget.pokemon.baseDefense;
      _goSta = widget.pokemon.baseHp;
      _loadingStats = false;
    });
  }

  int get _maxCp {
    if (_goAtk == 0) return 0;
    const cpm40 = 0.7903;
    double sqrt(num n) {
      if (n <= 0) return 0;
      double x = n.toDouble();
      for (int i = 0; i < 30; i++) x = (x + n / x) / 2;
      return x;
    }
    final cp = ((_goAtk + 15) * sqrt(_goDef + 15) *
        sqrt(_goSta + 15) * cpm40 * cpm40 / 10).floor();
    return cp < 10 ? 10 : cp;
  }

  @override
  void initState() {
    super.initState();
    _loadGoStats();
  }

  @override
  Widget build(BuildContext context) {
    final bg     = neutralBg(context);
    final border = neutralBorder(context);
    const rocketColor = Color(0xFF7B1FA2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        secTitle(context, 'STATS POKÉMON GO'),
        Container(
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: _loadingStats
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              : Column(children: [
                  Row(children: [
                    _statBox(context, '$_goAtk', 'Ataque'),
                    Container(width: 0.5, height: 40, color: border),
                    _statBox(context, '$_goDef', 'Defesa'),
                    Container(width: 0.5, height: 40, color: border),
                    _statBox(context, '$_goSta', 'Stamina'),
                  ]),
                  Divider(height: 0.5, color: border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('CP Máximo (Nível 40)',
                        style: TextStyle(fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Text('$_maxCp',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
        ),
        const SizedBox(height: 16),
        secTitle(context, 'DISPONIBILIDADE'),
        Column(children: [
          Row(children: [
            Expanded(child: _availCell(context, 'Shiny',    'Disponível',   const Color(0xFF34C759))),
            const SizedBox(width: 8),
            Expanded(child: _availCell(context, 'Shadow',   'Disponível',   rocketColor)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _availCell(context, 'Regional', 'Indisponível', Colors.red)),
            const SizedBox(width: 8),
            Expanded(child: _availCell(context, 'Lucky',    'Via troca',    const Color(0xFFFFCC00))),
          ]),
        ]),
        const SizedBox(height: 16),
        secTitle(context, 'COMO OBTER'),
        _obtainCard(context, Icons.catching_pokemon_outlined, const Color(0xFF4a9020),
          'Encontro selvagem', 'Ambientes urbanos e parques'),
        const SizedBox(height: 8),
        _obtainCard(context, Icons.star_border_outlined, const Color(0xFFc8a020),
          'Raid de 3 estrelas', 'Disponível como chefe de raid'),
      ]),
    );
  }

  Widget _statBox(BuildContext ctx, String val, String lbl) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(lbl, style: TextStyle(fontSize: 10,
          color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
      ]),
    ),
  );

  Widget _availCell(BuildContext ctx, String label, String value, Color color) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: neutralBg(ctx), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: TextStyle(fontSize: 10,
          color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );

  Widget _obtainCard(BuildContext ctx, IconData icon, Color iconColor, String title, String sub) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: neutralBg(ctx), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(sub, style: TextStyle(fontSize: 11,
            color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
        ]),
      ]),
    );
}