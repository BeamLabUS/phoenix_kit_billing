# PR #5 Review — Fix CountryData alias, migrate company info to Organization

**Reviewer:** Pincer 🦀
**Date:** 2026-04-06
**Verdict:** Approve with Minor Observations

---

## Summary

Migrates company/bank info retrieval from `CountryData.get_company_info()` / `CountryData.get_bank_details()` to `Organization.get_company_info()` / `Organization.get_bank_details()`, consolidating around the Organization settings LiveView module. Also adds `version/0` callback, `module_stats/0`, updated permission metadata, and massively expands the compat module delegates.

---

## What Works Well

1. **Consistent data source** — All print views (invoice, receipt, credit note, payment confirmation) now read from the same Organization source, no more scattered Settings.get_setting calls
2. **`format_company_address/1` made public** — Moved from `CountryData.format_company_address()` to `PhoenixKitBilling.format_company_address(company_info)`, accepts the map as argument — better testability
3. **Compat module fully expanded** — Every public function now delegated, not just a handful. Will make the eventual namespace migration smoother.
4. **`module_stats/0`** — Nice addition, shows orders/invoices/currencies on admin module card

---

## Issues and Observations

### 1. DESIGN — MEDIUM: `get_company_info` duplicated across 4 print views
Each of the 4 print LiveViews (invoice_print, receipt_print, credit_note_print, payment_confirmation_print) has an identical `get_company_info/0` private function. Should be extracted to a shared helper or use the billing module's `get_company_details/0` directly.

### 2. DESIGN — LOW: `module_stats/0` is not a callback
`module_stats/0` is a regular function, not a `@impl PhoenixKit.Module` callback. Fine for now, but inconsistent with the rest of the module API.

### 3. OBSERVATION: `elixirc_options: [ignore_module_conflict: true]`
Added to mix.exs for compat module. Correct approach, already used in other modules.

### 4. OBSERVATION: Compat module is 160+ lines of pure delegates
That's a lot of boilerplate. Necessary evil until core migration is complete, but worth tracking for removal.

---

## Post-Review Status

All issues are minor / design observations. No blockers.
