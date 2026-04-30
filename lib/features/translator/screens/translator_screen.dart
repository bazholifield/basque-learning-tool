import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:basque/core/api_client.dart';

class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  final _controller = TextEditingController();
  String _direction = 'eu-en';
  String? _result;
  bool _loading = false;
  String? _error;

  Future<void> _translate() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final parts = _direction.split('-');
      final dio = ref.read(apiClientProvider);
      final res = await dio.post('/translate', data: {
        'text': text,
        'source': parts[0],
        'target': parts[1],
      });
      setState(() { _result = res.data['translation'] as String; });
    } on DioException catch (e) {
      setState(() { _error = e.message; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Translate')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'eu-en', label: Text('Basque → English')),
                ButtonSegment(value: 'en-eu', label: Text('English → Basque')),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() {
                _direction = s.first;
                _result = null;
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _direction == 'eu-en' ? 'Enter Basque text...' : 'Enter English text...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _translate,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Translate'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              Text('Translation', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(_result!, style: Theme.of(context).textTheme.bodyLarge),
                ),
              ),
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
