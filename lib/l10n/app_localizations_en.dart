// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Expense Tracker';

  @override
  String get navHome => 'Home';

  @override
  String get navExpenses => 'Expenses';

  @override
  String get navLists => 'Lists';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get navBudget => 'Budget';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonBack => 'Back';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get homeEmptyTitle => 'No expenses yet';

  @override
  String get homeEmptyHint => 'Add your first expense with the button below';

  @override
  String get homeNoBudgetTitle => 'Budget mode is off';

  @override
  String homeNoBudgetHint(String monthTotal) {
    return 'Spent $monthTotal this month';
  }

  @override
  String get homeEnableBudget => 'Enable budget';

  @override
  String get homeAvailable => 'Available';

  @override
  String get homeSpent => 'Spent';

  @override
  String get homeRemaining => 'Remaining';

  @override
  String get homeDailyAvailable => 'Daily available';

  @override
  String homeCyclePeriod(String start, String end) {
    return 'Cycle $start – $end';
  }

  @override
  String homeDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '$count day left',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentExpenses => 'Recent expenses';

  @override
  String homeCycleEnded(String amount) {
    return 'Your cycle ended — remaining $amount';
  }

  @override
  String get homeNegativeRemaining => 'Over budget';

  @override
  String homeCarryOverLine(String amount) {
    return '+ Carry-over from previous cycle: $amount';
  }

  @override
  String get expenseAdd => 'Add expense';

  @override
  String get expenseEdit => 'Edit expense';

  @override
  String get expenseName => 'Name';

  @override
  String get expenseNameHint => 'What did you buy?';

  @override
  String get expenseAmount => 'Amount';

  @override
  String get expenseQuantity => 'Quantity';

  @override
  String get expenseUnitPrice => 'Unit price';

  @override
  String get expenseCategory => 'Category';

  @override
  String get expenseNoCategory => 'Uncategorized';

  @override
  String get expenseNote => 'Note';

  @override
  String get expenseMoreDetails => 'More details';

  @override
  String get expenseSaved => 'Expense saved';

  @override
  String get expenseDeleted => 'Expense deleted';

  @override
  String expenseDeleteConfirm(String amount) {
    return 'Delete this expense of $amount?';
  }

  @override
  String get expenseInvalidAmount => 'Enter a valid amount';

  @override
  String get expenseInvalidQuantity => 'Enter a valid quantity';

  @override
  String get expenseInvalidName => 'Enter a name';

  @override
  String get expenseSpentNow => 'Now';

  @override
  String get expenseAmountComputed =>
      'Amount computed from quantity × unit price';

  @override
  String get expenseGroupMode => 'Group purchase (same place)';

  @override
  String get expenseGroupModeHint =>
      'Items are saved under one card. Add each item, then tap Done.';

  @override
  String get expenseGroupNext => 'Save & add next item';

  @override
  String expenseGroupDone(int count) {
    return 'Done ($count)';
  }

  @override
  String expenseGroupItems(int count) {
    return '$count item(s)';
  }

  @override
  String get expenseGroupTotal => 'Group total';

  @override
  String get expensesEmpty => 'No expenses';

  @override
  String get expensesSearch => 'Search expenses';

  @override
  String get expensesFilterPeriod => 'Period';

  @override
  String get expensesFilterCategory => 'Category';

  @override
  String get expensesAllCategories => 'All categories';

  @override
  String get expensesDayTotal => 'Day total';

  @override
  String get expenseSourceShoppingList => 'From list';

  @override
  String get budgetTitle => 'Budget';

  @override
  String get budgetDisabledTitle => 'Budget mode is off';

  @override
  String get budgetDisabledHint =>
      'Set an available amount per cycle to track what remains.';

  @override
  String get budgetEnable => 'Enable budget';

  @override
  String get budgetStartDay => 'Cycle start day';

  @override
  String get budgetInitialAmount => 'Available amount per cycle';

  @override
  String get budgetDefaultAmount => 'Default amount per cycle';

  @override
  String get budgetDefaultAmountHint =>
      'Used as the starting amount of future cycles.';

  @override
  String get budgetCarryOver => 'Carry remaining balance to next cycle';

  @override
  String get budgetCarryOverHint =>
      'When enabled, the leftover (or shortage) moves to the next cycle.';

  @override
  String get budgetCurrentCycle => 'Current cycle';

  @override
  String get budgetSpentInCycle => 'Spent in this cycle';

  @override
  String budgetCarryOverApplied(String amount) {
    return 'Carry-over applied: $amount';
  }

  @override
  String get budgetStartFromToday => 'Start from today instead';

  @override
  String get budgetStartFromTodayHint =>
      'Cycle begins today and ends with the current period.';

  @override
  String get budgetEditAmount => 'Edit available amount (what remains)';

  @override
  String get budgetEditAmountNote =>
      'This change applies to the current cycle only.';

  @override
  String get budgetStartNewCycleNow => 'Close cycle and start new one now';

  @override
  String get budgetNewCycleConfirm =>
      'Close the current cycle and start a new one now?';

  @override
  String get budgetHistory => 'Cycle history';

  @override
  String get budgetCycleClosed => 'Closed';

  @override
  String get budgetCycleActive => 'Active';

  @override
  String get budgetDisable => 'Turn off budget';

  @override
  String get budgetDisableConfirm =>
      'Turn off budget mode? Past cycles stay in history.';

  @override
  String get budgetOverBudget =>
      'You have spent more than the available amount.';

  @override
  String get budgetDailyInfo => 'This is an indicator, not a spending limit.';

  @override
  String get listsTitle => 'Shopping lists';

  @override
  String get listsEmpty => 'No shopping lists';

  @override
  String get listsNew => 'New list';

  @override
  String get listsNewName => 'List name';

  @override
  String get listsCreate => 'Create';

  @override
  String get listsAddItem => 'Add item';

  @override
  String get listItemName => 'Item name';

  @override
  String get listItemEstPrice => 'Estimated price';

  @override
  String get listEstimatedTotal => 'Estimated total';

  @override
  String listItemsWithoutEstimate(int count) {
    return '$count item(s) without estimate';
  }

  @override
  String listVsRemaining(String total, String remaining) {
    return '$total of $remaining remaining';
  }

  @override
  String get listMarkPurchased => 'Purchased';

  @override
  String get listActualPrice => 'Actual price';

  @override
  String listActualPriceHint(String estimated) {
    return 'Estimated $estimated';
  }

  @override
  String get listConvertQuestion => 'Record as an expense now?';

  @override
  String get listConvertTitle => 'Convert to expense';

  @override
  String get listConverted => 'Recorded as expense';

  @override
  String get listArchive => 'Archive';

  @override
  String get listUnarchive => 'Unarchive';

  @override
  String get listArchivedSection => 'Archived';

  @override
  String get listDeleteItem => 'Remove item';

  @override
  String get listEmptyList => 'This list is empty';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsToday => 'Today';

  @override
  String get statsThisWeek => 'This week';

  @override
  String get statsThisMonth => 'This month';

  @override
  String get statsThisCycle => 'This cycle';

  @override
  String get statsCustom => 'Custom';

  @override
  String get statsTotalSpent => 'Total spent';

  @override
  String get statsAvgDaily => 'Average daily';

  @override
  String get statsByCategory => 'Spending by category';

  @override
  String get statsTopDays => 'Highest spending days';

  @override
  String get statsNoData => 'Nothing spent in this period';

  @override
  String get statsUncategorized => 'Uncategorized';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsBudget => 'Budget settings';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsData => 'Data management';

  @override
  String get settingsPrivacyText =>
      'All data is stored locally on this device. The app works fully offline and does not send any financial information anywhere.';

  @override
  String get settingsClearData => 'Delete all data';

  @override
  String get settingsClearDataConfirm =>
      'Permanently delete all expenses, lists, and budget history on this device?';

  @override
  String get settingsClearDataFinal =>
      'This cannot be undone. Delete everything?';

  @override
  String get settingsAbout => 'About';

  @override
  String get firstRunTitle => 'Welcome';

  @override
  String get firstRunHint =>
      'Record what you spend and understand what remains.';

  @override
  String get firstRunChooseCurrency => 'Choose your currency';

  @override
  String get firstRunCurrencyHint => 'You can change it later in Settings.';

  @override
  String get firstRunStart => 'Start';

  @override
  String get errorInvalidInput => 'Invalid input';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get catFood => 'Food';

  @override
  String get catHome => 'Home';

  @override
  String get catTransport => 'Transportation';

  @override
  String get catBills => 'Bills';

  @override
  String get catHealth => 'Health';

  @override
  String get catEntertainment => 'Entertainment';

  @override
  String get catOther => 'Other';
}
