defmodule Ohmyword.Linguistics.StubInflector do
  @moduledoc """
  A stub inflector used for testing the architecture.

  This inflector acts as a catch-all, returning just the base form
  of any word. It will be superseded by real inflectors as they are
  implemented.
  """

  @behaviour Ohmyword.Linguistics.Inflector

  alias Ohmyword.Vocabulary.Word

  @doc """
  Returns true for any word - this is a catch-all stub.
  """
  @impl true
  def applicable?(%Word{}), do: true
  def applicable?(_), do: false

  @doc """
  Returns just the root form with tag "base".

  ## Examples

      iex> StubInflector.generate_forms(%Word{term: "pas"})
      [{"pas", "base"}]

      iex> StubInflector.generate_forms(%Word{term: "Kuća"})
      [{"kuća", "base"}]
  """
  @impl true
  def generate_forms(%Word{term: term}) do
    [{String.downcase(term), "base"}]
  end
end
