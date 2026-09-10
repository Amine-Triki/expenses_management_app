// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'متتبع المصروفات';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navExpenses => 'المصروفات';

  @override
  String get navLists => 'القوائم';

  @override
  String get navStats => 'الإحصائيات';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get navBudget => 'الميزانية';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonOk => 'حسنًا';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonConfirm => 'تأكيد';

  @override
  String get commonYes => 'نعم';

  @override
  String get commonNo => 'لا';

  @override
  String get commonUndo => 'تراجع';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonToday => 'اليوم';

  @override
  String get commonYesterday => 'أمس';

  @override
  String get homeEmptyTitle => 'لا مصروفات بعد';

  @override
  String get homeEmptyHint => 'أضف مصروفك الأول من الزر أدناه';

  @override
  String get homeNoBudgetTitle => 'وضع الميزانية غير مفعّل';

  @override
  String homeNoBudgetHint(String monthTotal) {
    return 'صرفت $monthTotal هذا الشهر';
  }

  @override
  String get homeEnableBudget => 'تفعيل الميزانية';

  @override
  String get homeAvailable => 'المتاح';

  @override
  String get homeSpent => 'المصروف';

  @override
  String get homeRemaining => 'المتبقي';

  @override
  String get homeDailyAvailable => 'المتاح يوميًا';

  @override
  String homeCyclePeriod(String start, String end) {
    return 'الدورة $start – $end';
  }

  @override
  String homeDaysLeft(int count) {
    return 'بقيت $count يومًا';
  }

  @override
  String get homeRecentExpenses => 'آخر المصروفات';

  @override
  String homeCycleEnded(String amount) {
    return 'انتهت دورتك — المتبقي $amount';
  }

  @override
  String get homeNegativeRemaining => 'تجاوزت الميزانية';

  @override
  String homeCarryOverLine(String amount) {
    return '+ ترحيل من الدورة السابقة: $amount';
  }

  @override
  String get expenseAdd => 'إضافة مصروف';

  @override
  String get expenseEdit => 'تعديل المصروف';

  @override
  String get expenseName => 'الاسم';

  @override
  String get expenseNameHint => 'ماذا اشتريت؟';

  @override
  String get expenseAmount => 'المبلغ';

  @override
  String get expenseQuantity => 'الكمية';

  @override
  String get expenseUnitPrice => 'سعر الوحدة';

  @override
  String get expenseCategory => 'التصنيف';

  @override
  String get expenseNoCategory => 'غير مصنّف';

  @override
  String get expenseNote => 'ملاحظة';

  @override
  String get expenseMoreDetails => 'تفاصيل إضافية';

  @override
  String get expenseSaved => 'تم حفظ المصروف';

  @override
  String get expenseDeleted => 'تم حذف المصروف';

  @override
  String expenseDeleteConfirm(String amount) {
    return 'حذف هذا المصروف بمبلغ $amount؟';
  }

  @override
  String get expenseInvalidAmount => 'أدخل مبلغًا صحيحًا';

  @override
  String get expenseInvalidQuantity => 'أدخل كمية صحيحة';

  @override
  String get expenseInvalidName => 'أدخل اسمًا';

  @override
  String get expenseSpentNow => 'الآن';

  @override
  String get expenseAmountComputed => 'المبلغ محسوب من الكمية × سعر الوحدة';

  @override
  String get expenseGroupMode => 'شراء مجموعة (نفس المحل)';

  @override
  String get expenseGroupModeHint =>
      'تُحفظ البنود تحت بطاقة واحدة. أضف كل بند ثم اضغط تم.';

  @override
  String get expenseGroupNext => 'حفظ وإضافة البند التالي';

  @override
  String expenseGroupDone(int count) {
    return 'تم ($count)';
  }

  @override
  String expenseGroupItems(int count) {
    return '$count بند';
  }

  @override
  String get expenseGroupTotal => 'إجمالي المجموعة';

  @override
  String get expensesEmpty => 'لا مصروفات';

  @override
  String get expensesSearch => 'ابحث في المصروفات';

  @override
  String get expensesFilterPeriod => 'الفترة';

  @override
  String get expensesFilterCategory => 'التصنيف';

  @override
  String get expensesAllCategories => 'كل التصنيفات';

  @override
  String get expensesDayTotal => 'مجموع اليوم';

  @override
  String get expenseSourceShoppingList => 'من قائمة';

  @override
  String get budgetTitle => 'الميزانية';

  @override
  String get budgetDisabledTitle => 'وضع الميزانية غير مفعّل';

  @override
  String get budgetDisabledHint =>
      'حدّد مبلغًا متاحًا لكل دورة لتتابع ما تبقى.';

  @override
  String get budgetEnable => 'تفعيل الميزانية';

  @override
  String get budgetStartDay => 'يوم بداية الدورة';

  @override
  String get budgetInitialAmount => 'المبلغ المتاح لكل دورة';

  @override
  String get budgetDefaultAmount => 'المبلغ الافتراضي لكل دورة';

  @override
  String get budgetDefaultAmountHint => 'يُستخدم كمبلغ بداية للدورات القادمة.';

  @override
  String get budgetCarryOver => 'ترحيل المتبقي إلى الدورة التالية';

  @override
  String get budgetCarryOverHint =>
      'عند التفعيل، ينتقل الفائض (أو النقص) إلى الدورة التالية.';

  @override
  String get budgetCurrentCycle => 'الدورة الحالية';

  @override
  String get budgetSpentInCycle => 'المصروف في هذه الدورة';

  @override
  String budgetCarryOverApplied(String amount) {
    return 'تم ترحيل: $amount';
  }

  @override
  String get budgetStartFromToday => 'البدء من اليوم بدلًا من ذلك';

  @override
  String get budgetStartFromTodayHint =>
      'تبدأ الدورة اليوم وتنتهي مع نهاية الفترة الحالية.';

  @override
  String get budgetEditAmount => 'تعديل المبلغ المتاح (المتبقي)';

  @override
  String get budgetEditAmountNote => 'هذا التعديل للدورة الحالية فقط.';

  @override
  String get budgetStartNewCycleNow => 'إغلاق الدورة وبدء دورة جديدة الآن';

  @override
  String get budgetNewCycleConfirm =>
      'إغلاق الدورة الحالية وبدء دورة جديدة الآن؟';

  @override
  String get budgetHistory => 'سجل الدورات';

  @override
  String get budgetCycleClosed => 'مغلقة';

  @override
  String get budgetCycleActive => 'نشطة';

  @override
  String get budgetDisable => 'إيقاف الميزانية';

  @override
  String get budgetDisableConfirm =>
      'إيقاف وضع الميزانية؟ تبقى الدورات السابقة في السجل.';

  @override
  String get budgetOverBudget => 'صرفت أكثر من المبلغ المتاح.';

  @override
  String get budgetDailyInfo => 'هذا مؤشر إرشادي وليس حدًا للإنفاق.';

  @override
  String get listsTitle => 'قوائم التسوق';

  @override
  String get listsEmpty => 'لا قوائم تسوق';

  @override
  String get listsNew => 'قائمة جديدة';

  @override
  String get listsNewName => 'اسم القائمة';

  @override
  String get listsCreate => 'إنشاء';

  @override
  String get listsAddItem => 'إضافة عنصر';

  @override
  String get listItemName => 'اسم العنصر';

  @override
  String get listItemEstPrice => 'السعر التقديري';

  @override
  String get listEstimatedTotal => 'الإجمالي التقديري';

  @override
  String listItemsWithoutEstimate(int count) {
    return '$count عنصر بلا تقدير';
  }

  @override
  String listVsRemaining(String total, String remaining) {
    return '$total من أصل $remaining متبقية';
  }

  @override
  String get listMarkPurchased => 'تم الشراء';

  @override
  String get listActualPrice => 'السعر الفعلي';

  @override
  String listActualPriceHint(String estimated) {
    return 'التقديري $estimated';
  }

  @override
  String get listConvertQuestion => 'تسجيل كمصروف الآن؟';

  @override
  String get listConvertTitle => 'تحويل إلى مصروف';

  @override
  String get listConverted => 'سُجّل كمصروف';

  @override
  String get listArchive => 'أرشفة';

  @override
  String get listUnarchive => 'إلغاء الأرشفة';

  @override
  String get listArchivedSection => 'مؤرشفة';

  @override
  String get listDeleteItem => 'إزالة العنصر';

  @override
  String get listEmptyList => 'هذه القائمة فارغة';

  @override
  String get statsTitle => 'الإحصائيات';

  @override
  String get statsToday => 'اليوم';

  @override
  String get statsThisWeek => 'هذا الأسبوع';

  @override
  String get statsThisMonth => 'هذا الشهر';

  @override
  String get statsThisCycle => 'الدورة الحالية';

  @override
  String get statsCustom => 'مخصص';

  @override
  String get statsTotalSpent => 'إجمالي المصروف';

  @override
  String get statsAvgDaily => 'المعدل اليومي';

  @override
  String get statsByCategory => 'المصروف حسب التصنيف';

  @override
  String get statsTopDays => 'أعلى أيام الصرف';

  @override
  String get statsNoData => 'لا مصروفات في هذه الفترة';

  @override
  String get statsUncategorized => 'غير مصنّف';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsCurrency => 'العملة';

  @override
  String get settingsBudget => 'إعدادات الميزانية';

  @override
  String get settingsPrivacy => 'الخصوصية';

  @override
  String get settingsData => 'إدارة البيانات';

  @override
  String get settingsPrivacyText =>
      'كل البيانات تُخزَّن محليًا على هذا الجهاز. يعمل التطبيق دون إنترنت كليًا ولا يرسل أي معلومات مالية إلى أي مكان.';

  @override
  String get settingsClearData => 'حذف كل البيانات';

  @override
  String get settingsClearDataConfirm =>
      'حذف كل المصروفات والقوائم وسجل الميزانية على هذا الجهاز نهائيًا؟';

  @override
  String get settingsClearDataFinal => 'لا يمكن التراجع عن هذا. حذف كل شيء؟';

  @override
  String get settingsAbout => 'حول';

  @override
  String get firstRunTitle => 'مرحبًا بك';

  @override
  String get firstRunHint => 'سجّل ما تصرفه وافهم ما تبقى.';

  @override
  String get firstRunChooseCurrency => 'اختر عملتك';

  @override
  String get firstRunCurrencyHint => 'يمكنك تغييرها لاحقًا من الإعدادات.';

  @override
  String get firstRunStart => 'ابدأ';

  @override
  String get errorInvalidInput => 'إدخال غير صحيح';

  @override
  String get errorGeneric => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get catFood => 'طعام';

  @override
  String get catHome => 'منزل';

  @override
  String get catTransport => 'مواصلات';

  @override
  String get catBills => 'فواتير';

  @override
  String get catHealth => 'صحة';

  @override
  String get catEntertainment => 'ترفيه';

  @override
  String get catOther => 'أخرى';
}
