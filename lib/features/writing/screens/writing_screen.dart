import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:basque/core/api_client.dart';

final _conversationListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final res = await dio.get('/writing/conversations');
  return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
});

class _Exchange {
  final String questionBasque;
  final String questionEnglish;
  final String responseBasque;
  final String responseEnglish;

  const _Exchange({
    required this.questionBasque,
    required this.questionEnglish,
    required this.responseBasque,
    required this.responseEnglish,
  });
}

class WritingScreen extends ConsumerStatefulWidget {
  const WritingScreen({super.key});

  @override
  ConsumerState<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends ConsumerState<WritingScreen> {
  Map<String, dynamic>? _conversation;
  int _questionIndex = 0;
  bool _showTranslation = false;
  bool _done = false;
  bool _loading = false;
  bool _translating = false;
  String? _error;
  final _responseController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Exchange> _history = [];

  Future<void> _startConversation(Map<String, dynamic> meta) async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.get('/writing/conversation/${meta['id']}');
      setState(() {
        _conversation = Map<String, dynamic>.from(res.data);
        _questionIndex = 0;
        _showTranslation = false;
        _done = false;
        _history.clear();
        _responseController.clear();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _next() async {
    final responseText = _responseController.text.trim();
    if (responseText.isEmpty) return;

    final questions = _conversation!['questions'] as List;
    final question = Map<String, dynamic>.from(questions[_questionIndex] as Map);

    setState(() { _translating = true; _error = null; });
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.post('/writing/translate', data: {'text': responseText});
      final translation = res.data['translation'] as String;

      final exchange = _Exchange(
        questionBasque: question['basque'] as String,
        questionEnglish: question['english'] as String,
        responseBasque: responseText,
        responseEnglish: translation,
      );

      setState(() {
        _history.add(exchange);
        _responseController.clear();
        _showTranslation = false;
        if (_questionIndex < questions.length - 1) {
          _questionIndex++;
        } else {
          _done = true;
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _translating = false);
    }
  }

  void _restart() {
    setState(() {
      _questionIndex = 0;
      _showTranslation = false;
      _done = false;
      _history.clear();
      _responseController.clear();
    });
  }

  void _backToList() {
    setState(() {
      _conversation = null;
      _done = false;
      _error = null;
      _history.clear();
      _responseController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_conversation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Writing Practice')),
        body: _error != null
            ? Center(child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
            : _ConversationList(onSelect: _startConversation),
      );
    }

    final questions = _conversation!['questions'] as List;
    final total = questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_conversation!['title'] as String),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _backToList),
        bottom: _done
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: (_questionIndex + 1) / total),
              ),
      ),
      body: _done
          ? _CompletionScreen(
              history: _history,
              onBack: _backToList,
              onRepeat: _restart,
              scrollController: _scrollController,
            )
          : _ConversationView(
              history: _history,
              questions: questions,
              questionIndex: _questionIndex,
              showTranslation: _showTranslation,
              onToggleTranslation: () => setState(() => _showTranslation = !_showTranslation),
              responseController: _responseController,
              onNext: _next,
              translating: _translating,
              error: _error,
              isLast: _questionIndex == total - 1,
              scrollController: _scrollController,
            ),
    );
  }
}

class _ConversationView extends StatelessWidget {
  final List<_Exchange> history;
  final List questions;
  final int questionIndex;
  final bool showTranslation;
  final VoidCallback onToggleTranslation;
  final TextEditingController responseController;
  final Future<void> Function() onNext;
  final bool translating;
  final String? error;
  final bool isLast;
  final ScrollController scrollController;

  const _ConversationView({
    required this.history,
    required this.questions,
    required this.questionIndex,
    required this.showTranslation,
    required this.onToggleTranslation,
    required this.responseController,
    required this.onNext,
    required this.translating,
    required this.error,
    required this.isLast,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final question = Map<String, dynamic>.from(questions[questionIndex] as Map);

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              for (final ex in history) _ExchangeTile(exchange: ex),
              if (history.isNotEmpty) const SizedBox(height: 8),
              GestureDetector(
                onTap: onToggleTranslation,
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question['basque'] as String,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        if (showTranslation) ...[
                          const SizedBox(height: 8),
                          Text(
                            question['english'] as String,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                ),
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tap to see translation',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: responseController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Your response in Basque',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: translating ? null : onNext,
                child: translating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isLast ? 'Finish' : 'Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExchangeTile extends StatelessWidget {
  final _Exchange exchange;
  const _ExchangeTile({required this.exchange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exchange.questionBasque,
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exchange.questionEnglish,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exchange.responseBasque,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exchange.responseEnglish,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionScreen extends StatelessWidget {
  final List<_Exchange> history;
  final VoidCallback onBack;
  final VoidCallback onRepeat;
  final ScrollController scrollController;

  const _CompletionScreen({
    required this.history,
    required this.onBack,
    required this.onRepeat,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              for (final ex in history) _ExchangeTile(exchange: ex),
              const SizedBox(height: 16),
              const Center(child: Icon(Icons.check_circle_outline, size: 48, color: Colors.green)),
              const SizedBox(height: 8),
              Center(
                child: Text('Conversation complete!', style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(onPressed: onBack, child: const Text('Back to conversations')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: onRepeat, child: const Text('Practice again')),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConversationList extends ConsumerWidget {
  final void Function(Map<String, dynamic>) onSelect;

  const _ConversationList({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_conversationListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (conversations) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: conversations.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = conversations[i];
          return ListTile(
            title: Text(c['title'] as String),
            subtitle: Text(c['situation'] as String),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${c['question_count']} questions',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => onSelect(c),
          );
        },
      ),
    );
  }
}
