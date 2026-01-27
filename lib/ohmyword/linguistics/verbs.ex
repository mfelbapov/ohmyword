defmodule Ohmyword.Linguistics.Verbs do
  @moduledoc """
  Serbian verb inflector that generates all conjugated forms.

  Handles:
  - Four conjugation classes: a-verb, i-verb, e-verb, je-verb
  - Present tense (6 forms)
  - Past participle / L-participle (6 forms)
  - Imperative (3 forms)
  - Reflexive verbs (with "se" suffix)
  - Irregular form overrides
  - Impersonal verbs (optional 3rd person only)
  """

  @behaviour Ohmyword.Linguistics.Inflector

  alias Ohmyword.Vocabulary.Word

  # Present tense endings by conjugation class
  @a_verb_present %{
    "1sg" => "m",
    "2sg" => "š",
    "3sg" => "",
    "1pl" => "mo",
    "2pl" => "te",
    "3pl" => "ju"
  }

  @i_verb_present %{
    "1sg" => "im",
    "2sg" => "iš",
    "3sg" => "i",
    "1pl" => "imo",
    "2pl" => "ite",
    "3pl" => "e"
  }

  @e_verb_present %{
    "1sg" => "em",
    "2sg" => "eš",
    "3sg" => "e",
    "1pl" => "emo",
    "2pl" => "ete",
    "3pl" => "u"
  }

  # Past participle (L-participle) endings
  @past_participle_endings %{
    "m_sg" => "o",
    "f_sg" => "la",
    "n_sg" => "lo",
    "m_pl" => "li",
    "f_pl" => "le",
    "n_pl" => "la"
  }

  @impl true
  def applicable?(%Word{part_of_speech: :verb}), do: true
  def applicable?(_), do: false

  @impl true
  def generate_forms(%Word{} = word) do
    metadata = word.grammar_metadata || %{}
    irregular_forms = metadata["irregular_forms"] || %{}
    reflexive = word.reflexive == true

    # Extract base term (without "se" for reflexive verbs)
    base_term = extract_base_term(word.term, reflexive)
    term = String.downcase(base_term)

    # Get stems
    infinitive_stem = get_infinitive_stem(term)
    present_stem = get_present_stem(term, word.conjugation_class, metadata)

    # Generate all forms
    forms =
      generate_infinitive(word.term, reflexive) ++
        generate_present_forms(present_stem, word.conjugation_class, irregular_forms, reflexive) ++
        generate_past_forms(infinitive_stem, term, irregular_forms, reflexive) ++
        generate_imperative_forms(
          present_stem,
          word.conjugation_class,
          irregular_forms,
          reflexive
        )

    # Apply any remaining irregular form overrides
    Enum.map(forms, fn {form, tag} ->
      if override = Map.get(irregular_forms, tag) do
        {maybe_add_reflexive(String.downcase(override), reflexive), tag}
      else
        {form, tag}
      end
    end)
  end

  # Extract base term without "se" for reflexive verbs
  defp extract_base_term(term, true) do
    term
    |> String.trim_trailing(" se")
    |> String.trim()
  end

  defp extract_base_term(term, false), do: term

  # Get infinitive stem by removing -ti or -ći
  defp get_infinitive_stem(term) do
    cond do
      String.ends_with?(term, "ći") -> String.slice(term, 0..-3//1)
      String.ends_with?(term, "ti") -> String.slice(term, 0..-3//1)
      true -> term
    end
  end

  # Get present stem - use metadata if provided, otherwise derive from infinitive
  defp get_present_stem(term, conjugation_class, metadata) do
    case metadata["present_stem"] do
      nil -> derive_present_stem(term, conjugation_class)
      stem -> stem
    end
  end

  # Derive present stem from infinitive based on conjugation class
  defp derive_present_stem(term, "a-verb") do
    # Remove -ti to get stem ending in -a
    String.slice(term, 0..-3//1)
  end

  defp derive_present_stem(term, "i-verb") do
    # Remove -iti or -eti to get consonant stem
    cond do
      String.ends_with?(term, "iti") -> String.slice(term, 0..-4//1)
      String.ends_with?(term, "eti") -> String.slice(term, 0..-4//1)
      true -> String.slice(term, 0..-3//1)
    end
  end

  defp derive_present_stem(term, "e-verb") do
    # E-verbs typically need present_stem in metadata
    # Fallback: remove -ati
    cond do
      String.ends_with?(term, "ati") -> String.slice(term, 0..-4//1)
      true -> String.slice(term, 0..-3//1)
    end
  end

  defp derive_present_stem(term, "je-verb") do
    # JE-verbs: remove -ti to get infinitive stem, then add j
    # e.g., piti -> pi -> pij
    stem =
      cond do
        String.ends_with?(term, "ti") -> String.slice(term, 0..-3//1)
        true -> term
      end

    stem <> "j"
  end

  defp derive_present_stem(term, _) do
    # Default: treat as a-verb
    String.slice(term, 0..-3//1)
  end

  # Generate infinitive form
  # Note: For reflexive verbs, the term already includes "se", so don't add it again
  defp generate_infinitive(term, _reflexive) do
    [{String.downcase(term), "inf"}]
  end

  # Generate present tense forms
  defp generate_present_forms(stem, conjugation_class, irregular_forms, reflexive) do
    endings = get_present_endings(conjugation_class)

    ["1sg", "2sg", "3sg", "1pl", "2pl", "3pl"]
    |> Enum.map(fn person ->
      tag = "pres_#{person}"

      form =
        if override = Map.get(irregular_forms, tag) do
          String.downcase(override)
        else
          stem <> Map.get(endings, person, "")
        end

      {maybe_add_reflexive(form, reflexive), tag}
    end)
  end

  defp get_present_endings("a-verb"), do: @a_verb_present
  defp get_present_endings("i-verb"), do: @i_verb_present
  defp get_present_endings("e-verb"), do: @e_verb_present
  defp get_present_endings("je-verb"), do: @e_verb_present
  defp get_present_endings(_), do: @a_verb_present

  # Generate past participle (L-participle) forms
  defp generate_past_forms(infinitive_stem, term, irregular_forms, reflexive) do
    # Determine the L-participle stem
    l_stem = get_l_participle_stem(infinitive_stem, term)

    ["m_sg", "f_sg", "n_sg", "m_pl", "f_pl", "n_pl"]
    |> Enum.map(fn gender_number ->
      tag = "past_#{gender_number}"

      form =
        if override = Map.get(irregular_forms, tag) do
          String.downcase(override)
        else
          ending = Map.get(@past_participle_endings, gender_number)
          build_past_form(l_stem, gender_number, ending)
        end

      {maybe_add_reflexive(form, reflexive), tag}
    end)
  end

  # Get the L-participle stem
  defp get_l_participle_stem(infinitive_stem, _term) do
    infinitive_stem
  end

  # Build past participle form with proper vowel handling
  defp build_past_form(stem, "m_sg", _ending) do
    # Masculine singular: stem + o (with possible vowel adjustment)
    # If stem ends in consonant, need -ao; if vowel, just -o
    last_char = String.last(stem)

    if is_vowel?(last_char) do
      stem <> "o"
    else
      stem <> "ao"
    end
  end

  defp build_past_form(stem, _gender_number, ending) do
    stem <> ending
  end

  defp is_vowel?(char) when is_binary(char) do
    char in ~w(a e i o u)
  end

  # Generate imperative forms
  defp generate_imperative_forms(present_stem, conjugation_class, irregular_forms, reflexive) do
    endings = get_imperative_endings(present_stem, conjugation_class)

    [{"2sg", "imp_2sg"}, {"1pl", "imp_1pl"}, {"2pl", "imp_2pl"}]
    |> Enum.map(fn {person, tag} ->
      form =
        if override = Map.get(irregular_forms, tag) do
          String.downcase(override)
        else
          present_stem <> Map.get(endings, person, "")
        end

      {maybe_add_reflexive(form, reflexive), tag}
    end)
  end

  # Get imperative endings based on stem ending and conjugation class
  defp get_imperative_endings(stem, conjugation_class) do
    last_char = String.last(stem)

    cond do
      # A-verbs with vowel-ending stem use -j endings
      conjugation_class == "a-verb" and is_vowel?(last_char) ->
        %{"2sg" => "j", "1pl" => "jmo", "2pl" => "jte"}

      # I-verbs use -i endings
      conjugation_class == "i-verb" ->
        %{"2sg" => "i", "1pl" => "imo", "2pl" => "ite"}

      # E-verbs and je-verbs use -i endings
      conjugation_class in ["e-verb", "je-verb"] ->
        %{"2sg" => "i", "1pl" => "imo", "2pl" => "ite"}

      # Default: consonant stem uses -i endings
      true ->
        %{"2sg" => "i", "1pl" => "imo", "2pl" => "ite"}
    end
  end

  # Add "se" suffix for reflexive verbs
  defp maybe_add_reflexive(form, true), do: form <> " se"
  defp maybe_add_reflexive(form, false), do: form
end
