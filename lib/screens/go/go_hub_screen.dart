import 'package:flutter/material.dart';
import 'package:pokedex_tracker/screens/pokedex_screen.dart';
import 'package:pokedex_tracker/screens/go/go_cp_calculator_screen.dart';
import 'package:pokedex_tracker/screens/go/go_raids_screen.dart';
import 'package:pokedex_tracker/screens/go/go_mega_screen.dart';
import 'package:pokedex_tracker/screens/go/go_gigantamax_screen.dart';
import 'package:pokedex_tracker/screens/go/go_regional_forms_screen.dart';

class GoHubScreen extends StatelessWidget {
  const GoHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    // Definição dos cards do hub
    // sprite: ID nacional do Pokémon representativo (usa assets/sprites/artwork/)
    // color: cor de fundo suave, não saturada
    final cards = [
      _CardDef(
        title:    'Pokédex GO',
        subtitle: 'Registre seus Pokémon capturados',
        spriteId: 133, // Eevee — representa a diversidade do GO
        color:    isDark ? const Color(0xFF1A3A2A) : const Color(0xFFE8F5E9),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const PokedexScreen(
            pokedexId:    'pokémon_go',
            pokedexName:  'Pokémon GO',
            totalPokemon: 941,
          ),
        )),
      ),
      _CardDef(
        title:    'Calculadora de CP',
        subtitle: 'Calcule CP por IVs e nível',
        spriteId: 147, // Dratini — represents CP math
        color:    isDark ? const Color(0xFF1A2A3A) : const Color(0xFFE3F2FD),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const GoCpCalculatorScreen(),
        )),
      ),
      _CardDef(
        title:    'Raids Ativos',
        subtitle: 'Chefes de raid disponíveis agora',
        spriteId: 249, // Lugia — lendário icônico de raids
        color:    isDark ? const Color(0xFF2A1A3A) : const Color(0xFFEDE7F6),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const GoRaidsScreen(),
        )),
      ),
      _CardDef(
        title:    'Mega Evoluções',
        subtitle: 'Megas disponíveis no GO',
        spriteId: 6,   // Charizard — ícone mais famoso de Mega
        color:    isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEE),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const GoMegaScreen(),
        )),
      ),
      _CardDef(
        title:    'Gigantamax',
        subtitle: 'Formas Gigantamax no GO',
        spriteId: 143, // Snorlax — primeiro Gigantamax do GO
        color:    isDark ? const Color(0xFF2A2A1A) : const Color(0xFFFFFDE7),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const GoGigantamaxScreen(),
        )),
      ),
      _CardDef(
        title:    'Formas Regionais',
        subtitle: 'Alola, Galar, Hisui e variantes',
        spriteId: 26,  // Raichu de Alola (ID 26 = Raichu, forma Alola no GO)
        color:    isDark ? const Color(0xFF1A3A3A) : const Color(0xFFE0F7FA),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const GoRegionalFormsScreen(),
        )),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon GO'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   2,
          crossAxisSpacing: 12,
          mainAxisSpacing:  12,
          childAspectRatio: 1.0,
        ),
        itemCount: cards.length,
        itemBuilder: (context, i) => _HubCard(def: cards[i]),
      ),
    );
  }
}

// ─── Definição de card ────────────────────────────────────────────

class _CardDef {
  final String        title;
  final String        subtitle;
  final int           spriteId;
  final Color         color;
  final VoidCallback  onTap;

  const _CardDef({
    required this.title,
    required this.subtitle,
    required this.spriteId,
    required this.color,
    required this.onTap,
  });
}

// ─── Widget do card ───────────────────────────────────────────────

class _HubCard extends StatelessWidget {
  final _CardDef def;
  const _HubCard({required this.def});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
          child: Stack(
            children: [
              // Sprite como imagem de fundo
              Positioned(
                right: -12,
                bottom: -8,
                child: Opacity(
                  opacity: 0.22,
                  child: Image.asset(
                    'assets/sprites/artwork/${def.spriteId}.webp',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 110, height: 110),
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
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: scheme.onSurface.withOpacity(0.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
