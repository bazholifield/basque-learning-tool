import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:basque/core/api_client.dart';

class WritingScreen extends ConsumerStatefulWidget {
  const WritingScreen({super.key});

  @override
  ConsumerState<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends ConsumerState<WritingScreen> {
  String? _prompt;
  final _userController = TextEditingController();
  final _refController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;
  String? _error;

  Future<void> _fetchPrompt() async {
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.get('/writing/prompt');
      setState(() { _prompt = res.data['prompt'] as String; _result = null; });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _evaluate() async {
    final user = _userController.text.trim();
    final ref_ = _refController.text.trim();
    if (user.isEmpty || ref_.isEmpty) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.post('/writing/evaluate', data: {
        'user_text': user,
        'reference_text': ref_,
      });
      setState(() => _result = Map<String, dynamic>.from(res.data));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPrompt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Writing Practice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_prompt != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_prompt!, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      IconButton(onPressed: _fetchPrompt, icon: const Icon(Icons.refresh)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _userController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Your response in Basque',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _refController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Reference answer in Basque',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _evaluate,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Evaluate'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _ResultCard(result: _result!),
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

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = (result['similarity'] as num).toDouble();
    final pct = (score * 100).round();
    final label = score > 0.85 ? 'Excellent' : score > 0.65 ? 'Good' : 'Needs work';
    final color = score > 0.85
        ? Colors.green
        : score > 0.65
            ? Colors.orange
            : Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 24),
            Text('Your translation', style: Theme.of(context).textTheme.labelSmall),
            Text(result['user_translation'] ?? ''),
            const SizedBox(height: 12),
            Text('Reference translation', style: Theme.of(context).textTheme.labelSmall),
            Text(result['reference_translation'] ?? ''),
          ],
        ),
      ),
    );
  }
}
