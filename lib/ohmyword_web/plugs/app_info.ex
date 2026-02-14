defmodule OhmywordWeb.Plugs.AppInfo do
  @moduledoc """
  Assigns app version and word count to the connection.
  """

  import Plug.Conn

  alias Ohmyword.Vocabulary

  @app_version (case System.get_env("APP_VERSION") do
                  nil ->
                    case System.cmd("git", ["describe", "--tags", "--abbrev=0"],
                           stderr_to_stdout: true
                         ) do
                      {tag, 0} -> String.trim(tag)
                      _ -> "v" <> Mix.Project.config()[:version]
                    end

                  version ->
                    version
                end)

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> assign(:app_version, @app_version)
    |> assign(:word_count, Vocabulary.count_words())
  end
end
