defmodule PhoenixKit.Modules.Billing.Web.UserBillingProfileForm do
  @moduledoc """
  Temporary compatibility alias for PhoenixKitBilling.Web.UserBillingProfileForm.

  Provides backward-compatible LiveView for router integration in PhoenixKit core.
  Will be removed once core is migrated to `PhoenixKitBilling.Web.*`.
  """

  use Phoenix.LiveView

  @impl true
  defdelegate mount(params, session, socket),
    to: PhoenixKitBilling.Web.UserBillingProfileForm

  @impl true
  defdelegate render(assigns),
    to: PhoenixKitBilling.Web.UserBillingProfileForm

  @impl true
  defdelegate handle_event(event, params, socket),
    to: PhoenixKitBilling.Web.UserBillingProfileForm
end
