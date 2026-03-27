import 'package:flutter/material.dart';

class TypeColors {
  static const Map<String, Color> colors = {
    'Normal':   Color.fromRGBO(144, 153, 161, 1),
    'Fogo':     Color.fromRGBO(255, 159,  90, 1),
    'Água':     Color.fromRGBO( 77, 144, 213, 1),
    'Elétrico': Color.fromRGBO(243, 210,  59, 1),
    'Planta':   Color.fromRGBO(104, 189,  96, 1),
    'Gelo':     Color.fromRGBO(118, 206, 193, 1),
    'Lutador':  Color.fromRGBO(207,  68, 108, 1),
    'Veneno':   Color.fromRGBO(171, 107, 200, 1),
    'Terreno':  Color.fromRGBO(217, 121,  73, 1),
    'Voador':   Color.fromRGBO(148, 171, 222, 1),
    'Psíquico': Color.fromRGBO(249, 113, 118, 1),
    'Inseto':   Color.fromRGBO(144, 193,  45, 1),
    'Pedra':    Color.fromRGBO(199, 183, 139, 1),
    'Fantasma': Color.fromRGBO( 82, 105, 172, 1),
    'Dragão':   Color.fromRGBO(  9, 109, 196, 1),
    'Sombrio':  Color.fromRGBO( 95,  88, 106, 1),
    'Aço':      Color.fromRGBO( 92, 143, 162, 1),
    'Fada':     Color.fromRGBO(236, 144, 230, 1),
  };

  static Color fromType(String type) {
    return colors[type] ?? const Color(0xFFA8A878);
  }
}