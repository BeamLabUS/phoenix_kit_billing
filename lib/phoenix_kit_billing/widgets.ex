defmodule PhoenixKitBilling.Widgets do
  require Logger
  import Ecto.Query


  @moduledoc """
  Dashboard Widgets for Billing & Subscription functionality from PhoenixKit.Billing.

  Exposes key metrics:
  - Active subscriptions
  - Monthly Recurring Revenue (MRR)
  - Failed payment attempts
  - Churn rate
  """

  @doc """
  Check if the billing module is enabled and available.
  """
  def enabled?(_user) do
    case Code.ensure_loaded(PhoenixKit.Billing) do
      {:module, _} -> true
      {:error, _} -> false
    end
  end

  # ============================================================================
  # Helper Functions - Fetch Data from PhoenixKit.Billing
  # ============================================================================

  @doc """
  Count the number of active subscriptions.
  """
  defp get_active_subscriptions do
    try do
      case Code.ensure_loaded(PhoenixKit.Billing) do
        {:module, _} ->
          repo().aggregate(
            from(s in PhoenixKit.Billing.Subscription,
              where: s.status == :active
            ),
            :count,
            :id
          ) || 0

        {:error, _} ->
          0
      end
    rescue
      e ->
        Logger.warning("Error getting active subscriptions: #{inspect(e)}")
        0
    end
  end

  @doc """
  Calculate Monthly Recurring Revenue (MRR).
  Sums up the monthly amount from all active subscriptions.
  """
  defp get_mrr() do
    try do
      case Code.ensure_loaded(PhoenixKit.Billing) do
        {:module, _} ->
          case repo().aggregate(
                 from(s in PhoenixKit.Billing.Subscription,
                   where: s.status == :active
                 ),
                 :sum,
                 :amount_cents
               ) do
            nil ->
              "$0.00"

            total_cents ->
              # Convert cents to dollars and format
              total_dollars = total_cents / 100.0
              total_dollars
          end

        {:error, _} ->
          0
      end
    rescue
      e ->
        Logger.warning("Error calculating MRR: #{inspect(e)}")
        0
    end
  end

  @doc """
  Count failed payment attempts in the last 30 days.
  """
  defp get_failed_payments do
    try do
      case Code.ensure_loaded(PhoenixKit.Billing) do
        {:module, _} ->
          thirty_days_ago = DateTime.add(DateTime.utc_now(), -30, :day)

          repo().aggregate(
            from(p in PhoenixKit.Billing.Payment,
              where: p.status == :failed and p.inserted_at >= ^thirty_days_ago
            ),
            :count,
            :id
          ) || 0

        {:error, _} ->
          0
      end
    rescue
      e ->
        Logger.warning("Error getting failed payments: #{inspect(e)}")
        0
    end
  end

  @doc """
  Calculate the churn rate (percentage of subscriptions cancelled).
  """
  defp get_churn_rate do
    try do
      case Code.ensure_loaded(PhoenixKit.Billing) do
        {:module, _} ->
          # Get current month boundaries
          now = DateTime.utc_now()
          month_start = beginning_of_month(now)
          month_end = beginning_of_next_month()

          # Count subscriptions at start of month
          # Avoid division by zero
          subscriptions_at_start =
            repo().aggregate(
              from(s in PhoenixKit.Billing.Subscription,
                where: s.current_period_start <= ^month_start or s.status == :active
              ),
              :count,
              :id
            ) || 1

          # Count subscriptions cancelled this month
          cancelled_this_month =
            repo().aggregate(
              from(s in PhoenixKit.Billing.Subscription,
                where:
                  s.status == :cancelled and
                    s.cancelled_at >= ^month_start and
                    s.cancelled_at < ^month_end
              ),
              :count,
              :id
            ) || 0

          # Calculate percentage
          churn_percentage = cancelled_this_month / subscriptions_at_start * 100
          churn_percentage

        {:error, _} ->
          0
      end
    rescue
      e ->
        Logger.warning("Error calculating churn rate: #{inspect(e)}")
        0
    end
  end

  # ============================================================================
  # Date Helper Functions
  # ============================================================================

  defp beginning_of_month(%DateTime{year: year, month: month}) do
    DateTime.new!(Date.new!(year, month, 1), ~T[00:00:00])
  end

  def beginning_of_next_month do
    now = DateTime.utc_now()
    date = DateTime.to_date(now)

    first_of_this_month = %Date{year: date.year, month: date.month, day: 1}
    first_of_next_month = Date.add(first_of_this_month, Date.days_in_month(date))

    DateTime.new!(first_of_next_month, ~T[00:00:00], "Etc/UTC")
  end

  def widgets() do
    [
      %{
        uuid: "019da50b-7746-7d53-a6d3-5bda0564dc3a",
        name: "Active Subscriptions",
        value: fn _ -> get_active_subscriptions() end,
        description: "Number of active customer subscriptions",
        enabled: true
      },
      %{
        uuid: "019db2ff-932a-7b52-a284-6efc15012c5d",
        name: "Monthly Recurring Revenue",
        value: fn _ -> get_mrr() end,
        description: "Predicted monthly revenue from active subscriptions",
        enabled: true
      },
      %{
        uuid: "019da50b-7746-7d53-a6d3-5bda0564dc3f",
        name: "Failed Payments",
        value: fn _ -> get_failed_payments() end,
        description: "Payment attempts that failed in the last 30 days",
        enabled: true
      },
      %{
        uuid: "019da50b-7746-7d53-a6d3-5bda0564dc3d",
        name: "Churn Rate",
        value: fn _ -> get_churn_rate() end,
        description: "Percentage of subscriptions cancelled this month",
        enabled: true
      }
    ]
  end

  defp repo, do: PhoenixKit.RepoHelper.repo()
end
