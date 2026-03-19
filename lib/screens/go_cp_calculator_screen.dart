import 'package:flutter/material.dart';

class GoCpCalculatorScreen extends StatefulWidget {
  const GoCpCalculatorScreen({super.key});

  @override
  State<GoCpCalculatorScreen> createState() => _GoCpCalculatorScreenState();
}

class _GoCpCalculatorScreenState extends State<GoCpCalculatorScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  // ── Estado da calculadora de Evolução ────────────────────────────
  final _cpController = TextEditingController(text: '500');
  double _currentCp = 500;

  // ── Estado da calculadora de IVs ─────────────────────────────────
  double _level = 25;
  int _ivAtk = 15, _ivDef = 15, _ivHp = 15;

  // ── Stats do Pokémon (busca manual ou digita) ─────────────────────
  final _atkCtrl  = TextEditingController(text: '200');
  final _defCtrl  = TextEditingController(text: '200');
  final _hpCtrl   = TextEditingController(text: '200');

  static const List<double> _cpm = [
    0.094,0.1351,0.1663,0.192,0.2126,0.2295,0.2436,0.2557,0.2663,0.2756,
    0.2839,0.2913,0.298,0.3041,0.3096,0.3145,0.319,0.323,0.3267,0.33,
    0.3331,0.3359,0.3385,0.3408,0.343,0.345,0.3469,0.3486,0.3502,0.3517,
    0.3531,0.3544,0.3556,0.3567,0.3578,0.3587,0.3596,0.3604,0.3612,0.3619,
    0.3625,0.3631,0.3637,0.3642,0.3647,0.3652,0.3657,0.3661,0.3665,0.3669,
    0.37,
  ];

  double _sqrt(num n) {
    if (n <= 0) return 0;
    double x = n.toDouble();
    for (int i = 0; i < 30; i++) x = (x + n / x) / 2;
    return x;
  }

  int _calcCp(int ba, int bd, int bh, double lvl, int ia, int id, int ih) {
    final idx = ((lvl - 1) * 2).round().clamp(0, _cpm.length - 1);
    final cp = ((ba + ia) * _sqrt(bd + id) * _sqrt(bh + ih) * _cpm[idx] * _cpm[idx] / 10).floor();
    return cp < 10 ? 10 : cp;
  }

  int get _baseAtk  => int.tryParse(_atkCtrl.text) ?? 200;
  int get _baseDef  => int.tryParse(_defCtrl.text) ?? 200;
  int get _baseHp   => int.tryParse(_hpCtrl.text)  ?? 200;

  int get _maxCp => _calcCp(_baseAtk, _baseDef, _baseHp, 40, 15, 15, 15);
  int get _cpResult => _calcCp(_baseAtk, _baseDef, _baseHp, _level, _ivAtk, _ivDef, _ivHp);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cpController.dispose();
    _atkCtrl.dispose();
    _defCtrl.dispose();
    _hpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de CP'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Evolução'),
            Tab(text: 'IVs / Nível'),
          ],
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEvoCalc(context, bg),
          _buildIvCalc(context, bg),
        ],
      ),
    );
  }

  // ── Calculadora de Evolução ───────────────────────────────────────
  Widget _buildEvoCalc(BuildContext context, Color bg) {
    final cpInput = double.tryParse(_cpController.text) ?? 500;
    final evo1 = (cpInput * 1.815).round();
    final evo2 = (cpInput * 3.293).round();
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Insira o CP atual do Pokémon para estimar o CP após a evolução.',
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        // Input de CP
        TextField(
          controller: _cpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'CP atual',
            hintText: 'Ex: 1234',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (v) => setState(() {}),
        ),
        const SizedBox(height: 24),
        // Resultados
        Container(
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            _evoResultRow(context, 'Evolução 1', evo1,
              'Multiplicador ×1.815', scheme),
            Divider(height: 0.5, color: scheme.outlineVariant),
            _evoResultRow(context, 'Evolução 2', evo2,
              'Multiplicador ×3.293', scheme),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant, width: 0.5),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Valores aproximados. IVs e nível afetam o CP final.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _evoResultRow(BuildContext context, String label, int cp,
      String note, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Text(note, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ]),
        Text('$cp CP', style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: scheme.primary)),
      ]),
    );
  }

  // ── Calculadora de IVs / Nível ────────────────────────────────────
  Widget _buildIvCalc(BuildContext context, Color bg) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stats base
        Text('Stats base do Pokémon',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            letterSpacing: 0.8, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _statInput(context, _atkCtrl, 'Ataque')),
          const SizedBox(width: 8),
          Expanded(child: _statInput(context, _defCtrl, 'Defesa')),
          const SizedBox(width: 8),
          Expanded(child: _statInput(context, _hpCtrl, 'HP')),
        ]),
        const SizedBox(height: 20),
        // Sliders
        Text('Nível e IVs',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            letterSpacing: 0.8, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            _sliderRow(context, 'Nível', _level.toStringAsFixed(_level % 1 == 0 ? 0 : 1),
              1, 50, _level, (v) => setState(() => _level = (v * 2).round() / 2)),
            Divider(height: 1, color: scheme.outlineVariant),
            _sliderRow(context, 'IV Ataque', '$_ivAtk', 0, 15, _ivAtk.toDouble(),
              (v) => setState(() => _ivAtk = v.round())),
            Divider(height: 1, color: scheme.outlineVariant),
            _sliderRow(context, 'IV Defesa', '$_ivDef', 0, 15, _ivDef.toDouble(),
              (v) => setState(() => _ivDef = v.round())),
            Divider(height: 1, color: scheme.outlineVariant),
            _sliderRow(context, 'IV HP', '$_ivHp', 0, 15, _ivHp.toDouble(),
              (v) => setState(() => _ivHp = v.round())),
          ]),
        ),
        const SizedBox(height: 24),
        // Resultado
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.primary.withOpacity(0.3)),
          ),
          child: Column(children: [
            Text('$_cpResult',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700,
                color: scheme.primary)),
            Text('Combat Power',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('CP Máximo (Nível 40, 15/15/15): $_maxCp',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ]),
        ),
      ]),
    );
  }

  Widget _statInput(BuildContext context, TextEditingController ctrl, String label) =>
    TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    );

  Widget _sliderRow(BuildContext context, String label, String valStr,
      num min, num max, double val, ValueChanged<double> onChanged) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(valStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        Slider(value: val, min: min.toDouble(), max: max.toDouble(),
          divisions: (max - min).round(), onChanged: onChanged),
      ]),
    );
}