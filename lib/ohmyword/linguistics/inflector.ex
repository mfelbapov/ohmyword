defmodule Ohmyword.Linguistics.Inflector do
  @moduledoc """
  Behaviour definition for part-of-speech-specific inflectors.

  All POS-specific inflectors (Nouns, Verbs, Adjectives, etc.) must implement
  this behaviour to integrate with the Dispatcher and CacheManager.
  """

  alias Ohmyword.Vocabulary.Word

  @doc """
  Returns `true` if this inflector handles the given word's part of speech.

  ## Examples

      iex> Nouns.applicable?(%Word{part_of_speech: :noun})
      true

      iex> Nouns.applicable?(%Word{part_of_speech: :verb})
      false
  """
  @callback applicable?(word :: %Word{}) :: boolean()

  @doc """
  Generates all inflected forms for a given word.

  Returns a list of `{inflected_form, grammatical_tag}` tuples.
  The `term` should be lowercase Latin script.

  ## Examples

      iex> Nouns.generate_forms(%Word{term: "pas", part_of_speech: :noun})
      [
        {"pas", "nom_sg"},
        {"psa", "gen_sg"},
        {"psu", "dat_sg"},
        ...
      ]
  """
  @callback generate_forms(word :: %Word{}) :: [{term :: String.t(), form_tag :: String.t()}]
end
