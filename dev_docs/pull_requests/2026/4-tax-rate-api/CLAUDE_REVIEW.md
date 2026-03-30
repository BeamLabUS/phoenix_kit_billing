# Code Review: PR #4 — Add public tax rate API functions for cross-module use

**Reviewed:** 2026-03-30
**Reviewer:** Claude (claude-opus-4-6)
**PR:** https://github.com/BeamLabEU/phoenix_kit_billing/pull/4
**Author:** Tim (timujinne)
**Head SHA:** 6a26d4a92d75ea40a13079a71f2f2fd35e12b9fc
**Status:** Merged

## Summary

Small PR (+38/-0, 2 files, 1 commit) that adds three public API functions to `PhoenixKitBilling` for cross-module tax rate consumption:
1. `tax_enabled?/0` — checks if tax is enabled in billing settings
2. `get_tax_rate/0` — returns the tax rate as a `Decimal` fraction (e.g., `0.20` for 20%)
3. `get_tax_rate_percent/0` — returns the tax rate as an integer percentage (e.g., `20`)

Also adds `defdelegate` entries in the compat module (`PhoenixKit.Modules.Billing`) for all three functions plus `get_config/0`.

## Issues Found

### 1. [BUG - MEDIUM] `get_tax_rate_percent/0` ignores `tax_enabled?` flag — FIXED
**File:** `lib/phoenix_kit_billing.ex` lines 336-343
**Confidence:** 95/100

`get_tax_rate/0` returns `Decimal.new("0")` when tax is disabled, but `get_tax_rate_percent/0` returns the stored rate regardless of the `tax_enabled?` flag. This inconsistency will surprise callers:

```elixir
# When tax is disabled but billing_default_tax_rate is "20":
PhoenixKitBilling.get_tax_rate()         #=> Decimal.new("0")   -- correct
PhoenixKitBilling.get_tax_rate_percent() #=> 20                  -- should be 0
```

**Suggested fix:** Wrap the body in `if tax_enabled?()` like `get_tax_rate/0` does, returning `0` when disabled.

### 2. [BUG - MEDIUM] `get_tax_rate/0` crashes on non-numeric settings values — FIXED
**File:** `lib/phoenix_kit_billing.ex` lines 324-331
**Confidence:** 90/100

`Decimal.new/1` raises `Decimal.Error` if the stored string is not a valid number (e.g., `"abc"`, `""`). In contrast, `get_tax_rate_percent/0` handles bad input gracefully via `Integer.parse/1` with a fallback to `0`.

Settings values come from user input in the admin UI, so invalid values are possible. A corrupted or empty setting would crash any caller of `get_tax_rate/0`.

**Suggested fix:** Use `Decimal.parse/1` with a fallback, or wrap in a rescue returning `Decimal.new("0")`.

### 3. [BUG - LOW] `get_config/0` duplicates logic that `tax_enabled?/0` now encapsulates — FIXED
**File:** `lib/phoenix_kit_billing.ex` line 298
**Confidence:** 100/100

`get_config/0` still inlines `Settings.get_setting_cached("billing_tax_enabled", "false") == "true"` rather than calling the new `tax_enabled?/0`. Now that a dedicated function exists, the config map should use it:

```elixir
tax_enabled: tax_enabled?(),
```

### 4. [OBSERVATION] Compat module adds `get_config/0` delegate outside PR scope
**File:** `lib/phoenix_kit_billing/compat/billing.ex` line 14
**Confidence:** 70/100

The compat module gained `defdelegate get_config(), to: PhoenixKitBilling` in this PR, but `get_config/0` is not a new function — it predates this PR. This delegate may have been missing and intentionally added here, or it may have been an accidental inclusion. Worth confirming.

### 5. [NITPICK] `get_tax_rate/0` doc mentions implementation details
**File:** `lib/phoenix_kit_billing.ex` lines 318-323
**Confidence:** 60/100

The `@doc` mentions BeamLabCountries and the billing settings UI. These are implementation details that could drift. A simpler doc like "Returns the default tax rate as a Decimal fraction (e.g., `0.20` for 20%). Returns `0` when tax is disabled." would be more stable as a public API contract.

## What Was Done Well

- **Clean, focused PR** — single responsibility, easy to review
- **Good function naming** — `tax_enabled?/0`, `get_tax_rate/0`, `get_tax_rate_percent/0` are clear and idiomatic Elixir
- **Correct Decimal usage** for monetary calculations (dividing by 100 to convert percentage to rate)
- **Compat module kept in sync** — all three new functions are properly delegated
- **Proper `@doc` annotations** on all functions

## Verdict

**Approved with fixes** — Issues #1-3 fixed in follow-up commit. Remaining observations (#4, #5) are low severity.
