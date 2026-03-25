defmodule PhoenixKit.Modules.Billing.Web.SubscriptionTypes do
  @moduledoc """
  Subscription types list LiveView for the billing module.

  Displays all subscription types with management actions.
  """

  use Phoenix.LiveView
  use Gettext, backend: PhoenixKitWeb.Gettext
  import PhoenixKitWeb.Components.Core.AdminPageHeader
  import PhoenixKitWeb.Components.Core.UserInfo
  import PhoenixKitWeb.Components.Core.ThemeSwitcher
  import PhoenixKitWeb.Components.Core.StatCard
  import PhoenixKitWeb.Components.Core.EmailStatusBadge
  import PhoenixKitWeb.Components.Core.EventTimelineItem
  import PhoenixKitWeb.Components.Core.FileDisplay
  import PhoenixKitWeb.Components.Core.NumberFormatter
  import PhoenixKitWeb.Components.Core.TableDefault
  import PhoenixKitWeb.Components.Core.TableRowMenu
  import PhoenixKitWeb.Components.Core.Accordion
  import PhoenixKitWeb.Components.Core.Modal
  import PhoenixKitWeb.Components.Core.PkLink
  import Phoenix.HTML
  import Phoenix.HTML.Form
  import Phoenix.LiveView.Helpers
  alias PhoenixKit.Utils.Routes
  import PhoenixKitWeb.LayoutHelpers, only: [dashboard_assigns: 1]
  import PhoenixKitWeb.Components.Core.Button
  import PhoenixKitWeb.Components.Core.Flash
  import PhoenixKitWeb.Components.Core.Header
  import PhoenixKitWeb.Components.Core.Icon
  import PhoenixKitWeb.Components.Core.FormFieldLabel
  import PhoenixKitWeb.Components.Core.FormFieldError
  import PhoenixKitWeb.Components.Core.Input
  import PhoenixKitWeb.Components.Core.Textarea
  import PhoenixKitWeb.Components.Core.Select
  import PhoenixKitWeb.Components.Core.Checkbox
  import PhoenixKitWeb.Components.Core.SimpleForm
  import PhoenixKitWeb.Components.Core.Badge
  import PhoenixKitWeb.Components.Core.Pagination
  import PhoenixKitWeb.Components.Core.TimeDisplay
  import PhoenixKit.Modules.Billing.Web.Components.CurrencyDisplay
  import PhoenixKit.Modules.Billing.Web.Components.InvoiceStatusBadge
  import PhoenixKit.Modules.Billing.Web.Components.TransactionTypeBadge
  import PhoenixKit.Modules.Billing.Web.Components.OrderStatusBadge

  alias PhoenixKit.Modules.Billing
  alias PhoenixKit.Settings
  alias PhoenixKit.Utils.Routes

  @impl true
  def mount(_params, _session, socket) do
    if Billing.enabled?() do
      project_title = Settings.get_project_title()

      socket =
        socket
        |> assign(:page_title, "Subscription Types")
        |> assign(:project_title, project_title)
        |> load_subscription_types()

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Billing module is not enabled")
       |> push_navigate(to: Routes.path("/admin"))}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp load_subscription_types(socket) do
    types = Billing.list_subscription_types(active_only: false)
    assign(socket, :subscription_types, types)
  end

  @impl true
  def handle_event("toggle_active", %{"uuid" => uuid}, socket) do
    type = Enum.find(socket.assigns.subscription_types, &(&1.uuid == uuid))

    if type do
      case Billing.update_subscription_type(type, %{active: !type.active}) do
        {:ok, _type} ->
          {:noreply,
           socket
           |> load_subscription_types()
           |> put_flash(
             :info,
             if(type.active,
               do: "Subscription type deactivated",
               else: "Subscription type activated"
             )
           )}

        {:error, reason} ->
          {:noreply,
           put_flash(socket, :error, "Failed to update subscription type: #{inspect(reason)}")}
      end
    else
      {:noreply, put_flash(socket, :error, "Subscription type not found")}
    end
  end

  @impl true
  def handle_event("delete_subscription_type", %{"uuid" => uuid}, socket) do
    type = Enum.find(socket.assigns.subscription_types, &(&1.uuid == uuid))

    if type do
      case Billing.delete_subscription_type(type) do
        {:ok, _type} ->
          {:noreply,
           socket
           |> load_subscription_types()
           |> put_flash(:info, "Subscription type deleted")}

        {:error, :has_subscriptions} ->
          {:noreply,
           put_flash(
             socket,
             :error,
             "Cannot delete subscription type with active subscriptions. Deactivate it instead."
           )}

        {:error, reason} ->
          {:noreply,
           put_flash(socket, :error, "Failed to delete subscription type: #{inspect(reason)}")}
      end
    else
      {:noreply, put_flash(socket, :error, "Subscription type not found")}
    end
  end

  # Helper functions for template

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
