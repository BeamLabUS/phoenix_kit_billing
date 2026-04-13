defmodule Framework.Billing.Widgets do
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

  def widgets do
    [
      %{
        id: "billing_active_subscriptions",
        title: "Active Subscriptions",
        value: fn _user -> get_active_subscriptions() end,
        roles: [:admin],
        description: "Number of active customer subscriptions"
      },
      %{
        id: "billing_mrr",
        title: "Monthly Recurring Revenue",
        value: fn user -> get_mrr(user) end,
        roles: [:admin],
        description: "Predicted monthly revenue from active subscriptions"
      },
      %{
        id: "billing_failed_payments",
        title: "Failed Payments",
        value: fn _user -> get_failed_payments() end,
        roles: [:admin],
        description: "Payment attempts that failed in the last 30 days"
      },
      %{
        id: "billing_churn_rate",
        title: "Churn Rate",
        value: fn _user -> get_churn_rate() end,
        roles: [:admin],
        description: "Percentage of subscriptions cancelled this month"
      }
    ]
  end

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
          RepoHelper.repo().aggregate(
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
  defp get_mrr(user) do
    unit = Cldr.Currency.symbol(PhoenixKitBilling.get_default_currency())

    try do
      case Code.ensure_loaded(PhoenixKit.Billing) do
        {:module, _} ->
          case RepoHelper.repo().aggregate(
                 from(s in PhoenixKit.Billing.Subscription,
                   where: s.status == :active,
                   select: s.amount_cents
                 ),
                 :sum,
                 :amount_cents
               ) do
            nil ->
              "$0.00"

            total_cents ->
              # Convert cents to dollars and format
              total_dollars = total_cents / 100.0
              Number.Currency.number_to_currency(total_dollars, unit: unit)
          end

        {:error, _} ->
          Number.Currency.number_to_currency(0, unit: unit)
      end
    rescue
      e ->
        Logger.warning("Error calculating MRR: #{inspect(e)}")
        Number.Currency.number_to_currency(0, unit: unit)
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

          RepoHelper.repo().aggregate(
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
          month_end = end_of_month(now)

          # Count subscriptions at start of month
          # Avoid division by zero
          subscriptions_at_start =
            RepoHelper.repo().aggregate(
              from(s in PhoenixKit.Billing.Subscription,
                where: s.created_at <= ^month_start or s.status == :active
              ),
              :count,
              :id
            ) || 1

          # Count subscriptions cancelled this month
          cancelled_this_month =
            RepoHelper.repo().aggregate(
              from(s in PhoenixKit.Billing.Subscription,
                where:
                  s.status == :cancelled and
                    s.cancelled_at >= ^month_start and
                    s.cancelled_at <= ^month_end
              ),
              :count,
              :id
            ) || 0

          # Calculate percentage
          churn_percentage = cancelled_this_month / subscriptions_at_start * 100
          Number.Percentage.number_to_percentage(churn_percentage)

        {:error, _} ->
          Number.Percentage.number_to_percentage(0)
      end
    rescue
      e ->
        Logger.warning("Error calculating churn rate: #{inspect(e)}")
        Number.Percentage.number_to_percentage(0)
    end
  end

  # ============================================================================
  # Date Helper Functions
  # ============================================================================

  defp beginning_of_month(%DateTime{year: year, month: month}) do
    DateTime.new!(Date.new!(year, month, 1), ~T[00:00:00])
  end

  defp end_of_month(%DateTime{year: year, month: month}) do
    last_day =
      case month do
        2 ->
          if Date.leap_year?(Date.new!(year, month, 1)), do: 29, else: 28

        month when month in [4, 6, 9, 11] ->
          30

        _ ->
          31
      end

    DateTime.new!(Date.new!(year, month, last_day), ~T[23:59:59])
  end
end
