defmodule PhoenixKit.Modules.Billing.Web.BillingProfileForm do
  @moduledoc """
  Billing profile form LiveView for creating and editing billing profiles.
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
  alias PhoenixKit.Modules.Billing.BillingProfile
  alias PhoenixKit.Utils.CountryData
  alias PhoenixKit.Settings
  alias PhoenixKit.Users.Auth
  alias PhoenixKit.Utils.Routes

  @impl true
  def mount(params, _session, socket) do
    if Billing.enabled?() do
      project_title = Settings.get_project_title()
      %{users: users} = Auth.list_users_paginated(limit: 100)
      countries = CountryData.countries_for_select()

      socket =
        socket
        |> assign(:project_title, project_title)
        |> assign(:users, users)
        |> assign(:countries, countries)
        |> assign(:profile_type, "individual")
        |> load_profile(params["id"])

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Billing module is not enabled")
       |> push_navigate(to: Routes.path("/admin"))}
    end
  end

  defp load_profile(socket, nil) do
    # New profile
    changeset = Billing.change_billing_profile(%BillingProfile{type: "individual"})

    socket
    |> assign(:page_title, "New Billing Profile")
    |> assign(:profile, nil)
    |> assign(:form, to_form(changeset))
    |> assign(:selected_user_uuid, nil)
    |> assign(:subdivision_label, "Region")
  end

  defp load_profile(socket, id) do
    case Billing.get_billing_profile(id) do
      nil ->
        socket
        |> put_flash(:error, "Billing profile not found")
        |> push_navigate(to: Routes.path("/admin/billing/profiles"))

      profile ->
        changeset = Billing.change_billing_profile(profile)

        socket
        |> assign(:page_title, "Edit Billing Profile")
        |> assign(:profile, profile)
        |> assign(:form, to_form(changeset))
        |> assign(:selected_user_uuid, profile.user_uuid)
        |> assign(:profile_type, profile.type)
        |> assign(:subdivision_label, CountryData.get_subdivision_label(profile.country))
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_user", %{"user_uuid" => user_uuid}, socket) do
    user_uuid = if user_uuid == "", do: nil, else: user_uuid
    {:noreply, assign(socket, :selected_user_uuid, user_uuid)}
  end

  @impl true
  def handle_event("change_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :profile_type, type)}
  end

  @impl true
  def handle_event("validate", %{"billing_profile" => params}, socket) do
    changeset =
      (socket.assigns.profile || %BillingProfile{})
      |> Billing.change_billing_profile(params)
      |> Map.put(:action, :validate)

    # Update subdivision label when country changes
    subdivision_label = CountryData.get_subdivision_label(params["country"])

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:subdivision_label, subdivision_label)}
  end

  @impl true
  def handle_event("save", %{"billing_profile" => params}, socket) do
    params =
      params
      |> Map.put("user_uuid", socket.assigns.selected_user_uuid)
      |> Map.put("type", socket.assigns.profile_type)

    save_profile(socket, params)
  end

  defp save_profile(socket, params) do
    result =
      if socket.assigns.profile do
        Billing.update_billing_profile(socket.assigns.profile, params)
      else
        case socket.assigns.selected_user_uuid do
          nil ->
            {:error, :no_user}

          user_uuid ->
            Billing.create_billing_profile(user_uuid, params)
        end
      end

    case result do
      {:ok, _profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Billing profile saved successfully")
         |> push_navigate(to: Routes.path("/admin/billing/profiles"))}

      {:error, :no_user} ->
        {:noreply, put_flash(socket, :error, "Please select a user")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
