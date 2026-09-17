// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '记账助手';

  @override
  String get navHome => '首页';

  @override
  String get navExpenses => '支出';

  @override
  String get navLists => '清单';

  @override
  String get navStats => '统计';

  @override
  String get navSettings => '设置';

  @override
  String get navBudget => '预算';

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '确定';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '删除';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonYes => '是';

  @override
  String get commonNo => '否';

  @override
  String get commonUndo => '撤销';

  @override
  String get commonBack => '返回';

  @override
  String get commonToday => '今天';

  @override
  String get commonYesterday => '昨天';

  @override
  String get homeEmptyTitle => '还没有支出记录';

  @override
  String get homeEmptyHint => '点击下方按钮添加第一笔支出';

  @override
  String get homeNoBudgetTitle => '预算模式已关闭';

  @override
  String homeNoBudgetHint(String monthTotal) {
    return '本月已花费 $monthTotal';
  }

  @override
  String get homeEnableBudget => '开启预算';

  @override
  String get homeAvailable => '可用';

  @override
  String get homeSpent => '已花费';

  @override
  String get homeRemaining => '剩余';

  @override
  String homeCyclePeriod(String start, String end) {
    return '周期 $start – $end';
  }

  @override
  String homeDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '剩余 $count 天',
    );
    return '$_temp0';
  }

  @override
  String homeDailyAllowance(int days, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '本周期还剩 $days 天 — 每天可花费 $amount',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentExpenses => '最近支出';

  @override
  String homeCycleEnded(String amount) {
    return '周期已结束 — 剩余 $amount';
  }

  @override
  String get homeNegativeRemaining => '超出预算';

  @override
  String homeCarryOverLine(String amount) {
    return '+ 上一周期结转：$amount';
  }

  @override
  String get expenseAdd => '添加支出';

  @override
  String get expenseEdit => '编辑支出';

  @override
  String get expenseName => '名称';

  @override
  String get expenseNameHint => '买了什么？';

  @override
  String get expenseAmount => '金额';

  @override
  String get expenseQuantity => '数量';

  @override
  String get expenseUnitPrice => '单价';

  @override
  String get expenseCategory => '类别';

  @override
  String get expenseNoCategory => '未分类';

  @override
  String get expenseNote => '备注';

  @override
  String get expenseMoreDetails => '更多详情';

  @override
  String get expenseSaved => '支出已保存';

  @override
  String get expenseDeleted => '支出已删除';

  @override
  String expenseDeleteConfirm(String amount) {
    return '删除这笔金额为 $amount 的支出？';
  }

  @override
  String get expenseInvalidAmount => '请输入有效金额';

  @override
  String get expenseInvalidQuantity => '请输入有效数量';

  @override
  String get expenseInvalidName => '请输入名称';

  @override
  String get expenseSpentNow => '刚刚';

  @override
  String get expenseAmountComputed => '金额由数量 × 单价计算得出';

  @override
  String get expenseGroupMode => '合并购买（同一地点）';

  @override
  String get expenseGroupModeHint => '各项保存在同一卡片下。逐项添加，然后点击完成。';

  @override
  String get expenseGroupNext => '保存并添加下一项';

  @override
  String expenseGroupDone(int count) {
    return '完成（$count）';
  }

  @override
  String expenseGroupItems(int count) {
    return '$count 项';
  }

  @override
  String get expenseGroupTotal => '合计';

  @override
  String get expensesEmpty => '暂无支出';

  @override
  String get expensesSearch => '搜索支出';

  @override
  String get expensesFilterPeriod => '时段';

  @override
  String get expensesFilterCategory => '类别';

  @override
  String get expensesAllCategories => '所有类别';

  @override
  String get expensesDayTotal => '当日合计';

  @override
  String get expenseSourceShoppingList => '来自清单';

  @override
  String get budgetTitle => '预算';

  @override
  String get budgetDisabledTitle => '预算模式已关闭';

  @override
  String get budgetDisabledHint => '设置每个周期的可用金额，以跟踪剩余款项。';

  @override
  String get budgetEnable => '开启预算';

  @override
  String get budgetStartDay => '周期起始日';

  @override
  String get budgetInitialAmount => '每个周期的可用金额';

  @override
  String get budgetDefaultAmount => '每个周期的默认金额';

  @override
  String get budgetDefaultAmountHint => '用作未来周期的起始金额。';

  @override
  String get budgetCarryOver => '将剩余金额结转至下一周期';

  @override
  String get budgetCarryOverHint => '开启后，剩余（或超支）金额将结转到下一周期。';

  @override
  String get budgetCurrentCycle => '当前周期';

  @override
  String get budgetSpentInCycle => '本周期已花费';

  @override
  String budgetCarryOverApplied(String amount) {
    return '已结转：$amount';
  }

  @override
  String get budgetStartFromToday => '改为从今天开始';

  @override
  String get budgetStartFromTodayHint => '周期从今天开始，并与当前时段同时结束。';

  @override
  String get budgetEditAmount => '编辑可用金额（剩余）';

  @override
  String get budgetEditAmountNote => '此更改仅适用于当前周期。';

  @override
  String get budgetStartNewCycleNow => '结束当前周期并立即开始新周期';

  @override
  String get budgetNewCycleConfirm => '结束当前周期并立即开始新周期？';

  @override
  String get budgetHistory => '周期历史';

  @override
  String get budgetCycleClosed => '已结束';

  @override
  String get budgetCycleActive => '进行中';

  @override
  String get budgetDisable => '关闭预算';

  @override
  String get budgetDisableConfirm => '关闭预算模式？历史周期将保留。';

  @override
  String get budgetOverBudget => '您的花费已超过可用金额。';

  @override
  String get budgetDailyInfo => '这只是一个指标，并非消费限制。';

  @override
  String get listsTitle => '购物清单';

  @override
  String get listsEmpty => '暂无购物清单';

  @override
  String get listsNew => '新建清单';

  @override
  String get listsNewName => '清单名称';

  @override
  String get listsCreate => '创建';

  @override
  String get listsAddItem => '添加条目';

  @override
  String get listItemName => '条目名称';

  @override
  String get listItemEstPrice => '预估价格';

  @override
  String get listEstimatedTotal => '预估总计';

  @override
  String listItemsWithoutEstimate(int count) {
    return '$count 项未估价';
  }

  @override
  String listVsRemaining(String total, String remaining) {
    return '总计 $total，剩余 $remaining';
  }

  @override
  String get listMarkPurchased => '已购买';

  @override
  String get listActualPrice => '实际价格';

  @override
  String listActualPriceHint(String estimated) {
    return '预估 $estimated';
  }

  @override
  String get listConvertQuestion => '立即记为一笔支出？';

  @override
  String get listConvertTitle => '转为支出';

  @override
  String get listConverted => '已记为支出';

  @override
  String get listArchive => '归档';

  @override
  String get listUnarchive => '取消归档';

  @override
  String get listArchivedSection => '已归档';

  @override
  String get listDeleteItem => '移除条目';

  @override
  String get listEmptyList => '此清单为空';

  @override
  String get statsTitle => '统计';

  @override
  String get statsToday => '今天';

  @override
  String get statsThisWeek => '本周';

  @override
  String get statsThisMonth => '本月';

  @override
  String get statsThisCycle => '本周期';

  @override
  String get statsCustom => '自定义';

  @override
  String get statsTotalSpent => '总花费';

  @override
  String get statsAvgDaily => '日均';

  @override
  String get statsByCategory => '按类别支出';

  @override
  String get statsTopDays => '花费最高的日子';

  @override
  String get statsNoData => '此时间段内没有花费';

  @override
  String get statsUncategorized => '未分类';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsCurrency => '货币';

  @override
  String get settingsBudget => '预算设置';

  @override
  String get settingsPrivacy => '隐私';

  @override
  String get settingsData => '数据管理';

  @override
  String get settingsBackupExport => '导出备份';

  @override
  String get settingsBackupExportHint => '将所有数据保存到一个文件';

  @override
  String get settingsBackupRestore => '恢复备份';

  @override
  String get settingsBackupRestoreHint => '用备份文件替换当前所有数据';

  @override
  String get settingsBackupRestoreConfirm => '恢复此备份吗？当前所有数据将被替换。';

  @override
  String get settingsBackupExported => '备份已导出';

  @override
  String get settingsBackupRestored => '备份已恢复';

  @override
  String get settingsBackupFailed => '备份失败，请重试。';

  @override
  String get settingsBackupInvalidFile => '此文件不是有效的备份。';

  @override
  String get settingsBackupTooNew => '此备份来自更新版本的应用，请先更新应用。';

  @override
  String get settingsPrivacyText => '所有数据都存储在本设备上。应用完全离线运行，不会向任何地方发送任何财务信息。';

  @override
  String get settingsPrivacyPolicy => '阅读隐私政策';

  @override
  String get settingsClearData => '删除所有数据';

  @override
  String get settingsClearDataConfirm => '永久删除本设备上的所有支出、清单和预算历史？';

  @override
  String get settingsClearDataFinal => '此操作无法撤销。确定全部删除？';

  @override
  String get settingsAbout => '关于';

  @override
  String get aboutDevelopedBy => '由 Amine Triki 开发';

  @override
  String get firstRunTitle => '欢迎使用';

  @override
  String get firstRunHint => '记录您的每一笔花费，掌握剩余情况。';

  @override
  String get firstRunChooseCurrency => '选择您的货币';

  @override
  String get firstRunCurrencyHint => '您可以稍后在设置中更改。';

  @override
  String get firstRunStart => '开始';

  @override
  String get privacyConsentTitle => '隐私政策';

  @override
  String get privacyConsentMessage => '请在使用记账助手之前阅读并同意隐私政策。';

  @override
  String get privacyReadPolicy => '阅读隐私政策';

  @override
  String get privacyAccept => '同意并继续';

  @override
  String get privacyDecline => '不同意并退出';

  @override
  String get errorInvalidInput => '输入无效';

  @override
  String get errorGeneric => '出现问题。请重试。';

  @override
  String get catFood => '餐饮';

  @override
  String get catHome => '居家';

  @override
  String get catTransport => '交通';

  @override
  String get catBills => '账单';

  @override
  String get catHealth => '健康';

  @override
  String get catEntertainment => '娱乐';

  @override
  String get catOther => '其他';
}
