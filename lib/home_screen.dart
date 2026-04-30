import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _activities = [
    (label: 'Vocabulary', icon: Icons.style, route: '/vocab'),
    (label: 'Conjugation', icon: Icons.tune, route: '/conjugation'),
    (label: 'Declension', icon: Icons.account_tree, route: '/declension'),
    (label: 'Reading', icon: Icons.menu_book, route: '/reading'),
    (label: 'Writing', icon: Icons.edit_note, route: '/writing'),
    (label: 'Translate', icon: Icons.translate, route: '/translator'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basque Trainer'),
        centerTitle: true,
        backgroundColor: scheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Practice', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: _activities.map((a) => _ActivityCard(
                  label: a.label,
                  icon: a.icon,
                  onTap: () => context.push(a.route),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActivityCard({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: scheme.primary),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
