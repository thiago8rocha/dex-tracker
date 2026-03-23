import 'package:flutter/material.dart';
import 'package:pokedex_tracker/services/tcg_pocket_service.dart';
import 'package:pokedex_tracker/screens/pocket/pocket_card_list_screen.dart';

// ─── HUB SCREEN ───────────────────────────────────────────────────

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

// ─── Grid de coleções ─────────────────────────────────────────────

class _SetGrid extends StatelessWidget {
  final List<PocketSet> sets;
  const _SetGrid({required this.sets});

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) {
      return const Center(child: Text('Nenhuma coleção encontrada'));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing:  12,
      ),
      itemCount: sets.length,
      itemBuilder: (context, i) => _SetBox(set: sets[i]),
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
    final color2 = Color(meta?.color2 ?? 0xFFF08030);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PocketCardListScreen(
            setId:   set.id,
            setName: set.name,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: [
              color1.withOpacity(0.85),
              color2.withOpacity(0.85),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Imagem do booster (fundo) ──
              Positioned.fill(
                child: Image.network(
                  TcgPocketService.boosterImageUrl(set.id),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : const SizedBox.shrink(),
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

              // ── Gradiente escurecendo a base para o texto ──
              Positioned(
                left: 0, right: 0, bottom: 0,
                height: 72,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end:   Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── ID da coleção (canto superior esquerdo) ──
              Positioned(
                top: 8, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    set.id,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // ── Nome da coleção (rodapé) ──
              Positioned(
                left: 10, right: 10, bottom: 10,
                child: Text(
                  set.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
          crossAxisCount: 2, childAspectRatio: 0.85,
          crossAxisSpacing: 12, mainAxisSpacing: 12,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: scheme.onSurface.withOpacity(_anim.value * 0.12),
            borderRadius: BorderRadius.circular(12),
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
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
        ],
      ),
    );
  }
}
