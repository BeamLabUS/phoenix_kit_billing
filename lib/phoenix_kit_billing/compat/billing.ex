defmodule PhoenixKit.Modules.Billing do
  @moduledoc """
  Temporary compatibility alias for PhoenixKitBilling.

  This module exists to maintain backward compatibility with PhoenixKit core
  which still references the old `PhoenixKit.Modules.Billing.*` namespace.
  Will be removed once core is fully migrated to `PhoenixKitBilling.*`.
  """

  defdelegate enabled?(), to: PhoenixKitBilling
  defdelegate tax_enabled?(), to: PhoenixKitBilling
  defdelegate get_tax_rate(), to: PhoenixKitBilling
  defdelegate get_tax_rate_percent(), to: PhoenixKitBilling
  defdelegate get_config(), to: PhoenixKitBilling
  defdelegate list_billing_profiles_with_count(opts), to: PhoenixKitBilling
  defdelegate get_invoice(id, opts), to: PhoenixKitBilling
  defdelegate list_invoice_transactions(uuid), to: PhoenixKitBilling
  defdelegate create_order(user, attrs), to: PhoenixKitBilling
  defdelegate available_payment_methods(), to: PhoenixKitBilling
end
