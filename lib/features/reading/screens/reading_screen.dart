import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:basque/core/api_client.dart';

final _passageListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final res = await dio.get('/reading/passages');
  return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
});

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  Map<String, dynamic>? _selected; // passage metadata
  Map<String, dynamic>? _passage;  // full passage including basque_text + translation
  final _summaryController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loadingPassage = false;
  bool _loadingEval = false;
  String? _error;
  final _box = Hive.box('flashcards');

  static String _hiveKey(String id) => 'reading_${id}_bestScore';

  double? _bestScore(String id) {
    final v = _box.get(_hiveKey(id));
    return v != null ? (v as num).toDouble() : null;
  }

  void _saveBestScore(String id, double score) {
    final current = _bestScore(id);
    if (current == null || score > current) {
      _box.put(_hiveKey(id), score);
    }
  }

  Future<void> _openPassage(Map<String, dynamic> meta) async {
    setState(() {
      _selected = meta;
      _passage = null;
      _result = null;
      _error = null;
      _loadingPassage = true;
      _summaryController.clear();
    });
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.get('/reading/passage/${meta['id']}');
      setState(() => _passage = Map<String, dynamic>.from(res.data));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingPassage = false);
    }
  }

  Future<void> _evaluate() async {
    if (_passage == null || _summaryController.text.trim().isEmpty) return;
    setState(() { _loadingEval = true; _error = null; });
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.post('/reading/evaluate', data: {
        'user_summary': _summaryController.text.trim(),
        'reference_translation': _passage!['english_translation'],
      });
      final result = Map<String, dynamic>.from(res.data);
      _saveBestScore(_selected!['id'] as String, (result['score'] as num).toDouble());
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingEval = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selected == null ? 'Reading Practice' : _selected!['title'] as String),
        leading: _selected != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selected = null;
                  _passage = null;
                  _result = null;
                }),
              )
            : null,
      ),
      body: _selected == null
          ? _PassageList(
              onSelect: _openPassage,
              bestScore: _bestScore,
            )
          : _PassageDetail(
              passage: _passage,
              result: _result,
              loading: _loadingPassage,
              evaluating: _loadingEval,
              error: _error,
              summaryController: _summaryController,
              onEvaluate: _evaluate,
              selectedMeta: _selected!,
              bestScore: _bestScore(_selected!['id'] as String),
            ),
    );
  }
}

class _PassageList extends ConsumerWidget {
  final void Function(Map<String, dynamic>) onSelect;
  final double? Function(String) bestScore;

  const _PassageList({required this.onSelect, required this.bestScore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_passageListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (passages) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: passages.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final p = passages[i];
          final score = bestScore(p['id'] as String);
          final pct = score != null ? '${(score * 100).round()}%' : null;
          final level = p['level'] as String;
          return ListTile(
            title: Text(p['title'] as String),
            subtitle: Text(p['topic'] as String),
            leading: _LevelBadge(level: level),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pct != null) ...[
                  Text('Best: $pct',
                      style: TextStyle(
                        color: _scoreColor(context, score!),
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => onSelect(p),
          );
        },
      ),
    );
  }

  Color _scoreColor(BuildContext context, double score) {
    if (score > 0.85) return Colors.green;
    if (score > 0.65) return Colors.orange;
    return Theme.of(context).colorScheme.error;
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      'beginner' => Colors.green,
      'intermediate' => Colors.orange,
      _ => Colors.red,
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          level[0].toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}

class _PassageDetail extends StatelessWidget {
  final Map<String, dynamic>? passage;
  final Map<String, dynamic>? result;
  final bool loading;
  final bool evaluating;
  final String? error;
  final TextEditingController summaryController;
  final VoidCallback onEvaluate;
  final Map<String, dynamic> selectedMeta;
  final double? bestScore;

  const _PassageDetail({
    required this.passage,
    required this.result,
    required this.loading,
    required this.evaluating,
    required this.error,
    required this.summaryController,
    required this.onEvaluate,
    required this.selectedMeta,
    required this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            _LevelBadge(level: selectedMeta['level'] as String),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(selectedMeta['topic'] as String,
                  style: Theme.of(context).textTheme.bodySmall),
              if (bestScore != null)
                Text('Best: ${(bestScore! * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall),
            ]),
          ]),
          const SizedBox(height: 16),
          if (passage != null) ...[
            Text('Read this passage:', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(passage!['basque_text'] as String,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: summaryController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Write a summary in English',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: evaluating ? null : onEvaluate,
              child: evaluating
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Check Summary'),
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: 20),
            _ScoreCard(
              result: result!,
              translation: passage!['english_translation'] as String,
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final String translation;
  const _ScoreCard({required this.result, required this.translation});

  @override
  Widget build(BuildContext context) {
    final label = result['label'] as String;
    final score = (result['score'] as num).toDouble();
    final pct = (score * 100).round();
    final color = label == 'excellent'
        ? Colors.green
        : label == 'good'
            ? Colors.orange
            : Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(label[0].toUpperCase() + label.substring(1),
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              Text('$pct%',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 24),
            Text('Translation', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(translation),
          ],
        ),
      ),
    );
  }
}
