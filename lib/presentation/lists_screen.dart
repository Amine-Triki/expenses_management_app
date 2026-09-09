import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/shopping_controller.dart';
import '../l10n/app_localizations.dart';
import 'list_detail_screen.dart';

/// Shopping lists tab: active lists + archived section (manual archiving).
class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(activeListsProvider);
    final archived = ref.watch(archivedListsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.listsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createList(context, ref),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          active.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.errorGeneric)),
            data: (lists) {
              if (lists.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text(l10n.listsEmpty)),
                );
              }
              return Column(
                children: [
                  for (final l in lists)
                    ListTile(
                      leading: const Icon(Icons.shopping_cart_outlined),
                      title: Text(l.name),
                      onTap: () => _openList(context, l.id),
                    ),
                ],
              );
            },
          ),
          archived.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (lists) {
              if (lists.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(l10n.listArchivedSection,
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  for (final l in lists)
                    ListTile(
                      leading: const Icon(Icons.archive_outlined),
                      title: Text(l.name),
                      onTap: () => _openList(context, l.id),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _openList(BuildContext context, String listId) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ListDetailScreen(listId: listId)));
  }

  Future<void> _createList(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.listsNew),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.listsNewName),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.listsCreate),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final id = await ref.read(shoppingControllerProvider).createList(name);
      if (context.mounted) _openList(context, id);
    }
  }
}
