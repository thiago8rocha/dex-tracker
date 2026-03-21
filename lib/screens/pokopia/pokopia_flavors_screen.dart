import 'package:flutter/material.dart';

class PokopiaFlavorsScreen extends StatefulWidget {
  const PokopiaFlavorsScreen({super.key});

  @override
  State<PokopiaFlavorsScreen> createState() => _PokopiaFlavorsScreenState();
}

class _PokopiaFlavorsScreenState extends State<PokopiaFlavorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sabores e Mosslax'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Efeitos no Mosslax'),
            Tab(text: 'Receitas'),
          ],
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
          tabAlignment: TabAlignment.fill,
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _MosslaxTab(),
          _RecipesTab(),
        ],
      ),
    );
  }
}

// ─── ABA MOSSLAX ─────────────────────────────────────────────────

class _MosslaxTab extends StatelessWidget {
  const _MosslaxTab();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant, width: 0.5),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Alimente o Mosslax uma vez por dia para receber um buff ativo até as 05:00. '
              'O efeito depende do sabor do alimento oferecido. '
              'Comidas cozinhadas têm efeito mais forte que ingredientes crus.',
              style: TextStyle(fontSize: 12,
                  color: scheme.onSurfaceVariant, height: 1.4))),
          ]),
        ),
        const SizedBox(height: 16),

        ..._flavors.map((f) => _FlavorCard(data: f)),
      ]),
    );
  }
}

class _FlavorCard extends StatelessWidget {
  final _FlavorData data;
  const _FlavorCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Column(children: [
        // Cabeçalho
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: data.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(data.namePt,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text('(${data.nameEn})',
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
          ]),
        ),
        // Efeito
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Efeito  ',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            Expanded(child: Text(data.effect,
              style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w500, height: 1.4))),
          ]),
        ),
        // Exemplos de alimentos
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Exemplos  ',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            Expanded(child: Wrap(
              spacing: 5, runSpacing: 5,
              children: data.examples.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant, width: 0.5),
                ),
                child: Text(f, style: TextStyle(fontSize: 10, color: scheme.onSurface)),
              )).toList(),
            )),
          ]),
        ),
      ]),
    );
  }
}

// ─── ABA RECEITAS ────────────────────────────────────────────────

class _RecipesTab extends StatelessWidget {
  const _RecipesTab();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant, width: 0.5),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Chef Dente ensina as receitas durante suas quests em Rocky Ridges. '
              'Há 24 receitas divididas em 4 categorias. Comer comidas cozinhadas '
              'também faz upgrade das transformações do Ditto.',
              style: TextStyle(fontSize: 12,
                  color: scheme.onSurfaceVariant, height: 1.4))),
          ]),
        ),
        const SizedBox(height: 16),

        ..._recipeCategories.map((cat) => _RecipeCategory(data: cat)),
      ]),
    );
  }
}

class _RecipeCategory extends StatelessWidget {
  final _RecipeCategoryData data;
  const _RecipeCategory({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(data.icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(data.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: scheme.onSurfaceVariant)),
          const SizedBox(width: 6),
          Text('• ${data.station}',
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
        ]),
      ),
      ...data.recipes.map((r) => _RecipeTile(data: r)),
      const SizedBox(height: 16),
    ]);
  }
}

class _RecipeTile extends StatelessWidget {
  final _RecipeData data;
  const _RecipeTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(data.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600))),
          // Badge de sabor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _flavorColor(data.flavor).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(data.flavor,
              style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w600,
                color: _flavorColor(data.flavor))),
          ),
        ]),
        const SizedBox(height: 6),
        // Ingredientes
        Wrap(spacing: 6, runSpacing: 5,
          children: data.ingredients.map((i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outlineVariant, width: 0.5),
            ),
            child: Text(i,
              style: TextStyle(fontSize: 10, color: scheme.onSurface)),
          )).toList()),
        if (data.specialty != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.auto_awesome_outlined, size: 11, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('Requer especialidade: ${data.specialty}',
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
          ]),
        ],
      ]),
    );
  }

  Color _flavorColor(String flavor) {
    switch (flavor) {
      case 'Doce':    return const Color(0xFFE8517A);
      case 'Picante': return const Color(0xFFE85E30);
      case 'Azedo':   return const Color(0xFF5CB85C);
      case 'Amargo':  return const Color(0xFF8D6E63);
      case 'Seco':    return const Color(0xFF5B8DD9);
      default:        return const Color(0xFF9E9E9E);
    }
  }
}

// ─── DADOS ───────────────────────────────────────────────────────

class _FlavorData {
  final String namePt;
  final String nameEn;
  final Color color;
  final String effect;
  final List<String> examples;
  const _FlavorData({
    required this.namePt,
    required this.nameEn,
    required this.color,
    required this.effect,
    required this.examples,
  });
}

const _flavors = [
  _FlavorData(
    namePt: 'Doce',
    nameEn: 'Sweet',
    color: Color(0xFFE8517A),
    effect: 'Aumenta a taxa de aparição de Pokémon nos habitats próximos.',
    examples: ['Leppa Berry', 'Pecha Berry', 'Fluffy Bread', 'Leppa Salad'],
  ),
  _FlavorData(
    namePt: 'Picante',
    nameEn: 'Spicy',
    color: Color(0xFFE85E30),
    effect: 'Aumenta a chance de encontrar Pokémon nos habitats. Melhor buff para preencher a Pokédex.',
    examples: ['Crouton Salad', 'Healthy Soup', 'Electrifying Soup', 'Carrot Bread'],
  ),
  _FlavorData(
    namePt: 'Azedo',
    nameEn: 'Sour',
    color: Color(0xFF5CB85C),
    effect: 'Aumenta a chance de encontrar Pokémon raros nos habitats.',
    examples: ['Shredded Salad', 'Flavourful Soup', 'Leppa Bread', 'Tomato Hamburger Steak'],
  ),
  _FlavorData(
    namePt: 'Amargo',
    nameEn: 'Bitter',
    color: Color(0xFF8D6E63),
    effect: 'Aumenta a chance de encontrar Ho-Oh e Lugia no céu (necessário para coletar Rainbow Feather e Silver Feather).',
    examples: ['Seaweed Salad', 'Seaweed Soup', 'Recycled Bread'],
  ),
  _FlavorData(
    namePt: 'Seco',
    nameEn: 'Dry',
    color: Color(0xFF5B8DD9),
    effect: 'Aumenta a chance de encontrar itens raros como Rainbow Feather e Silver Feather.',
    examples: ['Crushed-berry Salad', 'Mushroom Soup', 'Mushroom Hamburger Steak'],
  ),
  _FlavorData(
    namePt: 'Genérico',
    nameEn: 'Generic / No flavor',
    color: Color(0xFF9E9E9E),
    effect: 'Sem buff especial. Alimentos sem sabor definido.',
    examples: ['Simple Salad', 'Simple Soup', 'Simple Bread', 'Hamburger Steak'],
  ),
];

class _RecipeCategoryData {
  final String name;
  final IconData icon;
  final String station;
  final List<_RecipeData> recipes;
  const _RecipeCategoryData({
    required this.name,
    required this.icon,
    required this.station,
    required this.recipes,
  });
}

class _RecipeData {
  final String name;
  final String flavor;
  final List<String> ingredients;
  final String? specialty;
  const _RecipeData({
    required this.name,
    required this.flavor,
    required this.ingredients,
    this.specialty,
  });
}

const _recipeCategories = [
  _RecipeCategoryData(
    name: 'SALADAS',
    icon: Icons.grass_outlined,
    station: 'Chopping Board + Leaf',
    recipes: [
      _RecipeData(name: 'Simple Salad',        flavor: 'Genérico', ingredients: ['Leaf x1', 'Qualquer x1']),
      _RecipeData(name: 'Leppa Salad',          flavor: 'Doce',     ingredients: ['Leaf x1', 'Leppa Berry x1']),
      _RecipeData(name: 'Seaweed Salad',        flavor: 'Amargo',   ingredients: ['Leaf x1', 'Seaweed x1']),
      _RecipeData(name: 'Shredded Salad',       flavor: 'Azedo',    ingredients: ['Leaf x1', 'Qualquer x1'], specialty: 'Chop'),
      _RecipeData(name: 'Crushed-berry Salad',  flavor: 'Seco',     ingredients: ['Leaf x1', 'Chesto Berry x1'], specialty: 'Crush'),
      _RecipeData(name: 'Crouton Salad',        flavor: 'Picante',  ingredients: ['Leaf x1', 'Bread x1']),
    ],
  ),
  _RecipeCategoryData(
    name: 'SOPAS',
    icon: Icons.soup_kitchen_outlined,
    station: 'Cooking Pot + Fresh Water',
    recipes: [
      _RecipeData(name: 'Simple Soup',         flavor: 'Genérico', ingredients: ['Fresh Water x1', 'Qualquer x2']),
      _RecipeData(name: 'Seaweed Soup',        flavor: 'Amargo',   ingredients: ['Fresh Water x1', 'Seaweed x1', 'Qualquer x1']),
      _RecipeData(name: 'Mushroom Soup',       flavor: 'Seco',     ingredients: ['Fresh Water x1', 'Cave Mushrooms x1', 'Qualquer x1']),
      _RecipeData(name: 'Electrifying Soup',   flavor: 'Picante',  ingredients: ['Fresh Water x1', 'Qualquer x2'], specialty: 'Generate'),
      _RecipeData(name: 'Healthy Soup',        flavor: 'Picante',  ingredients: ['Fresh Water x1', 'Bean x1', 'Leaf x1']),
      _RecipeData(name: 'Flavourful Soup',     flavor: 'Azedo',    ingredients: ['Fresh Water x1', 'Aspear Berry x1', 'Hamburger Steak x1']),
    ],
  ),
  _RecipeCategoryData(
    name: 'PÃES',
    icon: Icons.bakery_dining_outlined,
    station: 'Bread Oven + Wheat',
    recipes: [
      _RecipeData(name: 'Simple Bread',    flavor: 'Genérico', ingredients: ['Wheat x1', 'Qualquer x2']),
      _RecipeData(name: 'Leppa Bread',     flavor: 'Azedo',    ingredients: ['Wheat x1', 'Leppa Berry x1', 'Qualquer x1']),
      _RecipeData(name: 'Carrot Bread',    flavor: 'Picante',  ingredients: ['Wheat x1', 'Carrot x1', 'Qualquer x1']),
      _RecipeData(name: 'Recycled Bread',  flavor: 'Amargo',   ingredients: ['Wheat x1', 'Carrot x1', 'Qualquer x1'], specialty: 'Recycle'),
      _RecipeData(name: 'Fluffy Bread',    flavor: 'Doce',     ingredients: ['Wheat x1', 'Pecha Berry x1', 'Qualquer x1'], specialty: 'Water'),
      _RecipeData(name: 'Bread Bowl',      flavor: 'Picante',  ingredients: ['Wheat x1', 'Soup x1', 'Qualquer x1'], specialty: 'Burn'),
    ],
  ),
  _RecipeCategoryData(
    name: 'HAMBURGER STEAKS',
    icon: Icons.lunch_dining_outlined,
    station: 'Frying Pan + Bean',
    recipes: [
      _RecipeData(name: 'Hamburger Steak',          flavor: 'Genérico', ingredients: ['Bean x1', 'Qualquer x3']),
      _RecipeData(name: 'Mushroom Hamburger Steak', flavor: 'Seco',     ingredients: ['Bean x1', 'Cave Mushrooms x1', 'Qualquer x2']),
      _RecipeData(name: 'Tomato Hamburger Steak',   flavor: 'Azedo',    ingredients: ['Bean x1', 'Tomato x1', 'Qualquer x2']),
      _RecipeData(name: 'Potato Hamburger Steak',   flavor: 'Picante',  ingredients: ['Bean x1', 'Potato x1', 'Qualquer x2'], specialty: 'Generate'),
      _RecipeData(name: 'Spicy Hamburger Steak',    flavor: 'Picante',  ingredients: ['Bean x1', 'Tamato Berry x1', 'Qualquer x2']),
      _RecipeData(name: 'Sweet Hamburger Steak',    flavor: 'Doce',     ingredients: ['Bean x1', 'Leppa Berry x1', 'Qualquer x2']),
    ],
  ),
];