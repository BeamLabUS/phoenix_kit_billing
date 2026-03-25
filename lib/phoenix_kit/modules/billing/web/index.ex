defmodule PhoenixKit.Modules.Billing.Web.Index do
  @moduledoc """
  Billing module dashboard LiveView.

  Provides an overview of billing activity including:
  - Key metrics (orders, invoices, revenue)
  - Recent orders and invoices
  - Quick actions
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
        |> assign(:page_title, "Billing Dashboard")
        |> assign(:project_title, project_title)
        |> load_dashboard_data()

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

  defp load_dashboard_data(socket) do
    stats = Billing.get_dashboard_stats()
    recent_orders = Billing.list_orders(limit: 5, sort_by: :inserted_at, sort_order: :desc)
    recent_invoices = Billing.list_invoices(limit: 5, sort_by: :inserted_at, sort_order: :desc)
    currencies = Billing.list_currencies(enabled: true)

    socket
    |> assign(:stats, stats)
    |> assign(:recent_orders, recent_orders)
    |> assign(:recent_invoices, recent_invoices)
    |> assign(:currencies, currencies)
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, load_dashboard_data(socket)}
  end

  @impl true
  def handle_event("view_order", %{"uuid" => uuid}, socket) do
    {:noreply, push_navigate(socket, to: Routes.path("/admin/billing/orders/#{uuid}"))}
  end

  @impl true
  def handle_event("view_invoice", %{"uuid" => uuid}, socket) do
    {:noreply, push_navigate(socket, to: Routes.path("/admin/billing/invoices/#{uuid}"))}
  end
end
