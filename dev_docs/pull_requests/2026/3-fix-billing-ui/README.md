# PR #3 — Fix billing UI, routes, schema, and add edit mode

**Author:** Tim (timujinne)
**Merged:** 2026-03-30
**PR:** https://github.com/BeamLabEU/phoenix_kit_billing/pull/3
**Stats:** +1628 / -720 across 29 files, 7 commits

## What

- Fix webhook routes to use `phoenix_kit_api` pipeline
- Add `admin_routes/0` and `admin_locale_routes/0` for detail/form pages (fixing 404s)
- Migrate all list pages to `table_default` component with card/table toggle
- Add `table_row_menu` dropdown menus to all list pages
- Add missing subscription schema fields (plan snapshot, provider, belongs_to user)
- Implement subscription edit form with status management and plan change
- Add backward-compatible compat aliases for old namespace

## Why

- Webhook routes were broken (wrong pipeline)
- Detail/form pages returned 404 (routes not registered)
- List pages needed responsive mobile UI (card view toggle)
- Subscription schema was missing fields needed for real usage
- Admin had no way to edit existing subscriptions
- PhoenixKit core still references old `PhoenixKit.Modules.Billing.*` namespace

## Files Changed

| Area | Files | Description |
|------|-------|-------------|
| Routes | `web/routes.ex` | Webhook pipeline fix, admin_routes/admin_locale_routes |
| Schema | `schemas/subscription.ex` | New fields: plan_name, price, currency, provider, user |
| Context | `phoenix_kit_billing.ex` | update_subscription/2, plan snapshot on create |
| UI Lists | `billing_profiles.html.heex`, `currencies.html.heex`, `invoices.html.heex`, `orders.html.heex`, `transactions.html.heex`, `subscriptions.html.heex` | table_default migration + table_row_menu |
| UI Detail | `order_detail.html.heex`, `subscription_detail.html.heex`, `subscription_types.html.heex` | table_default / dropdown menu |
| Subscription Form | `subscription_form.ex`, `subscription_form.html.heex` | Edit mode with status management |
| Compat | `compat/billing.ex`, `compat/billing_profile.ex`, `compat/iban_data.ex`, `compat/user_billing_profile_form.ex`, `compat/user_billing_profiles.ex` | Namespace delegation |
