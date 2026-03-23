import 'package:flutter/material.dart';

// Formas alternativas disponíveis no Pokémon GO
// Separadas por categoria: Regional, Variantes de padrão, outras
class GoRegionalFormsScreen extends StatelessWidget {
  const GoRegionalFormsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Formas Alternativas'),
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Regionais'),
              Tab(text: 'Variantes'),
              Tab(text: 'Outras'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        body: const TabBarView(children: [
          _RegionalTab(),
          _VariantsTab(),
          _OtherFormsTab(),
        ]),
      ),
    );
  }
}

// ─── ABA: Formas Regionais ────────────────────────────────────────

class _RegionalTab extends StatelessWidget {
  const _RegionalTab();

  // Formas regionais por origem
  static const _sections = [
    _FormSection('Alola', [
      _FormEntry(26,  'Raichu de Alola',    'Elétrico / Psíquico'),
      _FormEntry(27,  'Sandshrew de Alola', 'Gelo / Aço'),
      _FormEntry(28,  'Sandslash de Alola', 'Gelo / Aço'),
      _FormEntry(37,  'Vulpix de Alola',    'Gelo'),
      _FormEntry(38,  'Ninetales de Alola', 'Gelo / Fada'),
      _FormEntry(50,  'Diglett de Alola',   'Terra / Aço'),
      _FormEntry(51,  'Dugtrio de Alola',   'Terra / Aço'),
      _FormEntry(52,  'Meowth de Alola',    'Sombrio'),
      _FormEntry(53,  'Persian de Alola',   'Sombrio'),
      _FormEntry(74,  'Geodude de Alola',   'Pedra / Elétrico'),
      _FormEntry(75,  'Graveler de Alola',  'Pedra / Elétrico'),
      _FormEntry(76,  'Golem de Alola',     'Pedra / Elétrico'),
      _FormEntry(88,  'Grimer de Alola',    'Venenoso / Sombrio'),
      _FormEntry(89,  'Muk de Alola',       'Venenoso / Sombrio'),
      _FormEntry(103, 'Exeggutor de Alola', 'Planta / Dragão'),
      _FormEntry(105, 'Marowak de Alola',   'Fogo / Fantasma'),
    ]),
    _FormSection('Galar', [
      _FormEntry(52,  'Meowth de Galar',    'Aço'),
      _FormEntry(77,  'Ponyta de Galar',    'Psíquico'),
      _FormEntry(78,  'Rapidash de Galar',  'Psíquico / Fada'),
      _FormEntry(79,  'Slowpoke de Galar',  'Psíquico'),
      _FormEntry(80,  'Slowbro de Galar',   'Venenoso / Psíquico'),
      _FormEntry(83,  "Farfetch'd de Galar",'Lutador'),
      _FormEntry(110, 'Weezing de Galar',   'Venenoso / Fada'),
      _FormEntry(122, 'Mr. Mime de Galar',  'Gelo / Psíquico'),
      _FormEntry(144, 'Articuno de Galar',  'Psíquico / Voador'),
      _FormEntry(145, 'Zapdos de Galar',    'Lutador / Voador'),
      _FormEntry(146, 'Moltres de Galar',   'Sombrio / Voador'),
      _FormEntry(199, 'Slowking de Galar',  'Venenoso / Psíquico'),
      _FormEntry(222, 'Corsola de Galar',   'Fantasma'),
      _FormEntry(263, 'Zigzagoon de Galar', 'Sombrio / Normal'),
      _FormEntry(264, 'Linoone de Galar',   'Sombrio / Normal'),
    ]),
    _FormSection('Hisui', [
      _FormEntry(58,  'Growlithe de Hisui', 'Fogo / Pedra'),
      _FormEntry(59,  'Arcanine de Hisui',  'Fogo / Pedra'),
      _FormEntry(100, 'Voltorb de Hisui',   'Elétrico / Planta'),
      _FormEntry(101, 'Electrode de Hisui', 'Elétrico / Planta'),
      _FormEntry(157, 'Typhlosion de Hisui','Fogo / Fantasma'),
      _FormEntry(211, 'Qwilfish de Hisui',  'Sombrio / Venenoso'),
      _FormEntry(215, 'Sneasel de Hisui',   'Lutador / Venenoso'),
      _FormEntry(503, 'Samurott de Hisui',  'Água / Sombrio'),
      _FormEntry(549, 'Lilligant de Hisui', 'Planta / Lutador'),
      _FormEntry(570, 'Zorua de Hisui',     'Normal / Fantasma'),
      _FormEntry(571, 'Zoroark de Hisui',   'Normal / Fantasma'),
      _FormEntry(628, 'Braviary de Hisui',  'Psíquico / Voador'),
      _FormEntry(705, 'Sliggoo de Hisui',   'Aço / Dragão'),
      _FormEntry(706, 'Goodra de Hisui',    'Aço / Dragão'),
      _FormEntry(713, 'Avalugg de Hisui',   'Gelo / Pedra'),
      _FormEntry(724, 'Decidueye de Hisui', 'Planta / Lutador'),
    ]),
    _FormSection('Paldea', [
      _FormEntry(128, 'Tauros de Paldea',   'Lutador (3 formas)'),
      _FormEntry(194, 'Wooper de Paldea',   'Venenoso / Terra'),
      _FormEntry(195, 'Quagsire',           'Venenoso / Terra'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _sections.map((s) => _FormSectionWidget(section: s, scheme: scheme)).toList(),
    );
  }
}

// ─── ABA: Variantes de padrão ─────────────────────────────────────

class _VariantsTab extends StatelessWidget {
  const _VariantsTab();

  static const _sections = [
    _FormSection('Unown (28 formas)', [
      _FormEntry(201, 'Unown A–Z', 'Psíquico'),
      _FormEntry(201, 'Unown !', 'Psíquico'),
      _FormEntry(201, 'Unown ?', 'Psíquico'),
    ]),
    _FormSection('Vivillon (20 padrões)', [
      _FormEntry(666, 'Vivillon Icy Snow', 'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Polar',    'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Tundra',   'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Continental','Inseto / Voador'),
      _FormEntry(666, 'Vivillon Garden',   'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Elegant',  'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Meadow',   'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Modern',   'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Marine',   'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Archipelago','Inseto / Voador'),
      _FormEntry(666, 'Vivillon High Plains','Inseto / Voador'),
      _FormEntry(666, 'Vivillon Sandstorm','Inseto / Voador'),
      _FormEntry(666, 'Vivillon River',    'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Monsoon',  'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Savanna',  'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Sun',      'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Ocean',    'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Jungle',   'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Fancy',    'Inseto / Voador'),
      _FormEntry(666, 'Vivillon Poké Ball','Inseto / Voador'),
    ]),
    _FormSection('Flabébé / Floette / Florges (5 cores)', [
      _FormEntry(669, 'Flabébé Vermelho',   'Fada'),
      _FormEntry(669, 'Flabébé Amarelo',    'Fada'),
      _FormEntry(669, 'Flabébé Laranja',    'Fada'),
      _FormEntry(669, 'Flabébé Azul',       'Fada'),
      _FormEntry(669, 'Flabébé Branco',     'Fada'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _sections.map((s) => _FormSectionWidget(section: s, scheme: scheme)).toList(),
    );
  }
}

// ─── ABA: Outras formas ───────────────────────────────────────────

class _OtherFormsTab extends StatelessWidget {
  const _OtherFormsTab();

  static const _sections = [
    _FormSection('Castform (4 formas)', [
      _FormEntry(351, 'Castform Normal',    'Normal'),
      _FormEntry(351, 'Castform Sunny',     'Fogo'),
      _FormEntry(351, 'Castform Rainy',     'Água'),
      _FormEntry(351, 'Castform Snowy',     'Gelo'),
    ]),
    _FormSection('Deoxys (4 formas)', [
      _FormEntry(386, 'Deoxys Normal',      'Psíquico'),
      _FormEntry(386, 'Deoxys Attack',      'Psíquico'),
      _FormEntry(386, 'Deoxys Defense',     'Psíquico'),
      _FormEntry(386, 'Deoxys Speed',       'Psíquico'),
    ]),
    _FormSection('Rotom (6 formas)', [
      _FormEntry(479, 'Rotom Normal',       'Elétrico / Fantasma'),
      _FormEntry(479, 'Rotom Heat',         'Elétrico / Fogo'),
      _FormEntry(479, 'Rotom Wash',         'Elétrico / Água'),
      _FormEntry(479, 'Rotom Frost',        'Elétrico / Gelo'),
      _FormEntry(479, 'Rotom Fan',          'Elétrico / Voador'),
      _FormEntry(479, 'Rotom Mow',          'Elétrico / Planta'),
    ]),
    _FormSection('Giratina (2 formas)', [
      _FormEntry(487, 'Giratina Altered',   'Fantasma / Dragão'),
      _FormEntry(487, 'Giratina Origin',    'Fantasma / Dragão'),
    ]),
    _FormSection('Shaymin (2 formas)', [
      _FormEntry(492, 'Shaymin Land',       'Planta'),
      _FormEntry(492, 'Shaymin Sky',        'Planta / Voador'),
    ]),
    _FormSection('Tornadus / Thundurus / Landorus (2 formas)', [
      _FormEntry(641, 'Tornadus Incarnate', 'Voador'),
      _FormEntry(641, 'Tornadus Therian',   'Voador'),
      _FormEntry(642, 'Thundurus Incarnate','Elétrico / Voador'),
      _FormEntry(642, 'Thundurus Therian',  'Elétrico / Voador'),
      _FormEntry(645, 'Landorus Incarnate', 'Terra / Voador'),
      _FormEntry(645, 'Landorus Therian',   'Terra / Voador'),
    ]),
    _FormSection('Kyurem (3 formas)', [
      _FormEntry(646, 'Kyurem Normal',      'Dragão / Gelo'),
      _FormEntry(646, 'Kyurem Black',       'Dragão / Gelo'),
      _FormEntry(646, 'Kyurem White',       'Dragão / Gelo'),
    ]),
    _FormSection('Zygarde (3 formas)', [
      _FormEntry(718, 'Zygarde 10%',        'Dragão / Terra'),
      _FormEntry(718, 'Zygarde 50%',        'Dragão / Terra'),
      _FormEntry(718, 'Zygarde Complete',   'Dragão / Terra'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _sections.map((s) => _FormSectionWidget(section: s, scheme: scheme)).toList(),
    );
  }
}

// ─── Widgets compartilhados ───────────────────────────────────────

class _FormSectionWidget extends StatelessWidget {
  final _FormSection section;
  final ColorScheme  scheme;
  const _FormSectionWidget({required this.section, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(section.title, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant)),
      ),
      ...section.forms.map((f) => _FormTile(form: f, scheme: scheme)),
      const SizedBox(height: 16),
    ]);
  }
}

class _FormTile extends StatelessWidget {
  final _FormEntry  form;
  final ColorScheme scheme;
  const _FormTile({required this.form, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Row(children: [
        Image.asset(
          'assets/sprites/artwork/${form.baseId}.webp',
          width: 40, height: 40, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => SizedBox(width: 40, height: 40,
            child: Icon(Icons.catching_pokemon,
                size: 24, color: scheme.onSurfaceVariant.withOpacity(0.4))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(form.name, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600)),
          Text(form.types, style: TextStyle(
              fontSize: 11, color: scheme.onSurfaceVariant)),
        ])),
      ]),
    );
  }
}

// ─── Modelos ──────────────────────────────────────────────────────

class _FormSection {
  final String           title;
  final List<_FormEntry> forms;
  const _FormSection(this.title, this.forms);
}

class _FormEntry {
  final int    baseId;
  final String name;
  final String types;
  const _FormEntry(this.baseId, this.name, this.types);
}
