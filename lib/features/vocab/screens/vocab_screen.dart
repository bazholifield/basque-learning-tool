import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import 'package:basque/core/api_client.dart';

// SM-2 flashcard state stored in Hive
class FlashcardState {
  int repetitions;
  double easeFactor;
  int intervalDays;
  DateTime? nextReview;

  FlashcardState()
      : repetitions = 0,
        easeFactor = 2.5,
        intervalDays = 1;

  void review(int quality) {
    if (quality >= 3) {
      if (repetitions == 0) {
        intervalDays = 1;
      } else if (repetitions == 1) {
        intervalDays = 6;
      } else {
        intervalDays = (intervalDays * easeFactor).round();
      }
      repetitions++;
      easeFactor = max(1.3, easeFactor + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    } else {
      repetitions = 0;
      intervalDays = 1;
    }
    nextReview = DateTime.now().add(Duration(days: intervalDays));
  }
}

final _vocabProvider = FutureProvider<Map<String, List>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final res = await dio.get('/vocab');
  return Map<String, List>.from(res.data);
});

class VocabScreen extends ConsumerStatefulWidget {
  const VocabScreen({super.key});

  @override
  ConsumerState<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends ConsumerState<VocabScreen> {
  String? _category;
  List<List<String>> _cards = [];
  int _index = 0;
  bool _flipped = false;
  int _correct = 0;
  int _total = 0;
  final _box = Hive.box('flashcards');

  void _loadCategory(String category, Map<String, List> data) {
    final raw = data[category] ?? [];
    setState(() {
      _category = category;
      _cards = raw.map<List<String>>((e) {
        final pair = e as List;
        return [pair[0].toString(), pair[1].toString()];
      }).toList()..shuffle();
      _index = 0;
      _flipped = false;
      _correct = 0;
      _total = 0;
    });
  }

  void _rate(int quality) {
    if (_cards.isEmpty) return;
    final key = '${_category}_${_cards[_index][0]}';
    final state = FlashcardState()..repetitions = _box.get('$key.reps', defaultValue: 0)
      ..easeFactor = _box.get('$key.ef', defaultValue: 2.5)
      ..intervalDays = _box.get('$key.interval', defaultValue: 1);
    state.review(quality);
    _box.put('$key.reps', state.repetitions);
    _box.put('$key.ef', state.easeFactor);
    _box.put('$key.interval', state.intervalDays);
    if (quality >= 3) setState(() => _correct++);
    setState(() {
      _total++;
      _flipped = false;
      _index = (_index + 1) % _cards.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vocabAsync = ref.watch(_vocabProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Vocabulary')),
      body: vocabAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          if (_category == null) {
            return _CategoryPicker(categories: data.keys.toList(), onSelect: (c) => _loadCategory(c, data));
          }
          if (_cards.isEmpty) return const Center(child: Text('No cards in this category.'));
          final card = _cards[_index];
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _category = null),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(_category!),
                    ),
                    const Spacer(),
                    Text('$_correct / $_total', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _flipped = !_flipped),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _FlashCard(
                        key: ValueKey(_flipped),
                        text: _flipped ? card[1] : card[0],
                        subtitle: _flipped ? 'Basque' : 'English — tap to flip',
                      ),
                    ),
                  ),
                ),
                if (_flipped) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => _rate(1), child: const Text('Hard'))),
                      const SizedBox(width: 8),
                      Expanded(child: FilledButton.tonal(onPressed: () => _rate(3), child: const Text('Good'))),
                      const SizedBox(width: 8),
                      Expanded(child: FilledButton(onPressed: () => _rate(5), child: const Text('Easy'))),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text('Card ${_index + 1} of ${_cards.length}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<String> categories;
  final void Function(String) onSelect;
  const _CategoryPicker({required this.categories, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => ListTile(
        title: Text(categories[i][0].toUpperCase() + categories[i].substring(1)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => onSelect(categories[i]),
      ),
    );
  }
}

class _FlashCard extends StatelessWidget {
  final String text;
  final String subtitle;
  const _FlashCard({super.key, required this.text, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
