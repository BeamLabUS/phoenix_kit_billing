defmodule PhoenixKit.Modules.Billing.IbanData do
  @moduledoc """
  Temporary compatibility alias for PhoenixKitBilling.IbanData.

  Used by PhoenixKit core's country_data.ex for IBAN validation.
  Will be removed once core is migrated to `PhoenixKitBilling.IbanData`.
  """

  defdelegate get_iban_length(country_code), to: PhoenixKitBilling.IbanData
  defdelegate sepa_member?(country_code), to: PhoenixKitBilling.IbanData
  defdelegate country_uses_iban?(country_code), to: PhoenixKitBilling.IbanData
  defdelegate get_spec(country_code), to: PhoenixKitBilling.IbanData
  defdelegate all_specs(), to: PhoenixKitBilling.IbanData
end
