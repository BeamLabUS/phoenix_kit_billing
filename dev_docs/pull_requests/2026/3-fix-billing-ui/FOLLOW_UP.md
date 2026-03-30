# Follow-Up: PR #3 — Post-merge issues and action items

**Created:** 2026-03-30
**Updated:** 2026-03-30
**Source:** [CLAUDE_REVIEW.md](CLAUDE_REVIEW.md)

## Fixed (in follow-up commits)

- [x] **PaymentMethod schema field mismatch** — `label` → `display_name` to match DB column from V33 migration
- [x] **Removed all try/rescue blocks** in subscription_form.ex (were masking the schema mismatch)
- [x] **Hardcoded EUR fallback** → now uses `Settings.get_setting("billing_default_currency", "EUR")`
- [x] **Added `last_renewal_error` to subscription changeset cast** — was in schema but not castable
- [x] **Fixed cancel flash message** — edit form now says "will be cancelled at period end" (matching list view)
- [x] **Added `data-confirm` dialogs** to pause and cancel buttons in subscription edit form
- [x] **Extracted shared helpers** — `status_badge_class/1` and `format_interval/2` into `SubscriptionHelpers` module
- [x] **DRYed up routes.ex** — `admin_routes/0` and `admin_locale_routes/0` now share `build_admin_routes/1`
- [x] **Removed duplicate `alias Routes`** in subscription_form.ex, subscription_detail.ex, subscription_types.ex

## Remaining items

- [ ] **Edit save only handles plan type change** — Payment method changes ignored in edit mode. See review issue #10.
- [ ] **Extend always 30 days** — Should use subscription type's interval or allow admin input. See review issue #11.
- [ ] **Status actions redirect away from edit form** — Consider reloading subscription in-place. See review issue #13.
- [ ] **No tests for compat modules** — If target module signatures change, these break silently. See review issue #14.
- [ ] **Create tracking issue for compat module removal** — Marked "temporary" but no ticket exists. See review issue #15.
- [ ] **Inconsistent row-click behavior** — Profiles → edit, others → detail view. See review issue #16.
- [ ] **Guard `update_subscription/2` attrs** — Accepts arbitrary attrs including sensitive fields. See review issue #19.

## Corrections to original review

- **Issue #1 was retracted** — Subscription columns (`plan_name`, `price`, `currency`, etc.) already exist in DB from PhoenixKit core V33 migration. The PR correctly added them to the Elixir schema.
- **Issue #2 root cause corrected** — Not a missing migration for `label` column. The PaymentMethod schema declared `field(:label)` but the DB column is `display_name`.
- **Issue #6 re-evaluated** — Both list and edit call `cancel_subscription/1` with same defaults. The inconsistency was only in the flash message text.
