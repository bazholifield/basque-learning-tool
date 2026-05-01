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

class _QuizQuestion {
  final String basque;
  final List<String> options;
  final int correctIndex;
  const _QuizQuestion({required this.basque, required this.options, required this.correctIndex});
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

  // Flashcard state
  List<List<String>> _session = [];
  int _index = 0;
  bool _flipped = false;
  int _correct = 0;
  bool _done = false;

  // Quiz state
  bool _quizMode = false;
  List<_QuizQuestion> _quizQuestions = [];
  int _quizIndex = 0;
  int? _quizSelected;
  int _quizCorrect = 0;
  bool _quizDone = false;

  final _box = Hive.box('flashcards');
  final _rng = Random();

  void _loadCategory(String category, Map<String, List> data) {
    final raw = data[category] ?? [];
    final cards = raw.map<List<String>>((e) {
      final pair = e as List;
      return [pair[0].toString(), pair[1].toString()];
    }).toList();

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
      _quizMode = false;
      _session = [...overdue, ...newCards];
      _index = 0;
      _flipped = false;
      _correct = 0;
      _done = _session.isEmpty;
    });
  }

  void _loadQuiz(String category, Map<String, List> data) {
    final raw = data[category] ?? [];
    final cards = raw.map<List<String>>((e) {
      final pair = e as List;
      return [pair[0].toString(), pair[1].toString()]; // [english, basque]
    }).toList();

    // Collect all english words across all categories for distractors
    final allEnglish = data.values
        .expand((list) => list.map((e) => (e as List)[0].toString()))
        .toList();

    final shuffled = List.of(cards)..shuffle(_rng);
    final questions = shuffled.take(min(shuffled.length, 15)).map((card) {
      final correctEnglish = card[0];
      final basque = card[1];

      // Prefer distractors from same category, fall back to all vocab
      final sameCategory = cards
          .where((c) => c[0] != correctEnglish)
          .map((c) => c[0])
          .toList()..shuffle(_rng);
      final distractors = <String>[...sameCategory.take(3)];
      if (distractors.length < 3) {
        final extras = allEnglish
            .where((e) => e != correctEnglish && !distractors.contains(e))
            .toList()..shuffle(_rng);
        distractors.addAll(extras.take(3 - distractors.length));
      }

      final options = [correctEnglish, ...distractors.take(3)]..shuffle(_rng);
      return _QuizQuestion(
        basque: basque,
        options: options,
        correctIndex: options.indexOf(correctEnglish),
      );
    }).toList();

    setState(() {
      _category = category;
      _quizMode = true;
      _quizQuestions = questions;
      _quizIndex = 0;
      _quizSelected = null;
      _quizCorrect = 0;
      _quizDone = false;
    });
  }

  void _selectOption(int i) {
    if (_quizSelected != null) return; // already answered
    final isCorrect = i == _quizQuestions[_quizIndex].correctIndex;
    setState(() {
      _quizSelected = i;
      if (isCorrect) _quizCorrect++;
    });
  }

  void _nextQuiz() {
    final next = _quizIndex + 1;
    if (next >= _quizQuestions.length) {
      final pct = (_quizCorrect / _quizQuestions.length * 100).round();
      final key = 'quiz_${_category!}_bestPct';
      final prev = _box.get(key) as int?;
      if (prev == null || pct > prev) _box.put(key, pct);
    }
    setState(() {
      _quizSelected = null;
      if (next >= _quizQuestions.length) {
        _quizDone = true;
      } else {
        _quizIndex = next;
      }
    });
  }

  int? _quizBestPct(String category) => _box.get('quiz_${category}_bestPct') as int?;

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

  void _backToCategories() => setState(() {
        _category = null;
        _done = false;
        _quizDone = false;
        _quizMode = false;
      });

  @override
  Widget build(BuildContext context) {
    final vocabAsync = ref.watch(_vocabProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary'),
        leading: _category != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _backToCategories)
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
              quizBestPct: _quizBestPct,
              onFlashcards: (c) => _loadCategory(c, data),
              onQuiz: (c) => _loadQuiz(c, data),
            );
          }

          if (_quizMode) {
            if (_quizDone) {
              return _QuizCompletion(
                correct: _quizCorrect,
                total: _quizQuestions.length,
                onBack: _backToCategories,
                onRetry: () => _loadQuiz(_category!, data),
              );
            }
            final q = _quizQuestions[_quizIndex];
            return _QuizView(
              question: q,
              questionIndex: _quizIndex,
              total: _quizQuestions.length,
              correct: _quizCorrect,
              selected: _quizSelected,
              onSelect: _selectOption,
              onNext: _nextQuiz,
              isLast: _quizIndex == _quizQuestions.length - 1,
            );
          }

          if (_done) {
            return _CompletionScreen(
              correct: _correct,
              total: _session.length,
              onBack: _backToCategories,
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
                    Text(_category!, style: Theme.of(context).textTheme.titleSmall),
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
                      Expanded(child: OutlinedButton(onPressed: () => _rate(1), child: const Text('Hard'))),
                      const SizedBox(width: 8),
                      Expanded(child: FilledButton.tonal(onPressed: () => _rate(3), child: const Text('Good'))),
                      const SizedBox(width: 8),
                      Expanded(child: FilledButton(onPressed: () => _rate(5), child: const Text('Easy'))),
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

class _QuizView extends StatelessWidget {
  final _QuizQuestion question;
  final int questionIndex;
  final int total;
  final int correct;
  final int? selected;
  final void Function(int) onSelect;
  final VoidCallback onNext;
  final bool isLast;

  const _QuizView({
    required this.question,
    required this.questionIndex,
    required this.total,
    required this.correct,
    required this.selected,
    required this.onSelect,
    required this.onNext,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final answered = selected != null;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Quiz', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text('${questionIndex + 1} / $total  •  $correct correct',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: (questionIndex + 1) / total),
          const SizedBox(height: 32),
          Text(
            question.basque,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'What does this mean in English?',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          for (int i = 0; i < question.options.length; i++) ...[
            _OptionButton(
              label: question.options[i],
              state: answered
                  ? i == question.correctIndex
                      ? _OptionState.correct
                      : i == selected
                          ? _OptionState.wrong
                          : _OptionState.neutral
                  : _OptionState.neutral,
              onTap: answered ? null : () => onSelect(i),
            ),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          if (answered)
            FilledButton(
              onPressed: onNext,
              child: Text(isLast ? 'See results' : 'Next'),
            ),
        ],
      ),
    );
  }
}

enum _OptionState { neutral, correct, wrong }

class _OptionButton extends StatelessWidget {
  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  const _OptionButton({required this.label, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (state) {
      _OptionState.correct => (Colors.green.shade50, Colors.green.shade800, Colors.green),
      _OptionState.wrong => (Colors.red.shade50, Colors.red.shade800, Colors.red),
      _OptionState.neutral => (
          Theme.of(context).colorScheme.surface,
          Theme.of(context).colorScheme.onSurface,
          Theme.of(context).colorScheme.outline,
        ),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: state == _OptionState.neutral ? 1 : 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: fg,
                fontWeight: state != _OptionState.neutral ? FontWeight.w600 : null,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _QuizCompletion extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _QuizCompletion({required this.correct, required this.total, required this.onBack, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (correct / total * 100).round() : 0;
    final color = pct >= 85 ? Colors.green : pct >= 65 ? Colors.orange : Theme.of(context).colorScheme.error;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(pct >= 65 ? Icons.emoji_events : Icons.refresh, size: 72, color: color),
            const SizedBox(height: 16),
            Text('$correct / $total correct',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color)),
            const SizedBox(height: 4),
            Text('$pct%', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 32),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onBack, child: const Text('Back to categories')),
          ],
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<String> categories;
  final int Function(String) dueCount;
  final int? Function(String) quizBestPct;
  final void Function(String) onFlashcards;
  final void Function(String) onQuiz;

  const _CategoryPicker({
    required this.categories,
    required this.dueCount,
    required this.quizBestPct,
    required this.onFlashcards,
    required this.onQuiz,
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
        final bestPct = quizBestPct(cat);
        return ListTile(
          title: Text(cat[0].toUpperCase() + cat.substring(1)),
          subtitle: due > 0
              ? Text('$due card${due == 1 ? '' : 's'} due',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500))
              : const Text('All caught up'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (bestPct != null) ...[
                Text(
                  'Best: $bestPct%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: bestPct >= 85
                        ? Colors.green
                        : bestPct >= 65
                            ? Colors.orange
                            : Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                icon: const Icon(Icons.quiz_outlined),
                tooltip: 'Quiz',
                onPressed: () => onQuiz(cat),
              ),
              IconButton(
                icon: const Icon(Icons.style_outlined),
                tooltip: 'Flashcards',
                onPressed: () => onFlashcards(cat),
              ),
            ],
          ),
          onTap: () => onFlashcards(cat),
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
            Text('All caught up!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('$correct / $total correct ($pct%)',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 32),
            FilledButton(onPressed: onBack, child: const Text('Back to categories')),
            const SizedBox(height: 12),
            TextButton(onPressed: onPracticeAll, child: const Text('Practice all cards anyway')),
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
