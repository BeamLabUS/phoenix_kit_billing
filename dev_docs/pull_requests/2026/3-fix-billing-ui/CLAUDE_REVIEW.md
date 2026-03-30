# Code Review: PR #3 — Fix billing UI, routes, schema, and add edit mode

**Reviewed:** 2026-03-30
**Reviewer:** Claude (claude-opus-4-6)
**PR:** https://github.com/BeamLabEU/phoenix_kit_billing/pull/3
**Author:** Tim (timujinne)
**Head SHA:** cbc8a75bef6fa1219f3f7f3964b94eced9f17bdb
**Status:** Merged

## Summary

Large PR (+1628/-720, 29 files, 7 commits) that:
1. Fixes webhook routes to use `phoenix_kit_api` pipeline and adds `admin_routes/0` + `admin_locale_routes/0` for detail/form pages
2. Migrates all list pages (billing profiles, currencies, invoices, orders, transactions, subscriptions) from raw `<table>` to `table_default` component with card/table toggle for mobile
3. Adds `table_row_menu` dropdown menus to all list pages replacing inline action buttons
4. Adds missing subscription schema fields (`plan_name`, `price`, `currency`, `provider`, `provider_subscription_id`, `last_renewal_error`, `belongs_to :user`)
5. Implements subscription edit form with status management (pause/resume/cancel/extend) and plan type change
6. Adds 5 backward-compatible compat modules delegating from old `PhoenixKit.Modules.Billing.*` namespace

## Issues Found

### 1. ~~[BUG - CRITICAL] Missing database migration for new subscription fields~~ — RETRACTED
**File:** `lib/phoenix_kit_billing/schemas/subscription.ex` lines 52-59, 79
**Confidence:** 0/100

**Retracted:** All columns (`plan_name`, `price`, `currency`, `provider`, `provider_subscription_id`, `last_renewal_error`) already exist in the database from PhoenixKit core V33 migration. The PR correctly added them to the Elixir schema to match the existing DB columns. No migration needed.

### 2. [BUG - CRITICAL] try/rescue silently swallowing all errors in list_payment_methods — FIXED
**File:** `lib/phoenix_kit_billing/web/subscription_form.ex` lines 70-73, 118-121, 238-261
**Confidence:** 95/100

Three `try/rescue` blocks catch all exceptions with `_ -> []`, hiding database errors, connection timeouts, etc. Root cause: `PaymentMethod` schema declared `field(:label)` but the DB column is `display_name` (from V33 migration). Fix: renamed schema field to `:display_name` and removed all try/rescue blocks.

### 3. [BUG - MEDIUM] Hardcoded "EUR" fallback in create_subscription — FIXED
**File:** `lib/phoenix_kit_billing.ex` line 2793
**Confidence:** 85/100

`currency: type.currency || "EUR"` silently defaults to EUR if subscription type has no currency. Fixed: now uses `Settings.get_setting("billing_default_currency", "EUR")` as fallback.

### 4. [BUG - MEDIUM] last_renewal_error not in changeset cast list — FIXED
**File:** `lib/phoenix_kit_billing/schemas/subscription.ex` lines 79, 120-141
**Confidence:** 95/100

Field exists in schema (line 79) but was absent from the `cast/3` list in `changeset/2`. Fixed: added `:last_renewal_error` to cast list.

### 5. [OBSERVATION] Compat LiveView modules are fragile — no handle_params delegation
**File:** `lib/phoenix_kit_billing/compat/user_billing_profile_form.ex`, `lib/phoenix_kit_billing/compat/user_billing_profiles.ex`
**Confidence:** 65/100

Verified: target modules currently don't implement `handle_params`, so not delegating it is correct today. However, the compat wrappers have no mechanism to catch drift — if anyone adds `handle_params` or `handle_info` to a target module, the compat wrapper will silently not delegate it, causing crashes. Consider using `defoverridable` or a macro that auto-delegates all `@impl` callbacks.

### 6. [BUG - MEDIUM] Inconsistent cancel_subscription behavior between list and edit — FIXED
**File:** `lib/phoenix_kit_billing/web/subscriptions.ex` line 124, `lib/phoenix_kit_billing/web/subscription_form.ex` line 298
**Confidence:** 90/100

Both list and edit actually call `cancel_subscription/1` which defaults to `immediately: false` (cancel at period end). The real issue was the edit form's flash message said "Subscription cancelled" (implying immediate) while the list said "will be cancelled at period end". Fixed: aligned flash message. Also added `data-confirm` dialogs to pause and cancel buttons.

### 7. [OBSERVATION] Duplicated helper functions across 3-4 modules — FIXED
**File:** `lib/phoenix_kit_billing/web/subscriptions.ex`, `subscription_form.ex`, `subscription_detail.ex`, `subscription_types.ex`
**Confidence:** 100/100

`status_badge_class/1` was identical in 3 modules. `format_interval/2` was identical in 4 modules. Fixed: extracted to `PhoenixKitBilling.Web.Components.SubscriptionHelpers` and imported in all 4 modules.

### 8. [OBSERVATION] admin_locale_routes/0 is a full copy-paste of admin_routes/0 — FIXED
**File:** `lib/phoenix_kit_billing/web/routes.ex` lines 24-95 vs 97-169
**Confidence:** 100/100

170 lines where `admin_locale_routes/0` was an exact duplicate with only `_locale` suffixes. Fixed: refactored into `build_admin_routes/1` private function accepting a suffix parameter.

### 9. [OBSERVATION] Duplicated Routes alias — FIXED
**File:** `lib/phoenix_kit_billing/web/subscription_form.ex` lines 18, 25
**Confidence:** 100/100

`alias PhoenixKit.Utils.Routes` appeared twice. Fixed: removed duplicate in subscription_form.ex, subscription_detail.ex, and subscription_types.ex. (Note: same pattern exists across other web modules but pre-dates this PR.)

### 10. [OBSERVATION] Edit save only handles subscription type change
**File:** `lib/phoenix_kit_billing/web/subscription_form.ex` lines 190-211
**Confidence:** 90/100

The `"save"` event for edit mode only checks if subscription type UUID changed. Payment method changes are ignored entirely. Save button says "Save Changes" but only handles one kind of change.

### 11. [OBSERVATION] extend_subscription hardcoded to 30 days
**File:** `lib/phoenix_kit_billing/web/subscription_form.ex` lines 314-328
**Confidence:** 85/100

Always extends by 30 days regardless of billing interval (could be weekly, yearly). Should extend by the subscription type's actual interval, or allow admin to specify days.

### 12. [OBSERVATION] No confirmation dialogs on destructive subscription actions
**File:** `lib/phoenix_kit_billing/web/subscription_form.html.heex` lines 198-243
**Confidence:** 90/100

Pause, resume, cancel, and extend buttons have no `data-confirm`. Cancel especially should require confirmation. Compare: currencies delete button correctly uses `data-confirm`.

### 13. [OBSERVATION] Status actions redirect away from edit form
**File:** `lib/phoenix_kit_billing/web/subscription_form.ex` lines 266-328
**Confidence:** 75/100

Every status action does `push_navigate` back to the detail page. Admin wanting to pause AND change plan must navigate back to edit after pausing. Consider reloading subscription in-place.

### 19. [OBSERVATION] update_subscription/2 accepts arbitrary attrs with no guard
**File:** `lib/phoenix_kit_billing.ex` line 2872
**Confidence:** 75/100

`update_subscription/2` passes any attrs map directly to `Subscription.changeset/2`. Since the changeset casts `status`, `user_uuid`, and other sensitive fields, an admin UI bug or misuse could corrupt subscription state. The existing status-change functions (`pause_subscription`, `resume_subscription`, etc.) use dedicated changesets with proper state transitions — `update_subscription/2` bypasses all of that. Consider restricting the castable fields or adding a separate `admin_changeset`.

### 14. [NITPICK] No tests for compat modules
**File:** `lib/phoenix_kit_billing/compat/*.ex`
**Confidence:** 85/100

Compat aliases are runtime delegation. If target module signatures change, these break silently.

### 15. [NITPICK] No tracking for compat module removal
**File:** `lib/phoenix_kit_billing/compat/*.ex`
**Confidence:** 70/100

All `@moduledoc` say "temporary" and "will be removed once core is migrated" but no tracking issue or TODO exists.

### 16. [NITPICK] Inconsistent row-click behavior across list pages
**Confidence:** 70/100

Billing profiles: click → edit. Invoices/subscriptions/orders: click → detail view. Currencies: no row-click. Pick one pattern.

### 17. [NITPICK] Long lines in templates
**Confidence:** 60/100

Several template lines exceed 120 chars in card action `navigate=` attributes.

### 18. [NITPICK] Currencies button priority swap
**Confidence:** 50/100

Import is now primary, Add Currency is secondary. May confuse existing users if Add Currency is used more frequently.

## What Was Done Well

- **Consistent migration to `table_default`** across all list pages with proper card/table toggle for mobile responsiveness
- **Good dropdown menus** — `table_row_menu` with contextual actions per entity type (view/edit/cancel for subscriptions, edit/enable/disable/delete for currencies)
- **Subscription edit form** is well-structured with clear status management UI (pause/resume/cancel buttons change based on current status)
- **Compat modules** are properly documented with clear `@moduledoc` explaining why they exist and when they should be removed
- **Plan snapshot pattern** (copying plan_name/price/currency to subscription at creation time) is the correct approach for billing — prevents price changes from retroactively affecting existing subscriptions
- **PubSub integration** in subscriptions list for real-time updates
- **Commit history** is clean — each commit is atomic and well-described

## Verdict

**Approved with fixes** — Original review incorrectly flagged issue #1 as a missing migration (columns already exist in core V33). The real critical issue was #2: a schema/DB mismatch (`label` vs `display_name` in PaymentMethod) causing try/rescue workarounds. Issues #2-4, #6-9 have been fixed in follow-up commits. Remaining observations (#5, #10-19) are low-to-medium severity and can be addressed incrementally.
