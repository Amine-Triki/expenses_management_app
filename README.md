# Personal Expense Tracker

## English

### Overview

Personal Expense Tracker is a private, offline-first Flutter application for
recording everyday spending and understanding how much money remains. It keeps
financial data on the device and does not require an account, a backend, or an
internet connection.

The app is intentionally focused on personal spending. It is not a banking
app, accounting suite, investment tracker, or general task manager.

### Features

- Add, edit, and soft-delete expenses.
- Group items bought at the same place into one card with a derived total.
- Record an expense name, amount, date and time, category, quantity, unit price, and note.
- Use a quick entry flow with only a name and amount required.
- Optionally enable budget cycles with a configurable start day and carry-over.
- View remaining money, spending totals, remaining days, and daily available money for the current cycle.
- Create shopping lists with quantities and estimated prices.
- Mark items as purchased and convert them into expenses using the actual price.
- Browse statistics for today, this week, this month, the current cycle, or a custom date range.
- Review average daily spending, spending by category, and highest-spending days.
- Configure language and currency independently.
- Use English, Arabic (RTL), or French.

### Privacy and money handling

- Local-first and offline by design.
- No user account, cloud service, or remote financial-data collection.
- Synchronization-ready records use UUIDs, timestamps, and soft deletion.
- Money is stored as integer minor units instead of binary floating point.

### Technology

- Flutter and Dart
- SQLite through [Drift](https://drift.simonbinder.eu/)
- [Riverpod](https://riverpod.dev/) for application state
- Flutter localization with generated `l10n` files
- Material 3 UI

### Architecture

The code follows a layered architecture:

```text
Presentation
  -> Application / State
  -> Domain / Business Logic
  -> Repository
  -> Local Data Source
  -> SQLite
```

The main directories are:

- `lib/presentation`: screens, widgets, formatting, and user interaction.
- `lib/application`: controllers and Riverpod providers.
- `lib/domain`: expense, budget, currency, and cycle business rules.
- `lib/data`: Drift database, repositories, and local persistence.
- `lib/l10n`: English, Arabic, and French localization resources.
- `test`: domain, data, and application-layer tests.

### Getting started

Requirements:

- Flutter SDK with Dart `^3.13.2`.
- A configured Flutter target such as Android, iOS, Web, Linux, macOS, or Windows.

Run the project:

```bash
flutter pub get
flutter run
```

Run the test suite:

```bash
flutter test
```

Regenerate Drift and localization files when required:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

### Product scope

The MVP focuses on expenses, optional budget cycles, shopping planning,
categories, simple statistics, localization, and privacy. Bank integrations,
cloud synchronization, investment tracking, business accounting, and advanced
financial analytics are intentionally outside the current scope.

## العربية

### نبذة

Personal Expense Tracker هو تطبيق Flutter خاص يعمل محليًا أولًا وبدون اتصال
بالإنترنت، يساعد على تسجيل المصروفات اليومية وفهم المبلغ المتبقي. تُخزَّن
البيانات المالية على الجهاز فقط، ولا يحتاج التطبيق إلى حساب مستخدم أو خادم أو
اتصال بالشبكة.

التطبيق مخصص لتتبع المصروفات الشخصية، وليس تطبيقًا بنكيًا أو نظام محاسبة كاملًا
أو متتبعًا للاستثمارات أو مدير مهام عام.

### المزايا

- إضافة المصروفات وتعديلها وحذفها منطقيًا.
- تجميع مشتريات نفس المحل في بطاقة واحدة بإجمالي محسوب.
- تسجيل الاسم والمبلغ والتاريخ والوقت والتصنيف والكمية وسعر الوحدة والملاحظة.
- إضافة سريعة تتطلب الاسم والمبلغ فقط.
- ميزانية اختيارية بدورة تبدأ في يوم قابل للتخصيص مع إمكانية ترحيل المتبقي.
- عرض المتبقي وإجمالي الإنفاق وعدد الأيام المتبقية والمتاح اليومي للدورة.
- إنشاء قوائم تسوق مع الكمية والسعر التقديري.
- تعليم العناصر كمشتراة وتحويلها إلى مصروفات بالسعر الفعلي.
- إحصاءات لليوم والأسبوع والشهر والدورة الحالية أو فترة مخصصة.
- عرض متوسط الإنفاق اليومي والإنفاق حسب التصنيف وأعلى أيام الإنفاق.
- إعداد اللغة والعملة بشكل مستقل.
- دعم الإنجليزية والعربية من اليمين إلى اليسار والفرنسية.

### الخصوصية والتعامل مع الأموال

- التطبيق محلي ويعمل دون اتصال افتراضيًا.
- لا يوجد حساب مستخدم أو خادم سحابي أو جمع عن بُعد للبيانات المالية.
- السجلات جاهزة للمزامنة مستقبلًا باستخدام UUID والطوابع الزمنية والحذف المنطقي.
- تُخزَّن الأموال بوحدات نقدية صغرى صحيحة بدلًا من الأعداد العشرية العائمة.

### التقنيات

- Flutter وDart
- SQLite عبر مكتبة [Drift](https://drift.simonbinder.eu/)
- [Riverpod](https://riverpod.dev/) لإدارة حالة التطبيق
- نظام Flutter للتعريب مع ملفات `l10n` مولّدة
- واجهة Material 3

### البنية

يتبع المشروع بنية طبقية:

```text
Presentation
  -> Application / State
  -> Domain / Business Logic
  -> Repository
  -> Local Data Source
  -> SQLite
```

المجلدات الرئيسية:

- `lib/presentation`: الشاشات والواجهات والتنسيق وتفاعل المستخدم.
- `lib/application`: المتحكمات ومزوّدو Riverpod.
- `lib/domain`: قواعد المصروفات والميزانية والعملة والدورات.
- `lib/data`: قاعدة Drift والمستودعات والتخزين المحلي.
- `lib/l10n`: موارد التعريب بالإنجليزية والعربية والفرنسية.
- `test`: اختبارات طبقات المجال والبيانات والتطبيق.

### التشغيل والتطوير

المتطلبات:

- Flutter SDK مع Dart `^3.13.2`.
- هدف Flutter مُعدّ مثل Android أو iOS أو Web أو Linux أو macOS أو Windows.

تشغيل المشروع:

```bash
flutter pub get
flutter run
```

تشغيل الاختبارات:

```bash
flutter test
```

إعادة توليد ملفات Drift والتعريب عند الحاجة:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

### نطاق المشروع

يركز الإصدار الأولي على المصروفات ودورات الميزانية الاختيارية والتخطيط للتسوق
والتصنيفات والإحصاءات البسيطة والتعريب والخصوصية. تكاملات البنوك والمزامنة
السحابية وتتبع الاستثمارات والمحاسبة التجارية والتحليلات المالية المتقدمة خارج
النطاق الحالي عمدًا.

## Author

Developed by [Amine Triki](https://amine-triki.tn/).
