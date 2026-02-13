defmodule OhmywordWeb.Plugs.AppInfo do
  @moduledoc """
  Assigns app version and word count to the connection.
  """

  import Plug.Conn

  alias Ohmyword.Vocabulary

  def init(opts), do: opts

  def call(conn, _opts) do
    version = Application.spec(:ohmyword, :vsn) |> to_string()

    conn
    |> assign(:app_version, "v#{version}")
    |> assign(:word_count, Vocabulary.count_words())
  end
end
