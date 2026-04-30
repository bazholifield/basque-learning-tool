import 'package:go_router/go_router.dart';
import 'package:basque/features/vocab/screens/vocab_screen.dart';
import 'package:basque/features/conjugation/screens/conjugation_screen.dart';
import 'package:basque/features/declension/screens/declension_screen.dart';
import 'package:basque/features/translator/screens/translator_screen.dart';
import 'package:basque/features/writing/screens/writing_screen.dart';
import 'package:basque/features/reading/screens/reading_screen.dart';
import 'package:basque/home_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/vocab', builder: (_, _) => const VocabScreen()),
    GoRoute(path: '/conjugation', builder: (_, _) => const ConjugationScreen()),
    GoRoute(path: '/declension', builder: (_, _) => const DeclensionScreen()),
    GoRoute(path: '/translator', builder: (_, _) => const TranslatorScreen()),
    GoRoute(path: '/writing', builder: (_, _) => const WritingScreen()),
    GoRoute(path: '/reading', builder: (_, _) => const ReadingScreen()),
  ],
);
