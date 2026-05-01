import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import 'package:basque/core/api_client.dart';

class FlashcardState {
  int repetitions;
  double easeFactor;
  int intervalDays;
  DateTime? nextReview;

  FlashcardState()
      : repetitions = 0,
        easeFactor = 2.5,
        intervalDays = 1,
        nextReview = null;

  static String hiveKey(String category, String englishWord) =>
      'vocab_${category}_$englishWord';

  static FlashcardState load(Box box, String category, String englishWord) {
    final k = hiveKey(category, englishWord);
    final state = FlashcardState();
    state.repetitions = box.get('$k.reps', defaultValue: 0);
    state.easeFactor = box.get('$k.ef', defaultValue: 2.5);
    state.intervalDays = box.get('$k.interval', defaultValue: 1);
    final stored = box.get('$k.nextReview') as String?;
    state.nextReview = stored != null ? DateTime.tryParse(stored) : null;
    return state;
  }

  void save(Box box, String category, String englishWord) {
    final k = hiveKey(category, englishWord);
    box.put('$k.reps', repetitions);
    box.put('$k.ef', easeFactor);
    box.put('$k.interval', intervalDays);
    if (nextReview != null) {
      box.put('$k.nextReview', nextReview!.toIso8601String());
    }
  }

  bool get isDue {
    if (nextReview == null) return true;
    return DateTime.now().isAfter(nextReview!);
  }

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
      easeFactor = max(
          1.3, easeFactor + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
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
  // [english, basque] pairs for the current due session
  List<List<String>> _session = [];
  int _index = 0;
  bool _flipped = false;
  int _correct = 0;
  bool _done = false;
  final _box = Hive.box('flashcards');

  void _loadCategory(String category, Map<String, List> data) {
    final raw = data[category] ?? [];
    final cards = raw.map<List<String>>((e) {
      final pair = e as List;
      return [pair[0].toString(), pair[1].toString()];
    }).toList();

    // Split into overdue, new, and future — session = overdue + new
    final overdue = <List<String>>[];
    final newCards = <List<String>>[];
    for (final card in cards) {
      final state = FlashcardState.load(_box, category, card[0]);
      if (state.nextReview == null) {
        newCards.add(card);
      } else if (state.isDue) {
        overdue.add(card);
      }
    }
    overdue.shuffle();
    newCards.shuffle();

    setState(() {
      _category = category;
      _session = [...overdue, ...newCards];
      _index = 0;
      _flipped = false;
      _correct = 0;
      _done = _session.isEmpty;
    });
  }

  void _rate(int quality) {
    if (_session.isEmpty) return;
    final card = _session[_index];
    final state = FlashcardState.load(_box, _category!, card[0]);
    state.review(quality);
    state.save(_box, _category!, card[0]);

    if (quality >= 3) _correct++;

    final next = _index + 1;
    setState(() {
      _flipped = false;
      if (next >= _session.length) {
        _done = true;
      } else {
        _index = next;
      }
    });
  }

  int _dueCount(String category, Map<String, List> data) {
    final raw = data[category] ?? [];
    return raw.where((e) {
      final pair = e as List;
      return FlashcardState.load(_box, category, pair[0].toString()).isDue;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final vocabAsync = ref.watch(_vocabProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary'),
        leading: _category != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _category = null;
                  _done = false;
                }),
              )
            : null,
      ),
      body: vocabAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          if (_category == null) {
            return _CategoryPicker(
              categories: data.keys.toList(),
              dueCount: (c) => _dueCount(c, data),
              onSelect: (c) => _loadCategory(c, data),
            );
          }

          if (_done) {
            return _CompletionScreen(
              correct: _correct,
              total: _session.length,
              onBack: () => setState(() {
                _category = null;
                _done = false;
              }),
              onPracticeAll: () => setState(() {
                final raw = data[_category!] ?? [];
                _session = raw.map<List<String>>((e) {
                  final pair = e as List;
                  return [pair[0].toString(), pair[1].toString()];
                }).toList()..shuffle();
                _index = 0;
                _flipped = false;
                _correct = 0;
                _done = false;
              }),
            );
          }

          final card = _session[_index];
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(_category!,
                        style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    Text('$_correct / ${_index + 1}  •  ${_index + 1} of ${_session.length}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _flipped = !_flipped),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _FlashCard(
                        key: ValueKey('${_index}_$_flipped'),
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
                      Expanded(
                          child: OutlinedButton(
                              onPressed: () => _rate(1),
                              child: const Text('Hard'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: FilledButton.tonal(
                              onPressed: () => _rate(3),
                              child: const Text('Good'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: FilledButton(
                              onPressed: () => _rate(5),
                              child: const Text('Easy'))),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 60),
                ],
                const SizedBox(height: 8),
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
  final int Function(String) dueCount;
  final void Function(String) onSelect;

  const _CategoryPicker({
    required this.categories,
    required this.dueCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final cat = categories[i];
        final due = dueCount(cat);
        return ListTile(
          title: Text(cat[0].toUpperCase() + cat.substring(1)),
          subtitle: due > 0
              ? Text('$due card${due == 1 ? '' : 's'} due',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500))
              : const Text('All caught up'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onSelect(cat),
        );
      },
    );
  }
}

class _CompletionScreen extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onPracticeAll;

  const _CompletionScreen({
    required this.correct,
    required this.total,
    required this.onBack,
    required this.onPracticeAll,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (correct / total * 100).round() : 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('All caught up!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('$correct / $total correct ($pct%)',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 32),
            FilledButton(onPressed: onBack, child: const Text('Back to categories')),
            const SizedBox(height: 12),
            TextButton(
                onPressed: onPracticeAll,
                child: const Text('Practice all cards anyway')),
          ],
        ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(text,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
