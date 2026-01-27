defmodule BoilerWeb.IssueLive.New do
  use BoilerWeb, :live_view

  alias Boiler.Support
  alias Boiler.Support.Issue

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl">
        <.header>
          Submit Feedback or Report an Issue
          <:subtitle>
            Have feedback or experiencing an issue? Let us know and we'll look into it.
          </:subtitle>
        </.header>

        <.form for={@form} id="issue-form" phx-submit="save" phx-change="validate" class="mt-8">
          <div class="space-y-6">
            <.input
              field={@form[:content]}
              type="textarea"
              label="Description"
              placeholder="Please describe your feedback or issue in detail..."
              rows="8"
              required
              phx-mounted={JS.focus()}
            />

            <.button variant="primary" block phx-disable-with="Submitting...">
              Submit Feedback
            </.button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    changeset = Support.change_issue(%Issue{})

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"issue" => issue_params}, socket) do
    case Support.create_issue(socket.assigns.current_scope, issue_params) do
      {:ok, _issue} ->
        changeset = Support.change_issue(%Issue{})

        {:noreply,
         socket
         |> put_flash(:info, "Thank you for your feedback! We'll review it shortly.")
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"issue" => issue_params}, socket) do
    changeset =
      %Issue{}
      |> Support.change_issue(issue_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "issue")
    assign(socket, form: form)
  end
end
