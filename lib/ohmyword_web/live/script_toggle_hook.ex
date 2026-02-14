defmodule OhmywordWeb.ScriptToggleHook do
  @moduledoc """
  Shared on_mount hook that provides `:script_mode` assign and handles
  the `toggle_script` event for all LiveViews that need script switching.
  """

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [attach_hook: 4]

  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> assign(:script_mode, :latin)
      |> attach_hook(:toggle_script, :handle_event, &handle_toggle/3)

    {:cont, socket}
  end

  defp handle_toggle("toggle_script", _params, socket) do
    new_mode = if socket.assigns.script_mode == :latin, do: :cyrillic, else: :latin
    {:halt, Phoenix.Component.assign(socket, :script_mode, new_mode)}
  end

  defp handle_toggle(_event, _params, socket), do: {:cont, socket}
end
