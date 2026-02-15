defmodule OhmywordWeb.UserLive.ResendConfirmation do
  use OhmywordWeb, :live_view

  alias Ohmyword.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} max_width="auth">
      <div class="space-y-4">
        <div class="text-center">
          <.header>
            Resend confirmation instructions
            <:subtitle>
              Enter your email address and we'll send you a new confirmation link.
            </:subtitle>
          </.header>
        </div>

        <div :if={local_mail_adapter?()} class="alert alert-info">
          <.icon name="hero-information-circle" class="size-6 shrink-0" />
          <div>
            <p>You are running the local mail adapter.</p>
            <p>
              To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
            </p>
          </div>
        </div>

        <.form for={@form} id="resend_confirmation_form" phx-submit="send">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />

          <.button variant="primary" block phx-disable-with="Sending...">
            Send confirmation instructions
          </.button>
        </.form>

        <div class="text-center text-sm">
          <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
            Back to log in
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form)}
  end

  @impl true
  def handle_event("send", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      if user.confirmed_at do
        # User is already confirmed
        {:noreply,
         socket
         |> put_flash(:info, "This email is already confirmed. You can log in now.")
         |> push_navigate(to: ~p"/users/log-in")}
      else
        # Send confirmation instructions
        Accounts.deliver_user_confirmation_instructions(
          user,
          &url(~p"/users/confirm/#{&1}")
        )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "If your email is in our system, you will receive confirmation instructions shortly."
         )
         |> push_navigate(to: ~p"/users/log-in")}
      end
    else
      # Don't reveal whether the email exists (prevent user enumeration)
      {:noreply,
       socket
       |> put_flash(
         :info,
         "If your email is in our system, you will receive confirmation instructions shortly."
       )
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  defp local_mail_adapter? do
    Application.get_env(:ohmyword, Ohmyword.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
