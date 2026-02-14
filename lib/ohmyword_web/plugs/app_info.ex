defmodule OhmywordWeb.Plugs.AppInfo do
  @moduledoc """
  Assigns app version and word count to the connection.
  """

  import Plug.Conn

  alias Ohmyword.Vocabulary
  alias Ohmyword.Search
  alias Ohmyword.Exercises

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
    |> assign(:search_term_count, Search.count_search_terms())
    |> assign(:sentence_count, Exercises.count_sentences())
  end
end
