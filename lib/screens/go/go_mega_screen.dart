import 'package:flutter/material.dart';

// Megas disponíveis no Pokémon GO (março 2026)
// Fonte: Bulbapedia - List of Pokémon with Mega Evolutions in GO
const _goMegas = [
  _GoMega(baseId: 3,   name: 'Mega Venusaur',    spriteId: 10033),
  _GoMega(baseId: 6,   name: 'Mega Charizard X',  spriteId: 10034),
  _GoMega(baseId: 6,   name: 'Mega Charizard Y',  spriteId: 10035),
  _GoMega(baseId: 9,   name: 'Mega Blastoise',    spriteId: 10036),
  _GoMega(baseId: 15,  name: 'Mega Beedrill',     spriteId: 10055),
  _GoMega(baseId: 18,  name: 'Mega Pidgeot',      spriteId: 10073),
  _GoMega(baseId: 65,  name: 'Mega Alakazam',     spriteId: 10037),
  _GoMega(baseId: 94,  name: 'Mega Gengar',       spriteId: 10038),
  _GoMega(baseId: 115, name: 'Mega Kangaskhan',   spriteId: 10039),
  _GoMega(baseId: 127, name: 'Mega Pinsir',       spriteId: 10041),
  _GoMega(baseId: 130, name: 'Mega Gyarados',     spriteId: 10042),
  _GoMega(baseId: 142, name: 'Mega Aerodactyl',   spriteId: 10043),
  _GoMega(baseId: 150, name: 'Mega Mewtwo X',     spriteId: 10044),
  _GoMega(baseId: 150, name: 'Mega Mewtwo Y',     spriteId: 10045),
  _GoMega(baseId: 181, name: 'Mega Ampharos',     spriteId: 10046),
  _GoMega(baseId: 208, name: 'Mega Steelix',      spriteId: 10072),
  _GoMega(baseId: 212, name: 'Mega Scizor',       spriteId: 10047),
  _GoMega(baseId: 214, name: 'Mega Heracross',    spriteId: 10056),
  _GoMega(baseId: 229, name: 'Mega Houndoom',     spriteId: 10048),
  _GoMega(baseId: 248, name: 'Mega Tyranitar',    spriteId: 10049),
  _GoMega(baseId: 254, name: 'Mega Sceptile',     spriteId: 10077),
  _GoMega(baseId: 257, name: 'Mega Blaziken',     spriteId: 10078),
  _GoMega(baseId: 260, name: 'Mega Swampert',     spriteId: 10079),
  _GoMega(baseId: 282, name: 'Mega Gardevoir',    spriteId: 10082),
  _GoMega(baseId: 302, name: 'Mega Sableye',      spriteId: 10080),
  _GoMega(baseId: 303, name: 'Mega Mawile',       spriteId: 10081),
  _GoMega(baseId: 306, name: 'Mega Aggron',       spriteId: 10083),
  _GoMega(baseId: 308, name: 'Mega Medicham',     spriteId: 10084),
  _GoMega(baseId: 310, name: 'Mega Manectric',    spriteId: 10085),
  _GoMega(baseId: 319, name: 'Mega Sharpedo',     spriteId: 10087),
  _GoMega(baseId: 323, name: 'Mega Camerupt',     spriteId: 10088),
  _GoMega(baseId: 334, name: 'Mega Altaria',      spriteId: 10089),
  _GoMega(baseId: 354, name: 'Mega Banette',      spriteId: 10090),
  _GoMega(baseId: 359, name: 'Mega Absol',        spriteId: 10091),
  _GoMega(baseId: 362, name: 'Mega Glalie',       spriteId: 10075),
  _GoMega(baseId: 373, name: 'Mega Salamence',    spriteId: 10094),
  _GoMega(baseId: 376, name: 'Mega Metagross',    spriteId: 10095),
  _GoMega(baseId: 380, name: 'Mega Latias',       spriteId: 10092),
  _GoMega(baseId: 381, name: 'Mega Latios',       spriteId: 10093),
  _GoMega(baseId: 382, name: 'Mega Kyogre',       spriteId: 10076), // Primal
  _GoMega(baseId: 383, name: 'Groudon Primal',    spriteId: 10074), // Primal
  _GoMega(baseId: 384, name: 'Mega Rayquaza',     spriteId: 10096),
  _GoMega(baseId: 428, name: 'Mega Lopunny',      spriteId: 10099),
  _GoMega(baseId: 445, name: 'Mega Garchomp',     spriteId: 10103),
  _GoMega(baseId: 448, name: 'Mega Lucario',      spriteId: 10100),
  _GoMega(baseId: 460, name: 'Mega Abomasnow',    spriteId: 10101),
  _GoMega(baseId: 475, name: 'Mega Gallade',      spriteId: 10109),
  _GoMega(baseId: 531, name: 'Mega Audino',       spriteId: 10110),
  _GoMega(baseId: 719, name: 'Mega Diancie',      spriteId: 10108),
];

class GoMegaScreen extends StatelessWidget {
  const GoMegaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mega Evoluções'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${_goMegas.length} Mega Evoluções disponíveis no Pokémon GO',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 8,
            mainAxisSpacing:  8,
          ),
          itemCount: _goMegas.length,
          itemBuilder: (context, i) => _MegaTile(mega: _goMegas[i], scheme: scheme),
        )),
      ]),
    );
  }
}

class _MegaTile extends StatelessWidget {
  final _GoMega     mega;
  final ColorScheme scheme;
  const _MegaTile({required this.mega, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset(
          'assets/sprites/artwork/${mega.baseId}.webp',
          width: 64, height: 64, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
              Icons.catching_pokemon, size: 40, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            mega.name,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

class _GoMega {
  final int    baseId;
  final String name;
  final int    spriteId;
  const _GoMega({required this.baseId, required this.name, required this.spriteId});
}
