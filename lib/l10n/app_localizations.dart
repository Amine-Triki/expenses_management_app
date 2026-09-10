import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Tracker'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get navExpenses;

  /// No description provided for @navLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get navLists;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get navBudget;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first expense with the button below'**
  String get homeEmptyHint;

  /// No description provided for @homeNoBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget mode is off'**
  String get homeNoBudgetTitle;

  /// No description provided for @homeNoBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'Spent {monthTotal} this month'**
  String homeNoBudgetHint(String monthTotal);

  /// No description provided for @homeEnableBudget.
  ///
  /// In en, this message translates to:
  /// **'Enable budget'**
  String get homeEnableBudget;

  /// No description provided for @homeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get homeAvailable;

  /// No description provided for @homeSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get homeSpent;

  /// No description provided for @homeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get homeRemaining;

  /// No description provided for @homeDailyAvailable.
  ///
  /// In en, this message translates to:
  /// **'Daily available'**
  String get homeDailyAvailable;

  /// No description provided for @homeCyclePeriod.
  ///
  /// In en, this message translates to:
  /// **'Cycle {start} – {end}'**
  String homeCyclePeriod(String start, String end);

  /// No description provided for @homeDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day left} other{{count} days left}}'**
  String homeDaysLeft(int count);

  /// No description provided for @homeRecentExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recent expenses'**
  String get homeRecentExpenses;

  /// No description provided for @homeCycleEnded.
  ///
  /// In en, this message translates to:
  /// **'Your cycle ended — remaining {amount}'**
  String homeCycleEnded(String amount);

  /// No description provided for @homeNegativeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get homeNegativeRemaining;

  /// No description provided for @homeCarryOverLine.
  ///
  /// In en, this message translates to:
  /// **'+ Carry-over from previous cycle: {amount}'**
  String homeCarryOverLine(String amount);

  /// No description provided for @expenseAdd.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expenseAdd;

  /// No description provided for @expenseEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get expenseEdit;

  /// No description provided for @expenseName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get expenseName;

  /// No description provided for @expenseNameHint.
  ///
  /// In en, this message translates to:
  /// **'What did you buy?'**
  String get expenseNameHint;

  /// No description provided for @expenseAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expenseAmount;

  /// No description provided for @expenseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get expenseQuantity;

  /// No description provided for @expenseUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get expenseUnitPrice;

  /// No description provided for @expenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenseCategory;

  /// No description provided for @expenseNoCategory.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get expenseNoCategory;

  /// No description provided for @expenseNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get expenseNote;

  /// No description provided for @expenseMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get expenseMoreDetails;

  /// No description provided for @expenseSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense saved'**
  String get expenseSaved;

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get expenseDeleted;

  /// No description provided for @expenseDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this expense of {amount}?'**
  String expenseDeleteConfirm(String amount);

  /// No description provided for @expenseInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get expenseInvalidAmount;

  /// No description provided for @expenseInvalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity'**
  String get expenseInvalidQuantity;

  /// No description provided for @expenseInvalidName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get expenseInvalidName;

  /// No description provided for @expenseSpentNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get expenseSpentNow;

  /// No description provided for @expenseAmountComputed.
  ///
  /// In en, this message translates to:
  /// **'Amount computed from quantity × unit price'**
  String get expenseAmountComputed;

  /// No description provided for @expenseGroupMode.
  ///
  /// In en, this message translates to:
  /// **'Group purchase (same place)'**
  String get expenseGroupMode;

  /// No description provided for @expenseGroupModeHint.
  ///
  /// In en, this message translates to:
  /// **'Items are saved under one card. Add each item, then tap Done.'**
  String get expenseGroupModeHint;

  /// No description provided for @expenseGroupNext.
  ///
  /// In en, this message translates to:
  /// **'Save & add next item'**
  String get expenseGroupNext;

  /// No description provided for @expenseGroupDone.
  ///
  /// In en, this message translates to:
  /// **'Done ({count})'**
  String expenseGroupDone(int count);

  /// No description provided for @expenseGroupItems.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s)'**
  String expenseGroupItems(int count);

  /// No description provided for @expenseGroupTotal.
  ///
  /// In en, this message translates to:
  /// **'Group total'**
  String get expenseGroupTotal;

  /// No description provided for @expensesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No expenses'**
  String get expensesEmpty;

  /// No description provided for @expensesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search expenses'**
  String get expensesSearch;

  /// No description provided for @expensesFilterPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get expensesFilterPeriod;

  /// No description provided for @expensesFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expensesFilterCategory;

  /// No description provided for @expensesAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get expensesAllCategories;

  /// No description provided for @expensesDayTotal.
  ///
  /// In en, this message translates to:
  /// **'Day total'**
  String get expensesDayTotal;

  /// No description provided for @expenseSourceShoppingList.
  ///
  /// In en, this message translates to:
  /// **'From list'**
  String get expenseSourceShoppingList;

  /// No description provided for @budgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetTitle;

  /// No description provided for @budgetDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget mode is off'**
  String get budgetDisabledTitle;

  /// No description provided for @budgetDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Set an available amount per cycle to track what remains.'**
  String get budgetDisabledHint;

  /// No description provided for @budgetEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable budget'**
  String get budgetEnable;

  /// No description provided for @budgetStartDay.
  ///
  /// In en, this message translates to:
  /// **'Cycle start day'**
  String get budgetStartDay;

  /// No description provided for @budgetInitialAmount.
  ///
  /// In en, this message translates to:
  /// **'Available amount per cycle'**
  String get budgetInitialAmount;

  /// No description provided for @budgetDefaultAmount.
  ///
  /// In en, this message translates to:
  /// **'Default amount per cycle'**
  String get budgetDefaultAmount;

  /// No description provided for @budgetDefaultAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Used as the starting amount of future cycles.'**
  String get budgetDefaultAmountHint;

  /// No description provided for @budgetCarryOver.
  ///
  /// In en, this message translates to:
  /// **'Carry remaining balance to next cycle'**
  String get budgetCarryOver;

  /// No description provided for @budgetCarryOverHint.
  ///
  /// In en, this message translates to:
  /// **'When enabled, the leftover (or shortage) moves to the next cycle.'**
  String get budgetCarryOverHint;

  /// No description provided for @budgetCurrentCycle.
  ///
  /// In en, this message translates to:
  /// **'Current cycle'**
  String get budgetCurrentCycle;

  /// No description provided for @budgetSpentInCycle.
  ///
  /// In en, this message translates to:
  /// **'Spent in this cycle'**
  String get budgetSpentInCycle;

  /// No description provided for @budgetCarryOverApplied.
  ///
  /// In en, this message translates to:
  /// **'Carry-over applied: {amount}'**
  String budgetCarryOverApplied(String amount);

  /// No description provided for @budgetStartFromToday.
  ///
  /// In en, this message translates to:
  /// **'Start from today instead'**
  String get budgetStartFromToday;

  /// No description provided for @budgetStartFromTodayHint.
  ///
  /// In en, this message translates to:
  /// **'Cycle begins today and ends with the current period.'**
  String get budgetStartFromTodayHint;

  /// No description provided for @budgetEditAmount.
  ///
  /// In en, this message translates to:
  /// **'Edit available amount (what remains)'**
  String get budgetEditAmount;

  /// No description provided for @budgetEditAmountNote.
  ///
  /// In en, this message translates to:
  /// **'This change applies to the current cycle only.'**
  String get budgetEditAmountNote;

  /// No description provided for @budgetStartNewCycleNow.
  ///
  /// In en, this message translates to:
  /// **'Close cycle and start new one now'**
  String get budgetStartNewCycleNow;

  /// No description provided for @budgetNewCycleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Close the current cycle and start a new one now?'**
  String get budgetNewCycleConfirm;

  /// No description provided for @budgetHistory.
  ///
  /// In en, this message translates to:
  /// **'Cycle history'**
  String get budgetHistory;

  /// No description provided for @budgetCycleClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get budgetCycleClosed;

  /// No description provided for @budgetCycleActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get budgetCycleActive;

  /// No description provided for @budgetDisable.
  ///
  /// In en, this message translates to:
  /// **'Turn off budget'**
  String get budgetDisable;

  /// No description provided for @budgetDisableConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn off budget mode? Past cycles stay in history.'**
  String get budgetDisableConfirm;

  /// No description provided for @budgetOverBudget.
  ///
  /// In en, this message translates to:
  /// **'You have spent more than the available amount.'**
  String get budgetOverBudget;

  /// No description provided for @budgetDailyInfo.
  ///
  /// In en, this message translates to:
  /// **'This is an indicator, not a spending limit.'**
  String get budgetDailyInfo;

  /// No description provided for @listsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping lists'**
  String get listsTitle;

  /// No description provided for @listsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shopping lists'**
  String get listsEmpty;

  /// No description provided for @listsNew.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get listsNew;

  /// No description provided for @listsNewName.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listsNewName;

  /// No description provided for @listsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get listsCreate;

  /// No description provided for @listsAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get listsAddItem;

  /// No description provided for @listItemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get listItemName;

  /// No description provided for @listItemEstPrice.
  ///
  /// In en, this message translates to:
  /// **'Estimated price'**
  String get listItemEstPrice;

  /// No description provided for @listEstimatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get listEstimatedTotal;

  /// No description provided for @listItemsWithoutEstimate.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) without estimate'**
  String listItemsWithoutEstimate(int count);

  /// No description provided for @listVsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{total} of {remaining} remaining'**
  String listVsRemaining(String total, String remaining);

  /// No description provided for @listMarkPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get listMarkPurchased;

  /// No description provided for @listActualPrice.
  ///
  /// In en, this message translates to:
  /// **'Actual price'**
  String get listActualPrice;

  /// No description provided for @listActualPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Estimated {estimated}'**
  String listActualPriceHint(String estimated);

  /// No description provided for @listConvertQuestion.
  ///
  /// In en, this message translates to:
  /// **'Record as an expense now?'**
  String get listConvertQuestion;

  /// No description provided for @listConvertTitle.
  ///
  /// In en, this message translates to:
  /// **'Convert to expense'**
  String get listConvertTitle;

  /// No description provided for @listConverted.
  ///
  /// In en, this message translates to:
  /// **'Recorded as expense'**
  String get listConverted;

  /// No description provided for @listArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get listArchive;

  /// No description provided for @listUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get listUnarchive;

  /// No description provided for @listArchivedSection.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get listArchivedSection;

  /// No description provided for @listDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get listDeleteItem;

  /// No description provided for @listEmptyList.
  ///
  /// In en, this message translates to:
  /// **'This list is empty'**
  String get listEmptyList;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @statsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statsToday;

  /// No description provided for @statsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get statsThisWeek;

  /// No description provided for @statsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get statsThisMonth;

  /// No description provided for @statsThisCycle.
  ///
  /// In en, this message translates to:
  /// **'This cycle'**
  String get statsThisCycle;

  /// No description provided for @statsCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get statsCustom;

  /// No description provided for @statsTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get statsTotalSpent;

  /// No description provided for @statsAvgDaily.
  ///
  /// In en, this message translates to:
  /// **'Average daily'**
  String get statsAvgDaily;

  /// No description provided for @statsByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get statsByCategory;

  /// No description provided for @statsTopDays.
  ///
  /// In en, this message translates to:
  /// **'Highest spending days'**
  String get statsTopDays;

  /// No description provided for @statsNoData.
  ///
  /// In en, this message translates to:
  /// **'Nothing spent in this period'**
  String get statsNoData;

  /// No description provided for @statsUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get statsUncategorized;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget settings'**
  String get settingsBudget;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get settingsData;

  /// No description provided for @settingsPrivacyText.
  ///
  /// In en, this message translates to:
  /// **'All data is stored locally on this device. The app works fully offline and does not send any financial information anywhere.'**
  String get settingsPrivacyText;

  /// No description provided for @settingsClearData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get settingsClearData;

  /// No description provided for @settingsClearDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all expenses, lists, and budget history on this device?'**
  String get settingsClearDataConfirm;

  /// No description provided for @settingsClearDataFinal.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Delete everything?'**
  String get settingsClearDataFinal;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @firstRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get firstRunTitle;

  /// No description provided for @firstRunHint.
  ///
  /// In en, this message translates to:
  /// **'Record what you spend and understand what remains.'**
  String get firstRunHint;

  /// No description provided for @firstRunChooseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Choose your currency'**
  String get firstRunChooseCurrency;

  /// No description provided for @firstRunCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'You can change it later in Settings.'**
  String get firstRunCurrencyHint;

  /// No description provided for @firstRunStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get firstRunStart;

  /// No description provided for @errorInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid input'**
  String get errorInvalidInput;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get catHome;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get catTransport;

  /// No description provided for @catBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get catBills;

  /// No description provided for @catHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// No description provided for @catEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get catEntertainment;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
