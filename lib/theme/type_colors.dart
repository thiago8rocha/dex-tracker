import 'package:flutter/material.dart';

class TypeColors {
  static const Map<String, Color> colors = {
    'Normal':   Color(0xFFA8A878),
    'Fogo':     Color(0xFFF08030),
    'Água':     Color(0xFF6890F0),
    'Elétrico': Color(0xFFF8D030),
    'Planta':   Color(0xFF78C850),
    'Gelo':     Color(0xFF98D8D8),
    'Lutador':  Color(0xFFC03028),
    'Veneno':   Color(0xFFA040A0),
    'Terreno':  Color(0xFFE0C068),
    'Voador':   Color(0xFFA890F0),
    'Psíquico': Color(0xFFF85888),
    'Inseto':   Color(0xFFA8B820),
    'Pedra':    Color(0xFFB8A038),
    'Fantasma': Color(0xFF705898),
    'Dragão':   Color(0xFF7038F8),
    'Sombrio':  Color(0xFF705848),
    'Aço':      Color(0xFFB8B8D0),
    'Fada':     Color(0xFFEE99AC),
  };

  static Color fromType(String type) {
    return colors[type] ?? const Color(0xFFA8A878);
  }
}