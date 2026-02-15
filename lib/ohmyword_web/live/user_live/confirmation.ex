defmodule OhmywordWeb.UserLive.Confirmation do
  use OhmywordWeb, :live_view

  alias Ohmyword.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} max_width="auth">
      <div>
        <div class="text-center">
          <.header>Email confirmed!</.header>
          <p class="mt-4 text-sm">
            Your email has been successfully confirmed. You can now log in to your account.
          </p>
        </div>

        <div class="mt-6">
          <.button navigate={~p"/users/log-in"} variant="primary" block>
            Continue to Log in
          </.button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case Accounts.confirm_user(token) do
      {:ok, user} ->
        # If user is already confirmed, show success message
        # This handles the case where mount is called multiple times
        {:ok,
         socket
         |> assign(:user, user)
         |> put_flash(:info, "Email confirmed successfully!")}

      {:error, _reason} ->
        {:ok,
         socket
         |> put_flash(:error, "Confirmation link is invalid or it has expired.")
         |> push_navigate(to: ~p"/users/log-in")}
    end
  end
end
