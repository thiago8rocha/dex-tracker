import 'package:flutter/material.dart';
import 'package:pokedex_tracker/screens/pokedex_screen.dart';
import 'package:pokedex_tracker/screens/pokopia/pokopia_specialties_screen.dart';
import 'package:pokedex_tracker/screens/pokopia/pokopia_flavors_screen.dart';
import 'package:pokedex_tracker/screens/pokopia/pokopia_relics_screen.dart';
import 'package:pokedex_tracker/screens/pokopia/pokopia_habitats_screen.dart';

class PokopiaHubScreen extends StatelessWidget {
  const PokopiaHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    final cards = [
      _CardDef(
        title:    'Pokédex',
        subtitle: '304 Pokémon de Pokopia',
        // Caterpie (10) — representa os amigos do jogo
        bgSprite: const _SpriteAsset.artwork(10),
        color: isDark ? const Color(0xFF1A3A1A) : const Color(0xFFE8F5E9),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const PokedexScreen(
            pokedexId:    'pokopia',
            pokedexName:  'Pokopia',
            totalPokemon: 304,
          ),
        )),
      ),
      _CardDef(
        title:    'Habitats',
        subtitle: '200 locais e seus Pokémon',
        // Oddish (43) — planta, representa habitat natural
        bgSprite: const _SpriteAsset.artwork(43),
        color: isDark ? const Color(0xFF1A2A3A) : const Color(0xFFE3F2FD),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const PokopiaHabitatsScreen(),
        )),
      ),
      _CardDef(
        title:    'Especialidades',
        subtitle: '31 especialidades',
        // Usar ícone de especialidade "grow" como imagem de fundo
        bgSprite: const _SpriteAsset.specialty('grow'),
        color: isDark ? const Color(0xFF2A1A3A) : const Color(0xFFF3E5F5),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const PokopiaSpecialtiesScreen(),
        )),
      ),
      _CardDef(
        title:    'Sabores e Mosslax',
        subtitle: 'Efeitos e receitas do Chef Dente',
        // Mosslax = Snorlax (143)
        bgSprite: const _SpriteAsset.artwork(143),
        color: isDark ? const Color(0xFF2A2A1A) : const Color(0xFFFFF8E1),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const PokopiaFlavorsScreen(),
        )),
      ),
      _CardDef(
        title:    'Relíquias',
        subtitle: 'Avaliadas pelo Prof. Tangrowth',
        // Tangrowth (465) = Professor Tangrowth
        bgSprite: const _SpriteAsset.artwork(465),
        color: isDark ? const Color(0xFF3A2A1A) : const Color(0xFFFBE9E7),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const PokopiaRelicsScreen(),
        )),
      ),
      _CardDef(
        title:    'Fósseis',
        subtitle: 'Fósseis encontrados em Pokopia',
        // Aerodactyl (142) — ícone clássico de fóssil
        bgSprite: const _SpriteAsset.artwork(142),
        color: isDark ? const Color(0xFF2A1A1A) : const Color(0xFFFFEBEE),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const PokopiaRelicsScreen(),
        )),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokopia'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Disclaimer
          Container(
            color: scheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Icon(Icons.info_outline, size: 14,
                  color: scheme.onSurfaceVariant.withOpacity(0.7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Os dados de Pokopia ainda estão sendo adicionados e atualizados.',
                  style: TextStyle(fontSize: 11,
                      color: scheme.onSurfaceVariant.withOpacity(0.8),
                      height: 1.3),
                ),
              ),
            ]),
          ),

          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   2,
                crossAxisSpacing: 12,
                mainAxisSpacing:  12,
                childAspectRatio: 1.0,
              ),
              itemCount: cards.length,
              itemBuilder: (context, i) =>
                  _HubCard(def: cards[i], scheme: scheme),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tipos de imagem de fundo ─────────────────────────────────────

class _SpriteAsset {
  final String path;
  const _SpriteAsset.artwork(int id) : path = 'assets/sprites/artwork/$id.webp';
  const _SpriteAsset.specialty(String name)
      : path = 'assets/pokopia/specialties/$name.png';
}

// ─── Definição de card ────────────────────────────────────────────

class _CardDef {
  final String       title;
  final String       subtitle;
  final _SpriteAsset bgSprite;
  final Color        color;
  final VoidCallback onTap;

  const _CardDef({
    required this.title,
    required this.subtitle,
    required this.bgSprite,
    required this.color,
    required this.onTap,
  });
}

// ─── Widget do card ───────────────────────────────────────────────

class _HubCard extends StatelessWidget {
  final _CardDef    def;
  final ColorScheme scheme;
  const _HubCard({required this.def, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: def.onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        def.color,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(
            color: scheme.outlineVariant.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [

            // Sprite como imagem de fundo
            Positioned(
              right: -10,
              bottom: -6,
              child: Opacity(
                opacity: 0.20,
                child: Image.asset(
                  def.bgSprite.path,
                  width:  110,
                  height: 110,
                  fit:    BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const SizedBox(width: 110, height: 110),
                ),
              ),
            ),

            // Conteúdo de texto
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    def.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    def.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.6),
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18,
                      color: scheme.onSurface.withOpacity(0.4)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
