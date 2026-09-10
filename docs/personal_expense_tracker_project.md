# Personal Expense Tracker — Project Constitution

> Persistent project reference: stable product decisions, architecture rules, technical conventions, and development principles.
> Temporary tasks and one-time prompts do not belong here.

## 1. Product Identity

A lightweight personal expense tracker focused on speed, simplicity, privacy, and offline use.

Core idea:

> Record what you spend and understand what remains.

The app is not a bank, accounting suite, investment tracker, general notes app, or general task manager.

## 2. Core Product Decisions

### Expenses

Users can:
- Add, edit, and delete expenses.
- Record name, amount, quantity, and unit price when useful.
- Enter a final amount directly.
- Record date and time.
- Add an optional category.
- Add an optional note.

Quick entry should require only:
`Name → Amount → Save`

### Available Money

Use one main concept:

> Available Money

The app does not need to know whether money is cash, available on a card, or available through mobile payment.

The MVP does not model separate bank accounts, savings accounts, cards, wallets, or payment providers.

## 3. Budget System

Budget tracking is optional.

The user may define:
- Initial available amount.
- Budget-cycle start day.
- Carry-over preference.

A budget cycle is not necessarily aligned with the calendar month.

Examples:
- Day 1 → 1 through end of month.
- Day 15 → 15 through 14.
- Day 25 → 25 through 24.

Conceptually:

`Remaining = Initial Amount + Carry-over - Expenses`

Daily indicator:

`Remaining / Remaining Days`

This is informational, not a hard spending limit.

Cycle lifecycle rules:
- The current cycle is derived from the start day and today's date; a cycle row is materialized only at activation and at close.
- No future cycle rows. No empty backfilled cycles for periods when the app was not opened.
- The first cycle covers the current period containing the activation date (retroactive); an optional "start from today" choice creates a partial cycle until the current period's natural end.
- A cycle closes on the first app open after its end date, or immediately on a manual restart.
- At close, a full snapshot is stored once and never recomputed: `final_expense_total`, `final_remaining`, `closed_at`.
- Carry-over, when enabled, transfers directly from the last closed cycle to the newly created current cycle.
- Negative remaining is carried as-is when carry-over is enabled and ignored (fresh start) when disabled.
- Current cycle amount and Default budget amount are separate; editing the current cycle never changes the default. The entered value is the AVAILABLE remaining (initial = entered + spent so far).
- Editing or deleting an expense that belongs to a closed cycle affects live statistics only; it never rebuilds the snapshot or historical carry-over.
- INVARIANT: the open cycle always contains today. A manual restart closes the cycle with yesterday as its last day (end_date rewritten) and the new cycle starts today as a partial window; a cycle that started today is aborted (tombstoned). Re-activation while a cycle is open follows the same rule.
- Cycle `start_date`/`end_date` are local calendar dates tied to the user's day, not UTC instants.

## 4. Shopping Lists

Shopping lists are part of the product because they directly support spending decisions.

They are not intended to become a general task manager.

A shopping item may contain:
- Name.
- Quantity.
- Estimated price.
- Optional note.
- Purchased state.

The app calculates an estimated total.

After purchase, the user can enter the actual price and convert the item into a real expense.

Example:

`Estimated = 4`
`Actual = 4.5`

The expense must use the actual amount.

Additional conversion rules:
- Conversion is item-by-item in the MVP; there is no bulk conversion.
- When an item is linked to an active expense (`deleted_at IS NULL`), that expense's amount is the source of truth for the actual amount; `actual_amount` on the item applies only when no active linked expense exists.
- Completed lists are not archived or deleted automatically; archiving and deletion are manual. `archived_at` is a separate concept from `deleted_at`.

## 5. Categories

Categories are optional.

Possible defaults:
- Food
- Home
- Transportation
- Bills
- Health
- Entertainment
- Other

Never force category selection during quick expense entry.

Categories primarily support statistics and filtering.

## 6. Statistics

Keep statistics simple:
- Today.
- This week.
- This month.
- Current budget cycle.
- Custom date range.
- Average daily spending.
- Spending by category.
- Highest-spending days.

Prefer calculating derived values from authoritative source data rather than storing redundant totals.

## 7. Privacy

Privacy is a core product principle.

MVP:
- Offline-first.
- Local-first.
- No account.
- No backend.
- No cloud requirement.
- Financial data stored locally.
- No unnecessary remote collection of financial information.

Future analytics, crash reporting, backup, and synchronization must be evaluated separately and clearly disclosed.

## 8. Technology

Primary stack:
- Flutter
- Dart
- SQLite

SQLite is sufficient for the MVP.

Do not introduce PostgreSQL, MariaDB, MySQL, or a backend unless a future requirement explicitly justifies it.

## 9. Architecture

Use layered architecture:

```text
Presentation
    ↓
Application / State
    ↓
Domain / Business Logic
    ↓
Repository
    ↓
Local Data Source
    ↓
SQLite
```

Future:

```text
                    ┌── Local Data Source ── SQLite
Repository ─────────┤
                    └── Sync Layer ── Cloud API
```

UI must not directly query SQLite.

### Responsibilities

**Presentation**
- Screens and widgets.
- User interaction.
- Display formatting.
- No database queries or core financial rules.

**Application / State**
- UI state.
- User actions.
- Coordination.

**Domain / Business Logic**
- Expense calculations.
- Budget-cycle calculations.
- Remaining-money calculations.
- Carry-over rules.
- Shopping-list conversion rules.
- Must remain independent from Flutter UI and SQLite.

**Repository**
- Stable interface between application/domain logic and data sources.
- Hides whether data comes from SQLite, cache, cloud, or synchronization.

**Data Source**
- Persistence implementation.

## 10. Synchronization-Ready Data

Even without cloud synchronization in MVP, synchronizable entities use:

- `id`
- `created_at`
- `updated_at`
- `deleted_at`

Use UUIDs instead of relying only on SQLite auto-increment IDs.

Rules:
- `created_at` is set on creation and never changes.
- `updated_at` changes whenever mutable data changes.
- `deleted_at = NULL` means active.
- `deleted_at != NULL` means logically deleted.

Do not physically delete synchronizable records without a deliberate cleanup strategy.

Future synchronization may require:
- Sync status.
- Offline queue.
- Last-sync timestamp.
- Conflict detection.
- Conflict resolution.
- Tombstones.
- Server-side versioning/timestamps.

Do not implement these prematurely.

## 11. Money Representation

Do not use binary floating point as the authoritative representation of money.

Prefer integer minor units where appropriate.

Example:

`12.50 TND → 1250 minor units`

Do not assume every currency has exactly two decimal places.

Formatting belongs to the presentation/localization layer.

Quantity (when used) is not money:
- Fractional quantities are allowed and stored as scaled integers with three fixed decimal places (value × 1000).
- Quantity precision is independent of currency precision.
- No unit field in the MVP; unit semantics live in the item name or note.

Timestamps are stored in UTC (epoch milliseconds); display converts to the user's local timezone.

## 12. Database Entities

Initial conceptual entities:

### `expenses`
- `id`
- `name`
- `quantity`
- `unit_price`
- `amount`
- `category_id`
- `group_id` (nullable — purchase-group membership)
- `note`
- `spent_at` (actual transaction time, distinct from `created_at`)
- `expense_source` (`manual` / `shopping_list`)
- `created_at`
- `updated_at`
- `deleted_at`

### `categories`
- `id`
- `name`
- `sort_order`
- `created_at`
- `updated_at`
- `deleted_at`

### `expense_groups` (purchase groups)
- `id`
- `name`
- `created_at`
- `updated_at`
- `deleted_at`

Members join via `expenses.group_id`; group totals are always derived from
active member expenses and never stored.

### `budget_cycles`
- `id`
- `start_day`
- `start_date`
- `end_date`
- `initial_amount`
- `carry_over_amount`
- `carry_over_enabled`
- `previous_cycle_id`
- `closed_at`
- `final_expense_total`
- `final_remaining`
- `created_at`
- `updated_at`
- `deleted_at`

### `shopping_lists`
- `id`
- `name`
- `archived_at`
- `created_at`
- `updated_at`
- `deleted_at`

### `shopping_list_items`
- `id`
- `shopping_list_id`
- `name`
- `quantity`
- `estimated_unit_price`
- `note`
- `purchased`
- `purchased_at`
- `expense_id`
- `actual_amount`
- `created_at`
- `updated_at`
- `deleted_at`

### `settings`

Application preferences such as:
- Language.
- Currency.
- First-run state.
- Default budget amount.
- User preferences.

Exact schema is detailed and validated in the planning document (`docs/personal_expense_tracker_planning.md`, section E).

## 13. Data Integrity

Business-critical calculations must be deterministic.

Avoid duplicated sources of truth.

If a value can reliably be derived from authoritative records, calculate it rather than storing multiple copies.

If caching is introduced, define invalidation/recalculation rules.

Closed budget cycles are a deliberate exception: their snapshot fields (`final_expense_total`, `final_remaining`) are frozen once at close and never recomputed. Derived estimated values for shopping-list items are computed at display time and not stored.

## 14. Localization

Localization is part of the MVP.

Initial languages:
- Arabic.
- English.
- French.

Requirements:
- Arabic RTL.
- English/French LTR.
- All user-facing strings come from localization resources.
- No hard-coded UI strings.
- Layouts tolerate different text lengths.
- Language is independent from currency.
- Architecture allows adding languages later.

## 15. Currency

Currency is independent from language.

Examples:
- Arabic does not imply Tunisian dinar.
- French does not imply euro.
- English does not imply US dollar.

Currency is a separate configurable setting.

The currency is always chosen explicitly by the user (first-launch selection); it is never inferred from language or location.

## 16. UX Principles

Priority:
1. Speed.
2. Simplicity.
3. Clarity.
4. Privacy.
5. Reliability.
6. Extensibility.

The application should not feel like accounting software.

Quick expense flow:

`+ Expense → Name → Amount → Save`

Optional details must not block the basic flow.

## 17. Main Screens

Conceptual screens:

```text
Home
├── Add Expense
├── Expenses
├── Statistics
├── Budget
├── Shopping Lists
└── Settings
```

The final navigation structure may be refined during UX planning.

### Home
Potentially shows:
- Available amount.
- Spent amount.
- Remaining amount.
- Daily indicator.
- Current budget cycle.
- Recent expenses.
- Quick Add Expense.

### Expenses
- History.
- Search.
- Date filtering.
- Category filtering.
- Edit/delete.

### Shopping Lists
- Create list.
- Add items.
- Estimated totals.
- Purchased state.
- Actual price.
- Convert to expense.

### Statistics
Simple spending summaries.

### Budget
- Enable/disable budget mode.
- Configure start day.
- Configure initial amount.
- Configure carry-over.

### Settings
- Language.
- Currency.
- Preferences.
- Data management.
- Privacy information.

## 18. Features Outside MVP

Do not add without explicit product approval:
- User accounts.
- Cloud synchronization.
- Bank integrations.
- Automatic bank transaction imports.
- Investment tracking.
- Debt management.
- Business accounting.
- General task management.
- General notes.
- Social features.
- Complex recurring financial systems.
- Advanced financial analytics.

## 19. Data Portability

Local export/import is desirable for a privacy-first application.

Possible future support:
- JSON backup.
- CSV expense export.
- Local restore.

Export/import is separate from cloud synchronization.

## 20. Code Quality

- Prefer readable code over clever code.
- Keep functions focused.
- Avoid unnecessary abstractions.
- Avoid premature optimization.
- Keep business rules independently testable.
- Keep persistence concerns out of presentation.
- Use strong typing.
- Prefer immutable models where practical.
- Handle nullable values deliberately.
- Never silently ignore important failures.

Use clear domain-oriented names.

Comments should explain why non-obvious code exists, not restate obvious code.

## 21. Testing

Prioritize tests for:
- Expense calculations.
- Exact money arithmetic.
- Budget-cycle boundaries.
- Different month lengths.
- Start days near month ends.
- Remaining amount.
- Carry-over.
- Shopping-list totals.
- Estimated-to-actual expense conversion.
- Date/time behavior.
- Important localization behavior.

Business logic must be testable independently of UI.

## 22. Error Handling

Errors must be explicit and understandable.

Examples:
- Invalid amount.
- Invalid quantity.
- Invalid budget configuration.
- Database failure.
- Migration failure.

Do not silently ignore failed writes.

Financial data correctness has priority over convenience.

## 23. Database Migrations

All schema changes must use explicit, versioned migrations.

Never assume the user's database is empty after an update.

Migrations must:
- Preserve user data.
- Be testable.
- Have a clear upgrade path.

## 24. Security

Do not expose financial information unnecessarily through:
- Logs.
- Debug output.
- Analytics.
- Error reports.

Avoid logging complete financial records.

Future backup/cloud features must define their security model before implementation.

## 25. Development Workflow

For a major feature:

1. Confirm product requirement.
2. Confirm user flow.
3. Confirm data changes.
4. Confirm business rules.
5. Identify edge cases.
6. Define tests.
7. Implement.
8. Verify offline behavior.
9. Verify localization.
10. Review architecture impact.

Do not add features merely because they are technically easy.

## 26. Decision-Making Rules

For every proposed feature, ask:

- Does it improve `Record → Understand → Decide`?
- Does it add unnecessary complexity?
- Does it compromise offline operation?
- Does it compromise privacy?
- Does it make future synchronization harder?
- Can it remain optional?

Prefer optional features when they are not essential.

## 27. Product Boundary

The product is:

> A private, offline-first personal spending tracker with optional budget cycles and shopping planning.

It is not:
- A bank.
- A financial institution.
- An accounting ERP.
- A general notes app.
- A general task manager.
- An investment platform.

## 28. Stable Decisions Summary

| Decision | Status |
|---|---|
| Flutter | Confirmed |
| Dart | Confirmed |
| SQLite | Confirmed |
| Offline-first | Confirmed |
| Local-first | Confirmed |
| Privacy-first | Confirmed |
| No account in MVP | Confirmed |
| No backend in MVP | Confirmed |
| Expense tracking | Core |
| Budget mode | Optional |
| Flexible budget start day | Confirmed |
| Carry-over | Optional |
| Categories | Optional |
| Shopping lists | Included |
| Estimated shopping prices | Included |
| Convert purchased item to expense | Included |
| Arabic | MVP |
| English | MVP |
| French | MVP |
| RTL/LTR | Required |
| UUID IDs | Required |
| UUID v7 for entity IDs (time-ordered; domain ordering stays on explicit timestamps) | Confirmed |
| `created_at` | Required |
| `updated_at` | Required |
| `deleted_at` | Required for sync-ready entities |
| Repository/data abstraction | Required |
| Cloud synchronization | Future |
| Bank integration | Out of MVP |
| General task manager | Out of MVP |
| General notes app | Out of MVP |
| Floating point as authoritative money representation | Prohibited |
| Direct UI → SQLite access | Prohibited |
| Lazy cycle materialization (no future/empty cycles) | Confirmed |
| Cycle-close snapshot (`final_*`, `closed_at`), never recomputed | Confirmed |
| Closed-cycle edits affect statistics only | Confirmed |
| Current vs Default budget amount separation | Confirmed |
| Carry-over transfers directly across gaps | Confirmed |
| First cycle retroactive (current period) | Confirmed |
| Currency chosen explicitly, never inferred | Confirmed |
| Bulk list conversion | Out of MVP |
| Timestamps UTC; cycle boundaries are local calendar dates | Confirmed |
| Minor units per currency (ISO 4217, e.g., TND millimes) | Confirmed |
| Quantity as scaled integer ×1000, no unit field | Confirmed |
| Storing shopping item estimated amount | Prohibited (computed at display) |
| `actual_amount` secondary to linked active expense | Confirmed |
| Manual list archive (`archived_at` ≠ `deleted_at`) | Confirmed |
| Purchase groups: members via `group_id`, derived total, unlimited items | Confirmed (owner-requested) |
| Cycle invariant: open cycle always contains today; manual restart closes at yesterday, new starts today | Confirmed |

## 29. Source of Truth

This document is the stable project reference.

When a stable decision changes:

1. Explicitly identify the changed decision.
2. Explain the reason.
3. Update this document.
4. Remove or resolve conflicting rules elsewhere.

Temporary planning prompts do not belong here.

Implementation-specific details may be added when they become stable project decisions.

The planning document (`docs/personal_expense_tracker_planning.md`) is the detailed implementation contract derived from this constitution. Decisions discovered during implementation must be escalated to the product owner, never silently decided.
