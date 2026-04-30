import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:basque/core/api_client.dart';

final _conjugationsProvider = FutureProvider<Map<String, List>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final res = await dio.get('/conjugations');
  return Map<String, List>.from(res.data);
});

class ConjugationScreen extends ConsumerStatefulWidget {
  const ConjugationScreen({super.key});

  @override
  ConsumerState<ConjugationScreen> createState() => _ConjugationScreenState();
}

class _ConjugationScreenState extends ConsumerState<ConjugationScreen> {
  Set<String> _selectedTenses = {};
  Map<String, dynamic>? _current;
  final _controller = TextEditingController();
  String? _feedback;
  bool? _correct;
  int _score = 0;
  int _total = 0;

  void _pick(Map<String, List> data) {
    if (_selectedTenses.isEmpty) return;
    final pool = _selectedTenses.expand((t) => data[t] ?? []).toList();
    if (pool.isEmpty) return;
    setState(() {
      _current = Map<String, dynamic>.from(pool[Random().nextInt(pool.length)] as Map);
      _feedback = null;
      _correct = null;
      _controller.clear();
    });
  }

  void _check(Map<String, List> data) {
    if (_current == null) return;
    final answer = _controller.text.trim().toLowerCase();
    final expected = (_current!['conjugation'] as String).toLowerCase();
    final ok = answer == expected;
    setState(() {
      _correct = ok;
      if (ok) _score++;
      _total++;
      _feedback = ok
          ? 'Correct!'
          : 'Incorrect — the answer is "${_current!['conjugation']}"';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _pick(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_conjugationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Conjugation')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          if (_selectedTenses.isEmpty) {
            _selectedTenses = data.keys.toSet();
          }
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  children: data.keys.map((t) => FilterChip(
                    label: Text(t),
                    selected: _selectedTenses.contains(t),
                    onSelected: (v) => setState(() {
                      v ? _selectedTenses.add(t) : _selectedTenses.remove(t);
                      _current = null;
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                if (_current == null)
                  Center(
                    child: FilledButton(
                      onPressed: () => _pick(data),
                      child: const Text('Start Practice'),
                    ),
                  )
                else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Verb: ${_current!['verb']} (${_current!['translation']})',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('Person: ${_current!['person']}'),
                          Text('Tense: ${_current!['tense']}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Your conjugation',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _check(data),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: () => _check(data), child: const Text('Check')),
                  if (_feedback != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _feedback!,
                      style: TextStyle(
                        color: _correct == true
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text('Score: $_score / $_total',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
