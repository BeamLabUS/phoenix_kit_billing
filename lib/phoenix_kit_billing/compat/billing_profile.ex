defmodule PhoenixKit.Modules.Billing.BillingProfile do
  @moduledoc """
  Temporary compatibility alias for PhoenixKitBilling.BillingProfile.

  Used by PhoenixKit core's auth.ex to reference the BillingProfile schema
  for query purposes. Will be removed once core is migrated.
  """

  defdelegate __schema__(arg), to: PhoenixKitBilling.BillingProfile
  defdelegate __struct__(), to: PhoenixKitBilling.BillingProfile
  defdelegate __struct__(kv), to: PhoenixKitBilling.BillingProfile
end
