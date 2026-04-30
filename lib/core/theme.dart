import 'package:flutter/material.dart';

const _seed = Color(0xFF2E7D32); // forest green — nod to the Basque flag

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _seed),
);

final appThemeDark = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
);
