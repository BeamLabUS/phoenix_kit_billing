defmodule PhoenixKit.Modules.Billing.Web.InvoicePrint do
  @moduledoc """
  Printable invoice view - displays invoice in a print-friendly format.

  This page is designed to be printed or saved as PDF directly from the browser.
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
  alias PhoenixKit.Utils.CountryData
  alias PhoenixKit.Modules.Billing.Transaction
  alias PhoenixKit.Settings
  alias PhoenixKit.Utils.Routes

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if Billing.enabled?() do
      case Billing.get_invoice(id, preload: [:user, :order, :transactions]) do
        nil ->
          {:ok,
           socket
           |> put_flash(:error, "Invoice not found")
           |> push_navigate(to: Routes.path("/admin/billing/invoices"))}

        invoice ->
          project_title = Settings.get_project_title()
          company_info = get_company_info()

          # Calculate refund info from transactions
          refund_info = calculate_refund_info(invoice.transactions)

          socket =
            socket
            |> assign(:page_title, "Invoice #{invoice.invoice_number}")
            |> assign(:project_title, project_title)
            |> assign(:invoice, invoice)
            |> assign(:company, company_info)
            |> assign(:refund_info, refund_info)

          {:ok, socket, layout: false}
      end
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

  defp get_company_info do
    %{
      name: Settings.get_setting("billing_company_name", ""),
      address: CountryData.format_company_address(),
      vat: Settings.get_setting("billing_company_vat", ""),
      bank_name: Settings.get_setting("billing_bank_name", ""),
      bank_iban: Settings.get_setting("billing_bank_iban", ""),
      bank_swift: Settings.get_setting("billing_bank_swift", "")
    }
  end

  defp calculate_refund_info(transactions) when is_list(transactions) do
    refund_txns =
      transactions
      |> Enum.filter(&Transaction.refund?/1)
      |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})

    if Enum.empty?(refund_txns) do
      nil
    else
      total_refunded =
        refund_txns
        |> Enum.map(& &1.amount)
        |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
        |> Decimal.abs()

      latest_refund = List.first(refund_txns)

      %{
        total: total_refunded,
        count: length(refund_txns),
        latest_date: latest_refund.inserted_at,
        transactions: refund_txns
      }
    end
  end

  defp calculate_refund_info(_), do: nil
end
