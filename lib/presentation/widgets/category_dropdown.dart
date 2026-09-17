import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/expense_controller.dart';
import '../../l10n/app_localizations.dart';
import 'category_name.dart';

/// Shared category selector — the single category picker used by every flow
/// that accepts a category (add/edit expense, shopping list items). Same
/// categories list, same "uncategorized" null option, same builtin-name
/// translation. A null value means no category.
class CategoryDropdown extends ConsumerWidget {
  const CategoryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoriesProvider);
    return categories.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (list) => DropdownButtonFormField<String?>(
        initialValue: value,
        decoration: InputDecoration(labelText: l10n.expenseCategory),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(l10n.expenseNoCategory),
          ),
          for (final c in list)
            DropdownMenuItem<String?>(
              value: c.id,
              child: Text(
                c.isBuiltin ? builtinCategoryName(context, c.name) : c.name,
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
