import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/expense_controller.dart';
import '../application/settings_controller.dart';
import '../domain/money_math.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'money_format.dart';
import 'widgets/category_name.dart';

/// Quick add/edit screen. The mandatory path is Name → Amount → Save;
/// optional details never block the flow (planning document C.2).
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.existing});

  final Expense? existing;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _noteController = TextEditingController();
  String? _categoryId;
  bool _detailsOpen = false;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      final settings = ref.read(appSettingsProvider).value;
      final money = MoneyFormatter(settings?.currencyCode ?? 'USD');
      _nameController.text = e.name;
      _amountController.text = money.format(e.amount, withCode: false);
      if (e.quantity != null) {
        _quantityController.text = scaledQuantityToString(e.quantity!);
      }
      if (e.unitPrice != null) {
        _unitPriceController.text = money.format(e.unitPrice!, withCode: false);
      }
      if (e.note != null) _noteController.text = e.note!;
      _categoryId = e.categoryId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Amount rule (G.2): quantity × unit price computes the amount, but a
  /// manually entered amount always wins and is never overwritten.
  int? _computedAmountMinor(int digits) {
    final qtyText = _quantityController.text.trim();
    final priceText = _unitPriceController.text.trim();
    if (qtyText.isEmpty || priceText.isEmpty) return null;
    final qty = quantityToScaled(qtyText);
    final price = parseMinorUnits(priceText, digits);
    if (qty <= 0 || price == null) return null;
    return scaledQuantityTimesPrice(qty, price);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.read(appSettingsProvider).value;
    final digits = settings == null ? 2 : 0; // replaced below
    final money = MoneyFormatter(settings?.currencyCode ?? 'USD');

    final name = _nameController.text.trim();
    final computed = _computedAmountMinor(money.info.digits);
    final manual = parseMinorUnits(_amountController.text, money.info.digits);

    // Final amount: manual input wins; otherwise the computed value.
    final amount = manual ?? computed;
    if (name.isEmpty) {
      setState(() => _errorText = l10n.expenseInvalidName);
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _errorText = l10n.expenseInvalidAmount);
      return;
    }

    // Optional quantity: must be > 0 when present.
    int? qtyScaled;
    final qtyText = _quantityController.text.trim();
    if (qtyText.isNotEmpty) {
      qtyScaled = quantityToScaled(qtyText);
      if (qtyScaled <= 0) {
        setState(() => _errorText = l10n.expenseInvalidQuantity);
        return;
      }
    }
    int? unitPrice;
    final priceText = _unitPriceController.text.trim();
    if (priceText.isNotEmpty) {
      unitPrice = parseMinorUnits(priceText, money.info.digits);
      if (unitPrice == null || unitPrice <= 0) {
        setState(() => _errorText = l10n.expenseInvalidAmount);
        return;
      }
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      final controller = ref.read(expenseControllerProvider);
      final note =
          _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
      final categoryId = _categoryId;
      // Builtin category ids hold translation keys; store as-is.
      final _ = digits;
      if (widget.existing == null) {
        await controller.addExpense(
          name: name,
          amountMinor: amount,
          quantityScaled: qtyScaled,
          unitPriceMinor: unitPrice,
          categoryId: categoryId,
          note: note,
          spentAtMs: DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        await controller.updateExpense(
          widget.existing!,
          name: name,
          amountMinor: amount,
          quantityScaled: qtyScaled,
          unitPriceMinor: unitPrice,
          categoryId: categoryId,
          note: note,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.expenseSaved)),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _errorText = l10n.errorGeneric);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider).value;
    final categories = ref.watch(categoriesProvider);
    final money = MoneyFormatter(settings?.currencyCode ?? 'USD');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null
            ? l10n.expenseAdd
            : l10n.expenseEdit),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            autofocus: widget.existing == null,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.expenseName,
              hintText: l10n.expenseNameHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            autofocus: widget.existing != null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*[.,]?[0-9]*$')),
            ],
            decoration: InputDecoration(
              labelText: l10n.expenseAmount,
              prefixText: '${settings?.currencyCode ?? 'USD'}  ',
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () =>
                setState(() => _detailsOpen = !_detailsOpen),
            icon: Icon(_detailsOpen
                ? Icons.expand_less
                : Icons.expand_more),
            label: Text(l10n.expenseMoreDetails),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 150),
            crossFadeState: _detailsOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^[0-9]*[.,]?[0-9]*$')),
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                            labelText: l10n.expenseQuantity),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _unitPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^[0-9]*[.,]?[0-9]*$')),
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                            labelText: l10n.expenseUnitPrice),
                      ),
                    ),
                  ],
                ),
                if (_computedAmountMinor(money.info.digits) != null &&
                    _amountController.text.trim().isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${l10n.expenseAmountComputed}: '
                      '${money.format(_computedAmountMinor(money.info.digits)!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 12),
                categories.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (list) => DropdownButtonFormField<String?>(
                    initialValue: _categoryId,
                    decoration:
                        InputDecoration(labelText: l10n.expenseCategory),
                    items: [
                      DropdownMenuItem<String?>(
                          value: null, child: Text(l10n.expenseNoCategory)),
                      for (final c in list)
                        DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.isBuiltin
                              ? builtinCategoryName(context, c.name)
                              : c.name),
                        ),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.expenseNote),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}

/// Opens the add screen, or the edit screen when [existing] is given.
Future<void> openAddExpenseScreen(BuildContext context, {Expense? existing}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
        builder: (_) => AddExpenseScreen(existing: existing)),
  );
}
