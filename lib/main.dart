import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('flashcards');
  await Hive.openBox('settings');
  runApp(const ProviderScope(child: BasqueApp()));
}

class BasqueApp extends StatelessWidget {
  const BasqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Basque Trainer',
      theme: appTheme,
      darkTheme: appThemeDark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
