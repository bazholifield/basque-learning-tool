import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:basque/core/api_client.dart';

final _declensionsProvider = FutureProvider<Map<String, List>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final res = await dio.get('/declensions');
  return Map<String, List>.from(res.data);
});

final _referenceProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final res = await dio.get('/declensions/reference');
  return Map<String, dynamic>.from(res.data);
});

class DeclensionScreen extends ConsumerStatefulWidget {
  const DeclensionScreen({super.key});

  @override
  ConsumerState<DeclensionScreen> createState() => _DeclensionScreenState();
}

class _DeclensionScreenState extends ConsumerState<DeclensionScreen> {
  Set<String> _selectedCases = {};
  final Set<String> _selectedNumbers = {'singular', 'plural'};
  Map<String, dynamic>? _current;
  final _controller = TextEditingController();
  String? _feedback;
  bool? _correct;
  int _score = 0;
  int _total = 0;

  void _pick(Map<String, List> data) {
    if (_selectedCases.isEmpty) return;
    final pool = _selectedCases
        .expand((c) => (data[c] ?? []).where((e) => _selectedNumbers.contains((e as Map)['number'])))
        .toList();
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
    final expected = (_current!['declension'] as String).toLowerCase();
    final ok = answer == expected;
    setState(() {
      _correct = ok;
      if (ok) _score++;
      _total++;
      _feedback = ok
          ? 'Correct!'
          : 'Incorrect — the answer is "${_current!['declension']}"';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _pick(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    final declAsync = ref.watch(_declensionsProvider);
    final refAsync = ref.watch(_referenceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Declension')),
      body: declAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          if (_selectedCases.isEmpty) _selectedCases = data.keys.toSet();
          final reference = refAsync.valueOrNull ?? {};
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  FilterChip(
                    label: const Text('Singular'),
                    selected: _selectedNumbers.contains('singular'),
                    onSelected: (v) => setState(() => v
                        ? _selectedNumbers.add('singular')
                        : _selectedNumbers.remove('singular')),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Plural'),
                    selected: _selectedNumbers.contains('plural'),
                    onSelected: (v) => setState(() => v
                        ? _selectedNumbers.add('plural')
                        : _selectedNumbers.remove('plural')),
                  ),
                ]),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: data.keys.map((c) => FilterChip(
                    label: Text(c),
                    selected: _selectedCases.contains(c),
                    onSelected: (v) => setState(() {
                      v ? _selectedCases.add(c) : _selectedCases.remove(c);
                      _current = null;
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 16),
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
                          Text('Noun: ${_current!['noun']} (${_current!['translation']})',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text('Case: ${_current!['case']}'),
                          Text('Number: ${_current!['number']}'),
                          if (reference.containsKey(_current!['case'])) ...[
                            const SizedBox(height: 8),
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: const Text('About this case'),
                              children: [
                                Text(reference[_current!['case']]['description'] ?? ''),
                                const SizedBox(height: 4),
                                Text('Example: ${reference[_current!['case']]['example'] ?? ''}',
                                    style: const TextStyle(fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Your declension',
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
