import 'dart:convert';
import 'package:flutter/services.dart';

/// Acessa os dados locais de pokémon do arquivo assets/data/pokedex_data.json.
/// Carregado uma vez em memória ao iniciar o app — sem nenhuma chamada de rede.
class PokedexDataService {
  static const String _assetPath  = 'assets/data/pokedex_data.json';
  static const String _namesPath  = 'assets/data/pokemon_names.json';
  static const String _formsPath  = 'assets/data/forms_map.json';

  static PokedexDataService? _instance;
  static PokedexDataService get instance =>
      _instance ??= PokedexDataService._();
  PokedexDataService._();

  Map<int, Map<String, dynamic>> _data  = {};
  Map<int, String>               _names = {};
  // forms_map keyed por speciesId — lista de formas alternativas
  Map<int, List<dynamic>>        _forms = {};
  bool _loaded = false;

  /// Carrega o JSON do bundle em memória. Chamar uma vez no main().
  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = json.decode(raw) as Map<String, dynamic>;
      _data = decoded.map((k, v) =>
          MapEntry(int.parse(k), Map<String, dynamic>.from(v as Map)));

      final rawNames = await rootBundle.loadString(_namesPath);
      final decodedNames = json.decode(rawNames) as Map<String, dynamic>;
      _names = decodedNames.map((k, v) => MapEntry(int.parse(k), v as String));

      final rawForms = await rootBundle.loadString(_formsPath);
      final decodedForms = json.decode(rawForms) as Map<String, dynamic>;
      _forms = decodedForms.map((k, v) =>
          MapEntry(int.parse(k), v as List<dynamic>));

      _loaded = true;
    } catch (_) {}
  }

  bool get isLoaded => _loaded;

  /// Dados brutos de um pokémon (null se não carregado ou ID inválido)
  Map<String, dynamic>? get(int id) => _loaded ? _data[id] : null;

  // ─── Getters usados pelas telas de detalhe ─────────────────────

  List<String> getTypes(int id) =>
      (get(id)?['types'] as List<dynamic>?)?.cast<String>() ?? [];

  String getHeight(int id) =>
      get(id)?['height'] as String? ?? '—';

  String getWeight(int id) =>
      get(id)?['weight'] as String? ?? '—';

  String getCategory(int id) =>
      get(id)?['category'] as String? ?? '—';

  String getFlavorText(int id) =>
      get(id)?['flavorText'] as String? ?? '';

  String getGeneration(int id) =>
      get(id)?['generation'] as String? ?? '';

  int getCaptureRate(int id) =>
      get(id)?['captureRate'] as int? ?? 0;

  List<Map<String, dynamic>> getAbilities(int id) {
    final raw = get(id)?['abilities'] as List<dynamic>?;
    return raw?.map((a) => Map<String, dynamic>.from(a as Map)).toList() ?? [];
  }

  List<Map<String, dynamic>> getEvoChain(int id) {
    final raw = get(id)?['evoChain'] as List<dynamic>?;
    return raw?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
  }

  /// Lista de jogos onde o pokémon aparece (já ordenada cronologicamente)
  List<String> getGames(int id) {
    final raw = get(id)?['games'] as List<dynamic>?;
    return raw?.cast<String>() ?? [];
  }

  /// Nome em inglês no formato "Bulbasaur" (ex: para exibição na grid)
  String getName(int id) => _names[id] ?? '#$id';

  /// Retorna true se o pokémon tem formas alternativas no forms_map.json.
  /// Síncrono — pode ser chamado no initState sem async.
  bool hasForms(int id) {
    final list = _forms[id];
    return list != null && list.isNotEmpty;
  }

  /// Lista de formas alternativas para um pokémon.
  List<dynamic> getForms(int id) => _forms[id] ?? [];
}