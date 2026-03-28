defmodule PhoenixKit.Modules.Billing.Supervisor do
  @moduledoc """
  Supervisor for PhoenixKit Billing system.

  Manages billing background processes. Add to your application's supervision tree:

      # In lib/your_app/application.ex
      children = [
        PhoenixKit.Modules.Billing.Supervisor
      ]
  """

  use Supervisor

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  def init(_opts) do
    PhoenixKit.Modules.Billing.ApplicationIntegration.register()
    Supervisor.init([], strategy: :one_for_one)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: :infinity
    }
  end
end
