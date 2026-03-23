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
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    setState(() { _loading = true; _error = null; });
    try {
      final sets = await TcgPocketService.fetchSeries();
      if (mounted) setState(() { _sets = sets; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Erro ao carregar coleções'; _loading = false; });
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
              : _SetGrid(sets: _sets),
    );
  }
}

// ─── Grid ─────────────────────────────────────────────────────────

class _SetGrid extends StatelessWidget {
  final List<PocketSet> sets;
  const _SetGrid({required this.sets});

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
      itemBuilder: (_, i) => _SetBox(set: sets[i]),
    );
  }
}

// ─── Caixa de coleção ─────────────────────────────────────────────

class _SetBox extends StatelessWidget {
  final PocketSet set;
  const _SetBox({required this.set});

  @override
  Widget build(BuildContext context) {
    final meta   = kPocketSetMeta[set.id];
    final color1 = Color(meta?.color1 ?? 0xFF7038F8);
    final color2 = Color(meta?.color2 ?? 0xFF303030);

    // Imagem da primeira carta do set — é sempre a carta de capa do booster
    final packImageUrl = set.packCardImageUrl;

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
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Imagem da carta de capa do booster ──────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 42, 0, 0),
                child: Image.network(
                  packImageUrl,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  loadingBuilder: (_, child, p) =>
                      p == null ? child : const SizedBox.shrink(),
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.style_outlined, size: 40,
                        color: Colors.white.withOpacity(0.25)),
                  ),
                ),
              ),

              // ── Gradiente escurecendo o topo para o texto ────────
              Positioned(
                top: 0, left: 0, right: 0, height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Cabeçalho: ID + Nome sem nenhuma caixa/container ──
              Positioned(
                top: 9, left: 10, right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID — pequeno e semitransparente
                    Text(
                      set.id,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 0.8,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                      ),
                    ),
                    const SizedBox(height: 1),
                    // Nome — destaque total
                    Text(
                      set.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
