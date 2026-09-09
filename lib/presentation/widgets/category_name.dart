import 'package:flutter/material.dart';

import '../../data/repositories/category_repository.dart';
import '../../l10n/app_localizations.dart';

/// Resolves a category display name: builtin ids are translated via their
/// key, user categories render raw text (planning document H.4).
String categoryDisplayName(BuildContext context, String categoryId) {
  final key = CategoryRepository.builtinKeyFor(categoryId);
  if (key == null) return categoryId;
  return builtinCategoryName(context, key);
}

/// Builtin translation keys → display names.
String builtinCategoryName(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context)!;
  return switch (key) {
    'cat.food' => l10n.catFood,
    'cat.home' => l10n.catHome,
    'cat.transport' => l10n.catTransport,
    'cat.bills' => l10n.catBills,
    'cat.health' => l10n.catHealth,
    'cat.entertainment' => l10n.catEntertainment,
    'cat.other' => l10n.catOther,
    _ => key,
  };
}
