defmodule PhoenixKitBilling.ApplicationIntegration do
  @moduledoc "Registers Billing module with PhoenixKit on startup."

  def register do
    # No application env registration needed — billing module is auto-discovered
    # via Code.ensure_loaded? in module_registry.ex
    :ok
  end
end
