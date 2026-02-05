defmodule Ohmyword.Linguistics.Dispatcher do
  @moduledoc """
  Routes words to the correct inflector module based on part of speech.

  The dispatcher maintains a registry of inflector modules and delegates
  to the first one that claims applicability for a given word.
  """

  alias Ohmyword.Vocabulary.Word

  @inflectors [
    Ohmyword.Linguistics.Nouns,
    Ohmyword.Linguistics.Verbs,
    Ohmyword.Linguistics.Adjectives,
    Ohmyword.Linguistics.Pronouns,
    Ohmyword.Linguistics.Numerals,
    Ohmyword.Linguistics.Invariables,
    # Stub inflector as fallback - catches anything not handled above
    Ohmyword.Linguistics.StubInflector
  ]

  @doc """
  Generates all inflected forms for a word.

  Routes to the appropriate inflector based on part of speech and returns
  the generated forms as a list of `{term, form_tag}` tuples.

  Returns an empty list if no inflector matches or the word is nil.

  ## Examples

      iex> Dispatcher.inflect(%Word{term: "pas", part_of_speech: :noun})
      [{"pas", "base"}]  # With stub inflector

      iex> Dispatcher.inflect(nil)
      []
  """
  @spec inflect(%Word{} | nil) :: [{String.t(), String.t()}]
  def inflect(nil), do: []

  def inflect(%Word{} = word) do
    case get_inflector(word) do
      nil ->
        []

      inflector ->
        inflector.generate_forms(word)
    end
  end

  @doc """
  Returns the inflector module that handles this word's part of speech.

  Returns `nil` if no inflector claims applicability.

  ## Examples

      iex> Dispatcher.get_inflector(%Word{part_of_speech: :noun})
      Ohmyword.Linguistics.StubInflector  # Until real Nouns module exists

      iex> Dispatcher.get_inflector(nil)
      nil
  """
  @spec get_inflector(%Word{} | nil) :: module() | nil
  def get_inflector(nil), do: nil

  def get_inflector(%Word{} = word) do
    Enum.find(@inflectors, fn inflector ->
      module_loaded?(inflector) && inflector.applicable?(word)
    end)
  end

  @doc """
  Returns the list of registered inflector modules.
  """
  @spec inflectors() :: [module()]
  def inflectors, do: @inflectors

  # Check if a module is loaded and available
  defp module_loaded?(module) do
    case Code.ensure_loaded(module) do
      {:module, _} -> true
      {:error, _} -> false
    end
  end
end
