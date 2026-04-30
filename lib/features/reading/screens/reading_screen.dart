import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:basque/core/api_client.dart';

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  static const _topics = ['food', 'travel', 'weather', 'school', 'sports'];
  static const _levels = ['beginner', 'intermediate', 'advanced'];
  static const _lengths = ['short', 'medium', 'long'];

  String _topic = 'food';
  String _level = 'beginner';
  String _length = 'short';

  Map<String, dynamic>? _passage;
  final _summaryController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loadingPassage = false;
  bool _loadingEval = false;
  String? _error;

  Future<void> _fetchPassage() async {
    setState(() { _loadingPassage = true; _passage = null; _result = null; _error = null; });
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.get('/reading/passage',
          queryParameters: {'topic': _topic, 'level': _level, 'length': _length});
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
      setState(() => _result = Map<String, dynamic>.from(res.data));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingEval = false);
    }
  }

  Widget _dropdown<T>(String label, T value, List<T> items, void Function(T) onChanged) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Practice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: _dropdown('Topic', _topic, _topics, (v) => setState(() => _topic = v))),
              const SizedBox(width: 8),
              Expanded(child: _dropdown('Level', _level, _levels, (v) => setState(() => _level = v))),
              const SizedBox(width: 8),
              Expanded(child: _dropdown('Length', _length, _lengths, (v) => setState(() => _length = v))),
            ]),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadingPassage ? null : _fetchPassage,
              child: _loadingPassage
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Get Passage'),
            ),
            if (_passage != null) ...[
              const SizedBox(height: 20),
              Text('Read this passage:', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_passage!['basque_text'] as String,
                      style: Theme.of(context).textTheme.bodyLarge),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _summaryController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Write a summary in English',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadingEval ? null : _evaluate,
                child: _loadingEval
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Check Summary'),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              _ScoreCard(result: _result!, translation: _passage!['english_translation'] as String),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
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
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 24),
            Text('Translation', style: Theme.of(context).textTheme.labelSmall),
            Text(translation),
          ],
        ),
      ),
    );
  }
}
