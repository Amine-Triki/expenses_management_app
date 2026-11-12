# My Expenses Log (Personal Expense Tracker)

## English

### Overview

My Expenses Log (Personal Expense Tracker) is a private, offline-first Flutter application for
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
- Optionally enable budget cycles with a configurable start day.
- View remaining money, spending totals, remaining days, and daily available money for the current cycle.
- Create shopping lists with quantities and estimated prices.
- Mark items as purchased and convert them into expenses using the actual price.
- Schedule optional one-time, weekly, or monthly local reminders for shopping lists.
- Archive shopping lists manually without deleting them.
- Browse statistics for today, this week, this month, the current cycle, or a custom date range.
- Review average daily spending, spending by category, and highest-spending days.
- Export a complete SQLite backup or expenses as CSV, and restore a local backup.
- Protect the app with an optional local PIN lock.
- Configure language and currency independently.
- Use English, Arabic (RTL), French, or Chinese.

The current release is `0.1.4+5`.

### Privacy and money handling

- Local-first and offline by design.
- No user account, cloud service, or remote financial-data collection.
- Synchronization-ready records use UUIDs, timestamps, and soft deletion.
- Money is stored as integer minor units instead of binary floating point.
- Backups and CSV exports are initiated locally through system file dialogs.

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
- `lib/application`: controllers, Riverpod providers, backup/restore, and local reminders.
- `lib/domain`: expense, budget, currency, and cycle business rules.
- `lib/data`: Drift database, repositories, and local persistence.
- `lib/l10n`: English, Arabic, French, and Chinese localization resources.
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

### App startup flow

At launch the app runs in this order:

1. Builtin categories are seeded idempotently, settings load, reminder
   scheduling is initialized, and the current budget cycle is ensured before
   any UI appears.
2. If privacy consent has not been accepted, the **Privacy Consent** screen is
   shown first and cannot be dismissed by back navigation.
3. On the **First Run** screen the user explicitly picks a currency; it is
   never inferred from language or region.
4. The app then enters the main shell: four tabs (Home / Expenses / Lists /
   Stats) with Budget and Settings as secondary screens.
5. If the optional PIN lock is enabled, a `LockGate` wraps the whole app and
   requires the PIN before any content is revealed.

### Android build and release

The Android target is configured in `android/app/build.gradle.kts`:

- Application ID: `com.aminetriki.expenses_management_app`.
- `compileSdk = 37`; `minSdk` and `targetSdk` come from the Flutter toolchain.
- Version code and name come from `pubspec.yaml`.
- Java 17 with core library desugaring (`desugar_jdk_libs:2.1.5`).
- Toolchain: Gradle 9.3.1, Android Gradle Plugin 9.1.1, Kotlin 2.4.0.
- Release builds use R8 with `isMinifyEnabled` and `isShrinkResources` enabled.
- Release signing reads `android/key.properties` (`keyAlias`, `keyPassword`,
  `storeFile`, `storePassword`); if the file or keystore is missing, release
  builds fall back to debug signing so the project always builds.

To create your own release keystore:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
        -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` (never commit it):

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

### Android permissions

- `POST_NOTIFICATIONS`: required on Android 13+ to show shopping-list
  reminders; requested only when the first reminder is enabled.
- `RECEIVE_BOOT_COMPLETED`: a boot receiver re-schedules list reminders after a
  device restart so they survive reboots.

### Security notes for contributors

This repository is published publicly. Never commit:

- `android/key.properties` (already ignored by `.gitignore`).
- Keystore files: `*.jks`, `*.keystore`, `*.p12` (already ignored).
- `android/local.properties` (machine-specific paths and Flutter build state).

Keep API-free: the app has no accounts, no backend, and no cloud services, so
no runtime secrets belong in the codebase.

### Product scope

The MVP focuses on expenses, optional budget cycles, shopping planning,
categories, simple statistics, localization, and privacy. Bank integrations,
cloud synchronization, investment tracking, business accounting, and advanced
financial analytics are intentionally outside the current scope.

## العربية

### نبذة

My Expenses Log (Personal Expense Tracker) هو تطبيق Flutter خاص يعمل محليًا أولًا وبدون اتصال
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
- ميزانية اختيارية بدورة تبدأ في يوم قابل للتخصيص.
- عرض المتبقي وإجمالي الإنفاق وعدد الأيام المتبقية والمتاح اليومي للدورة.
- إنشاء قوائم تسوق مع الكمية والسعر التقديري.
- تعليم العناصر كمشتراة وتحويلها إلى مصروفات بالسعر الفعلي.
- جدولة تذكيرات محلية اختيارية لقوائم التسوق لمرة واحدة أو أسبوعيًا أو شهريًا.
- أرشفة قوائم التسوق يدويًا دون حذفها.
- إحصاءات لليوم والأسبوع والشهر والدورة الحالية أو فترة مخصصة.
- عرض متوسط الإنفاق اليومي والإنفاق حسب التصنيف وأعلى أيام الإنفاق.
- تصدير نسخة SQLite احتياطية كاملة أو المصروفات بصيغة CSV واستعادة نسخة محلية.
- حماية التطبيق بقفل PIN محلي اختياري.
- إعداد اللغة والعملة بشكل مستقل.
- دعم الإنجليزية والعربية من اليمين إلى اليسار والفرنسية والصينية.

### الخصوصية والتعامل مع الأموال

- التطبيق محلي ويعمل دون اتصال افتراضيًا.
- لا يوجد حساب مستخدم أو خادم سحابي أو جمع عن بُعد للبيانات المالية.
- السجلات جاهزة للمزامنة مستقبلًا باستخدام UUID والطوابع الزمنية والحذف المنطقي.
- تُخزَّن الأموال بوحدات نقدية صغرى صحيحة بدلًا من الأعداد العشرية العائمة.
- تتم النسخ الاحتياطية وتصديرات CSV محليًا عبر نوافذ اختيار الملفات في النظام.

الإصدار الحالي هو `0.1.4+5`.

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
- `lib/application`: المتحكمات ومزوّدو Riverpod والنسخ الاحتياطي والتذكيرات المحلية.
- `lib/domain`: قواعد المصروفات والميزانية والعملة والدورات.
- `lib/data`: قاعدة Drift والمستودعات والتخزين المحلي.
- `lib/l10n`: موارد التعريب بالإنجليزية والعربية والفرنسية والصينية.
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

### تسلسل الإقلاع

عند فتح التطبيق تسير الأمور بهذا الترتيب:

1. تُزرع التصنيفات الافتراضية، تُحمَّل الإعدادات، تُهيّأ خدمة التذكيرات، ويُضمن
   وجود دورة الميزانية الحالية قبل ظهور أي واجهة.
2. إن لم تُقبل سياسة الخصوصية بعد، تُعرض أولًا شاشة **الموافقة على الخصوصية**
   ولا يمكن تجاوزها بزر الرجوع.
3. في شاشة **أول تشغيل** يختار المستخدم العملة صراحةً، ولا تُستنتج أبدًا من
   اللغة أو المنطقة.
4. بعدها يدخل التطبيق الهيكل الرئيسي: أربعة تبويبات (Home / Expenses / Lists /
   Stats) مع شاشتي Budget وSettings الثانويتين.
5. إن كان قفل PIN مفعّلًا، يغلّف `LockGate` التطبيق كاملًا ويطلب الرمز قبل إظهار
   أي محتوى.

### بناء وإصدار Android

هدف Android مُعدّ في `android/app/build.gradle.kts`:

- معرّف التطبيق: `com.aminetriki.expenses_management_app`.
- `compileSdk = 37`؛ و`minSdk` و`targetSdk` من أدوات Flutter.
- رقم الإصدار واسمه يأتيان من `pubspec.yaml`.
- Java 17 مع تفعيل core library desugaring (`desugar_jdk_libs:2.1.5`).
- أدوات البناء: Gradle 9.3.1، Android Gradle Plugin 9.1.1، Kotlin 2.4.0.
- إصدارات Release تستخدم R8 مع تفعيل `isMinifyEnabled` و`isShrinkResources`.
- توقيع Release يقرأ `android/key.properties` (`keyAlias`، `keyPassword`،
  `storeFile`، `storePassword`)؛ إن غاب الملف أو المخزن، ترجع إصدارات Release
  إلى توقيع debug حتى لا يتعطل البناء أبدًا.

لإنشاء مخزن مفاتيح الإصدار الخاص بك:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
        -keysize 2048 -validity 10000 -alias upload
```

ثم أنشئ `android/key.properties` (لا ترفعه أبدًا إلى المستودع):

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

### أذونات Android

- `POST_NOTIFICATIONS`: مطلوب في Android 13+ لإظهار تذكيرات قوائم التسوق، ولا
  يُطلب إلا عند تفعيل أول تذكير.
- `RECEIVE_BOOT_COMPLETED`: مستقبِل إقلاع يعيد جدولة تذكيرات القوائم بعد إعادة
  تشغيل الجهاز لضمان بقائها.

### ملاحظات أمنية للمساهمين

هذا المستودع منشور علنًا. لا ترفع أبدًا:

- `android/key.properties` (متجاهل مسبقًا في `.gitignore`).
- ملفات مخازن المفاتيح: `*.jks`، `*.keystore`، `*.p12` (متجاهلة مسبقًا).
- `android/local.properties` (مسارات خاصة بالجهاز وحالة بناء Flutter).

التطبيق بلا خدمات خارجية: لا حسابات ولا خادم ولا خدمات سحابية، لذا لا تنتمي أي
أسرار تشغيلية إلى الكود.

### نطاق المشروع

يركز الإصدار الأولي على المصروفات ودورات الميزانية الاختيارية والتخطيط للتسوق
والتصنيفات والإحصاءات البسيطة والتعريب والخصوصية. تكاملات البنوك والمزامنة
السحابية وتتبع الاستثمارات والمحاسبة التجارية والتحليلات المالية المتقدمة خارج
النطاق الحالي عمدًا.

## License

This project is licensed under the [MIT License](LICENSE).

## Author

Developed by [Amine Triki](https://amine-triki.tn/).