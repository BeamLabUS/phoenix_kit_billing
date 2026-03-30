defmodule PhoenixKitBilling.Web.Components.SubscriptionHelpers do
  @moduledoc """
  Shared helper functions for subscription-related LiveViews.

  Provides formatting and display utilities used across subscription list,
  detail, form, and subscription type pages.
  """

  @doc """
  Returns the daisyUI badge class for a subscription status.
  """
  def status_badge_class(status) do
    case status do
      "active" -> "badge-success"
      "trialing" -> "badge-info"
      "past_due" -> "badge-warning"
      "paused" -> "badge-neutral"
      "cancelled" -> "badge-error"
      _ -> "badge-ghost"
    end
  end

  @doc """
  Formats a billing interval into a human-readable string.
  """
  def format_interval(nil, _), do: "-"
  def format_interval(_, nil), do: "-"

  def format_interval(interval, interval_count) do
    case {interval, interval_count} do
      {"month", 1} -> "Monthly"
      {"month", n} -> "Every #{n} months"
      {"year", 1} -> "Yearly"
      {"year", n} -> "Every #{n} years"
      {"week", 1} -> "Weekly"
      {"week", n} -> "Every #{n} weeks"
      {"day", 1} -> "Daily"
      {"day", n} -> "Every #{n} days"
      _ -> "#{interval_count} #{interval}(s)"
    end
  end
end
