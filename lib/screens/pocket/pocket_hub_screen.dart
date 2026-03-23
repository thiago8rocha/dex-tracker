import 'package:flutter/material.dart';
import 'package:pokedex_tracker/services/tcg_pocket_service.dart';
import 'package:pokedex_tracker/screens/pocket/pocket_card_list_screen.dart';

class PocketHubScreen extends StatefulWidget {
  const PocketHubScreen({super.key});

  @override
  State<PocketHubScreen> createState() => _PocketHubScreenState();
}

class _PocketHubScreenState extends State<PocketHubScreen> {
  List<PocketSet> _sets = [];
  // Mapa setId → URL da imagem do booster (carregada em background)
  final Map<String, String?> _boosterArt = {};
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    setState(() { _loading = true; _error = null; _boosterArt.clear(); });
    try {
      final sets = await TcgPocketService.fetchSeries();
      if (!mounted) return;
      setState(() { _sets = sets; _loading = false; });
      _loadBoosterArts(sets);
    } catch (_) {
      if (mounted) setState(() { _error = 'Erro ao carregar coleções'; _loading = false; });
    }
  }

  Future<void> _loadBoosterArts(List<PocketSet> sets) async {
    for (final s in sets) {
      final full = await TcgPocketService.fetchSet(s.id);
      if (!mounted) return;
      // Preferência: artwork do booster → logo do set
      final art = full?.firstBoosterArtwork ?? full?.logoImageUrl;
      if (mounted) setState(() => _boosterArt[s.id] = art);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TCG Pocket'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const _HubSkeleton()
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadSets)
              : _SetGrid(sets: _sets, boosterArt: _boosterArt),
    );
  }
}

// ─── Grid ─────────────────────────────────────────────────────────

class _SetGrid extends StatelessWidget {
  final List<PocketSet>      sets;
  final Map<String, String?> boosterArt;
  const _SetGrid({required this.sets, required this.boosterArt});

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) return const Center(child: Text('Nenhuma coleção encontrada'));
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.82,
        crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: sets.length,
      itemBuilder: (_, i) => _SetBox(set: sets[i], imageUrl: boosterArt[sets[i].id]),
    );
  }
}

// ─── Caixa de coleção ─────────────────────────────────────────────

class _SetBox extends StatelessWidget {
  final PocketSet set;
  final String?   imageUrl;
  const _SetBox({required this.set, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final meta   = kPocketSetMeta[set.id];
    final color1 = Color(meta?.color1 ?? 0xFF7038F8);
    final color2 = Color(meta?.color2 ?? 0xFFF08030);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => PocketCardListScreen(setId: set.id, setName: set.name),
      )),
      child: Container(
        // borderRadius: 4 — padrão retangular do projeto
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [color1, color2],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cabeçalho: ID e nome em destaque ──────────────
              Container(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
                color: Colors.black.withOpacity(0.38),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID pequeno acima
                    Text(
                      set.id,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Nome em destaque
                    Text(
                      set.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ── Imagem do pacote booster ───────────────────────
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Fundo de degradê
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [color1.withOpacity(0.5), color2.withOpacity(0.5)],
                        ),
                      ),
                    ),
                    // Imagem
                    if (imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, p) =>
                              p == null ? child : const SizedBox.shrink(),
                          errorBuilder: (_, __, ___) =>
                              _FallbackIcon(color: Colors.white),
                        ),
                      )
                    else
                      _FallbackIcon(color: Colors.white),
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

class _FallbackIcon extends StatelessWidget {
  final Color color;
  const _FallbackIcon({required this.color});
  @override
  Widget build(BuildContext context) => Center(
    child: Icon(Icons.style_outlined, size: 40, color: color.withOpacity(0.3)));
}

// ─── Skeleton ────────────────────────────────────────────────────

class _HubSkeleton extends StatefulWidget {
  const _HubSkeleton();
  @override State<_HubSkeleton> createState() => _HubSkeletonState();
}

class _HubSkeletonState extends State<_HubSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>    _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.82,
          crossAxisSpacing: 12, mainAxisSpacing: 12,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: scheme.onSurface.withOpacity(_anim.value * 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

// ─── Error view ──────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
      const SizedBox(height: 12),
      Text(message),
      const SizedBox(height: 16),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
        onPressed: onRetry,
        child: const Text('Tentar novamente'),
      ),
    ]),
  );
}
