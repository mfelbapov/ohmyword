defmodule Ohmyword.Linguistics.Invariables do
  @moduledoc """
  Inflector for invariable parts of speech: adverbs, prepositions, conjunctions,
  interjections, and particles.

  These words do not decline or conjugate (with the exception of some adverbs
  that have comparative and superlative forms).
  """

  @behaviour Ohmyword.Linguistics.Inflector

  @invariable_pos [:adverb, :preposition, :conjunction, :interjection, :particle]

  @impl true
  def applicable?(%{part_of_speech: pos}), do: pos in @invariable_pos
  def applicable?(_), do: false

  @impl true
  def generate_forms(%{term: nil}), do: []
  def generate_forms(%{term: ""}), do: []

  def generate_forms(%{part_of_speech: :adverb} = word) do
    base = [{String.downcase(word.term), "base"}]

    comparative =
      case get_in(word.grammar_metadata || %{}, ["comparative"]) do
        nil -> []
        "" -> []
        comp -> [{String.downcase(comp), "comp"}]
      end

    superlative =
      case get_in(word.grammar_metadata || %{}, ["superlative"]) do
        nil -> []
        "" -> []
        super -> [{String.downcase(super), "super"}]
      end

    base ++ comparative ++ superlative
  end

  def generate_forms(word) do
    # All other invariables: just base form
    [{String.downcase(word.term), "base"}]
  end
end
