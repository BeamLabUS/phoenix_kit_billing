# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.1] - 2026-03-29

### Changed

- Restructured to flat `lib/phoenix_kit_billing/` layout with `PhoenixKitBilling` namespace
- Added `.gitignore` for clean repository tracking

### Fixed

- Sorted alias declarations alphabetically across 33 files to satisfy Credo strict mode

## [0.1.0] - 2026-03-28

### Added

- Initial billing module with PhoenixKit.Module behaviour
- Multi-currency support with exchange rates
- Billing profiles for individuals and companies
- Order management with line items and status tracking
- Invoice generation with receipt functionality (draft → sent → paid/overdue/void)
- Transaction tracking with refunds and credit notes
- Subscription management with renewal cycles and dunning
- Subscription type definitions (pricing, intervals, trial periods)
- Payment provider architecture (Stripe, PayPal, Razorpay)
- Internal subscription control (subscriptions managed in DB, not by providers)
- Webhook processing for all supported providers
- Oban workers for subscription renewals and dunning
- PubSub events for real-time LiveView updates
- Admin LiveViews: dashboard, orders, invoices, transactions, subscriptions, billing profiles, currencies, settings
- User dashboard: My Orders, Billing Profiles
- Print views: invoice, receipt, credit note, payment confirmation
- Centralized path helpers via Paths module
- Install mix task
