import 'package:flutter/material.dart';

import '../../domain/currency.dart';
import '../../l10n/app_localizations.dart';

Future<String?> showCurrencyPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _CurrencyPickerSheet(current: current),
  );
}

class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet({required this.current});
  final String? current;

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _results {
    final query = _controller.text.trim().toUpperCase();
    if (query.isEmpty) return CurrencyInfo.pickerCodes;
    return CurrencyInfo.pickerCodes
        .where((code) => code.startsWith(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final results = _results;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height - media.viewInsets.bottom,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (results.length == 1) {
                    Navigator.pop(context, results.single);
                  }
                },
                decoration: InputDecoration(
                  hintText: l10n.currencySearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .deleteButtonTooltip,
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        l10n.currencyNoResults,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final code = results[index];
                        return ListTile(
                          title: Text(code),
                          trailing: code == widget.current
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () => Navigator.pop(context, code),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
