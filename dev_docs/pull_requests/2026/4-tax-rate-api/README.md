# PR #4 — Add public tax rate API functions for cross-module use

**Author:** Tim (timujinne)
**Merged:** 2026-03-30
**PR:** https://github.com/BeamLabEU/phoenix_kit_billing/pull/4

## What

Adds three public API functions to `PhoenixKitBilling` so other modules (e.g., ecommerce) can query tax configuration without directly accessing billing settings:

- `tax_enabled?/0` — boolean check
- `get_tax_rate/0` — Decimal rate (e.g., `0.20`)
- `get_tax_rate_percent/0` — integer percentage (e.g., `20`)

## Why

The ecommerce module needs tax rate information from billing. Rather than duplicating settings lookups, billing becomes the single source of truth for tax configuration.

## Files Changed

| File | Changes |
|------|---------|
| `lib/phoenix_kit_billing.ex` | +34 — three new public functions |
| `lib/phoenix_kit_billing/compat/billing.ex` | +4 — delegate entries for new functions + `get_config/0` |
