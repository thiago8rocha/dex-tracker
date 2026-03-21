import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Gerencia download e cache local de artwork sprites de pokémon.
///
/// Tipos:
///   'artwork' — official artwork (grid + detalhe) — cacheado localmente
///   'pixel'   — pixel sprite pequeno para silhueta/placeholder — cacheado localmente
///   outros    — shiny, home, etc. carregam via rede normalmente (já são rápidos)
///
/// Cache em disco: <appSupportDir>/sprites/{tipo}/{id}.png
class SpriteService {
  static SpriteService? _instance;
  static SpriteService get instance => _instance ??= SpriteService._();
  SpriteService._();

  static const String _base =
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon';

  // Notifica listeners quando um sprite é baixado: (id, tipo)
  final _downloaded = StreamController<(int, String)>.broadcast();
  Stream<(int, String)> get onDownloaded => _downloaded.stream;

  final _inProgress = <String>{};
  Directory? _cacheDir;

  Future<Directory> get _dir async {
    _cacheDir ??= Directory(
      '${(await getApplicationSupportDirectory()).path}/sprites',
    );
    return _cacheDir!;
  }

  String _url(int id, String type) {
    switch (type) {
      case 'pixel':   return '$_base/$id.png';
      case 'artwork':
      default:        return '$_base/other/official-artwork/$id.png';
    }
  }

  String _key(int id, String type) => '${type}_$id';

  /// Retorna o File do sprite se já estiver em cache, null caso contrário.
  Future<File?> getCached(int id, String type) async {
    final file = File('${(await _dir).path}/$type/$id.png');
    return (await file.exists()) ? file : null;
  }

  /// Baixa um sprite e salva em disco. Retorna o File ou null se falhar.
  Future<File?> download(int id, String type) async {
    final key = _key(id, type);
    if (_inProgress.contains(key)) return null;

    final file = File('${(await _dir).path}/$type/$id.png');
    if (await file.exists()) return file;

    _inProgress.add(key);
    try {
      await file.parent.create(recursive: true);
      final res = await http.get(Uri.parse(_url(id, type)))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(res.bodyBytes);
        _downloaded.add((id, type));
        return file;
      }
    } catch (_) {
    } finally {
      _inProgress.remove(key);
    }
    return null;
  }

  /// Baixa pixel sprites (para silhueta) e artwork da dex atual em paralelo.
  /// Os pixel são priorizados pois são muito menores (~2KB) e aparecem primeiro.
  /// Em seguida baixa artwork da dex e depois o restante em background.
  Future<void> prefetchDexWithFallback(List<int> ids) async {
    const batchSize = 20;

    // 1. Pixel da dex atual — muito rápido (~40KB total), serve de silhueta
    for (int i = 0; i < ids.length; i += batchSize) {
      final batch = ids.skip(i).take(batchSize).toList();
      await Future.wait(batch.map((id) => download(id, 'pixel')));
    }

    // 2. Artwork da dex atual — em background, sem bloquear a UI
    _downloadBackground(ids);
  }

  void _downloadBackground(List<int> priorityIds) async {
    const batchSize = 6;

    // Artwork dos pokémon da dex atual primeiro
    final allIds  = List.generate(1025, (i) => i + 1);
    final rest    = allIds.where((id) => !priorityIds.contains(id)).toList();
    final ordered = [...priorityIds, ...rest];

    for (int i = 0; i < ordered.length; i += batchSize) {
      final batch = ordered.skip(i).take(batchSize).toList();
      await Future.wait(batch.map((id) => download(id, 'artwork')));
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Verifica se uma amostra de sprites mudou no servidor (silent refresh).
  Future<List<int>> checkStaleSprites(List<int> sampleIds, String type) async {
    final stale = <int>[];
    for (final id in sampleIds) {
      final file = await getCached(id, type);
      if (file == null) continue;
      try {
        final res = await http.head(Uri.parse(_url(id, type)))
            .timeout(const Duration(seconds: 5));
        final remoteSize = int.tryParse(res.headers['content-length'] ?? '') ?? 0;
        final localSize  = await file.length();
        if (remoteSize > 0 && remoteSize != localSize) stale.add(id);
      } catch (_) {}
    }
    return stale;
  }

  /// Tamanho total do cache em bytes.
  Future<int> cacheSize() async {
    final dir = await _dir;
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  /// Limpa todo o cache de sprites.
  Future<void> clearCache() async {
    final dir = await _dir;
    if (await dir.exists()) await dir.delete(recursive: true);
    _cacheDir = null;
  }
}