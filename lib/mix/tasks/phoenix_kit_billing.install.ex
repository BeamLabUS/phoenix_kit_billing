defmodule Mix.Tasks.PhoenixKitBilling.Install do
  @moduledoc """
  Installs PhoenixKit Billing module into parent application.

  ## Usage

      mix phoenix_kit_billing.install
  """

  use Mix.Task

  @shortdoc "Install PhoenixKit Billing module"

  @impl Mix.Task
  def run(_argv) do
    Mix.shell().info("Installing PhoenixKit Billing...")

    Mix.shell().info("""

    PhoenixKit Billing installed successfully!

    Next steps:
    1. Add {:phoenix_kit_billing, "~> 0.1"} to your mix.exs deps
    2. Run `mix deps.get`
    3. Add Oban queue to config/config.exs:
       - billing: 10
    4. Add Oban cron job to config/config.exs:
       {"0 6 * * *", PhoenixKit.Modules.Billing.Workers.SubscriptionRenewalWorker}
    5. Add PhoenixKit.Modules.Billing.Supervisor to your application supervision tree
    6. Configure payment provider API keys in Admin → Settings → Billing → Providers
    7. Run `mix phoenix_kit.update` to apply billing migrations
    8. Enable the Billing module in Admin → Modules
    """)
  end
end
