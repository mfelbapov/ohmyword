defmodule Ohmyword.Linguistics.Nouns do
  @moduledoc """
  Serbian noun inflector that generates all 14 declined forms (7 cases x 2 numbers).

  Handles:
  - Five declension classes: consonant, a-stem, o-stem, e-stem, i-stem
  - Fleeting vowel A (pas → psa)
  - Palatalization in vocative (junak → junače)
  - Animacy for masculine accusative
  - Irregular plural stems and form overrides
  - Singularia tantum and pluralia tantum
  """

  @behaviour Ohmyword.Linguistics.Inflector

  alias Ohmyword.Vocabulary.Word

  # Cases in Serbian
  @cases [:nom, :gen, :dat, :acc, :voc, :ins, :loc]

  # Palatalization mappings for vocative
  @palatalization_map %{
    "k" => "č",
    "g" => "ž",
    "h" => "š",
    "c" => "č",
    "z" => "ž"
  }

  # Palatal consonants that take -ev- instead of -ov- in plural
  @palatal_consonants ~w(č ć š ž đ j)
  # Also handles "dž", "lj", "nj" as digraphs

  # Ending tables for each declension class
  # A-stem (feminine -a nouns and masculine -a nouns like "tata")
  @a_stem_endings %{
    sg: %{nom: "a", gen: "e", dat: "i", acc: "u", voc: "o", ins: "om", loc: "i"},
    pl: %{nom: "e", gen: "a", dat: "ama", acc: "e", voc: "e", ins: "ama", loc: "ama"}
  }

  # O-stem (neuter -o nouns)
  @o_stem_endings %{
    sg: %{nom: "o", gen: "a", dat: "u", acc: "o", voc: "o", ins: "om", loc: "u"},
    pl: %{nom: "a", gen: "a", dat: "ima", acc: "a", voc: "a", ins: "ima", loc: "ima"}
  }

  # E-stem (neuter -e nouns)
  @e_stem_endings %{
    sg: %{nom: "e", gen: "a", dat: "u", acc: "e", voc: "e", ins: "em", loc: "u"},
    pl: %{nom: "a", gen: "a", dat: "ima", acc: "a", voc: "a", ins: "ima", loc: "ima"}
  }

  # I-stem (feminine consonant nouns)
  @i_stem_endings %{
    sg: %{nom: "", gen: "i", dat: "i", acc: "", voc: "i", ins: "i", loc: "i"},
    pl: %{nom: "i", gen: "i", dat: "ima", acc: "i", voc: "i", ins: "ima", loc: "ima"}
  }

  # Consonant stem singular endings (masculine consonant nouns)
  @consonant_sg_endings %{nom: "", gen: "a", dat: "u", acc: "", voc: "e", ins: "om", loc: "u"}

  # Consonant stem plural endings (without insert, used with -ov-/-ev- or directly)
  @consonant_pl_endings %{
    nom: "i",
    gen: "a",
    dat: "ima",
    acc: "e",
    voc: "i",
    ins: "ima",
    loc: "ima"
  }

  @impl true
  def applicable?(%Word{part_of_speech: :noun}), do: true
  def applicable?(_), do: false

  @impl true
  def generate_forms(%Word{} = word) do
    term = String.downcase(word.term)
    metadata = word.grammar_metadata || %{}
    declension_class = word.declension_class || infer_declension_class(word)

    cond do
      metadata["singularia_tantum"] ->
        generate_singular_forms(term, word, declension_class, metadata)

      metadata["pluralia_tantum"] ->
        generate_plural_forms(term, word, declension_class, metadata)

      true ->
        generate_singular_forms(term, word, declension_class, metadata) ++
          generate_plural_forms(term, word, declension_class, metadata)
    end
  end

  # Generate 7 singular forms
  defp generate_singular_forms(term, word, declension_class, metadata) do
    Enum.map(@cases, fn case_atom ->
      form_tag = "#{case_atom}_sg"
      form = build_form(term, word, declension_class, case_atom, :sg, metadata, form_tag)
      {form, form_tag}
    end)
  end

  # Generate 7 plural forms
  defp generate_plural_forms(term, word, declension_class, metadata) do
    Enum.map(@cases, fn case_atom ->
      form_tag = "#{case_atom}_pl"
      form = build_form(term, word, declension_class, case_atom, :pl, metadata, form_tag)
      {form, form_tag}
    end)
  end

  # Build a single form, checking for overrides first
  defp build_form(term, word, declension_class, case_atom, number, metadata, form_tag) do
    # Check for irregular form override
    if override = get_in(metadata, ["irregular_forms", form_tag]) do
      String.downcase(override)
    else
      apply_regular_declension(term, word, declension_class, case_atom, number, metadata)
    end
  end

  # Apply regular declension rules
  defp apply_regular_declension(term, word, declension_class, case_atom, number, metadata) do
    case declension_class do
      "a-stem" -> decline_a_stem(term, case_atom, number)
      "o-stem" -> decline_o_stem(term, case_atom, number)
      "e-stem" -> decline_e_stem(term, case_atom, number)
      "i-stem" -> decline_i_stem(term, case_atom, number)
      "consonant" -> decline_consonant(term, word, case_atom, number, metadata)
      _ -> decline_consonant(term, word, case_atom, number, metadata)
    end
  end

  # A-stem declension (feminine -a nouns and masculine -a nouns)
  defp decline_a_stem(term, case_atom, number) do
    stem = remove_ending(term, "a")
    ending = @a_stem_endings[number][case_atom]
    stem <> ending
  end

  # O-stem declension (neuter -o nouns)
  defp decline_o_stem(term, case_atom, number) do
    stem = remove_ending(term, "o")
    ending = @o_stem_endings[number][case_atom]
    stem <> ending
  end

  # E-stem declension (neuter -e nouns)
  defp decline_e_stem(term, case_atom, number) do
    stem = remove_ending(term, "e")
    ending = @e_stem_endings[number][case_atom]
    stem <> ending
  end

  # I-stem declension (feminine consonant nouns)
  defp decline_i_stem(term, case_atom, number) do
    ending = @i_stem_endings[number][case_atom]
    term <> ending
  end

  # Consonant stem declension (masculine consonant nouns)
  defp decline_consonant(term, word, case_atom, number, metadata) do
    case number do
      :sg -> decline_consonant_singular(term, word, case_atom, metadata)
      :pl -> decline_consonant_plural(term, word, case_atom, metadata)
    end
  end

  defp decline_consonant_singular(term, word, case_atom, metadata) do
    fleeting_a = metadata["fleeting_a"] == true
    palatalization = metadata["palatalization"] == true

    # For nominative, always use the original term
    if case_atom == :nom do
      term
    else
      # Get the stem (with fleeting A removed if applicable)
      stem =
        if fleeting_a do
          remove_fleeting_a(term)
        else
          term
        end

      # Handle vocative with palatalization
      stem =
        if case_atom == :voc && palatalization do
          apply_palatalization(stem)
        else
          stem
        end

      # Get the ending
      ending = @consonant_sg_endings[case_atom]

      # Handle accusative based on animacy
      if case_atom == :acc do
        if word.animate do
          # Animate: accusative = genitive
          stem <> @consonant_sg_endings[:gen]
        else
          # Inanimate: accusative = nominative
          term
        end
      else
        stem <> ending
      end
    end
  end

  defp decline_consonant_plural(term, word, case_atom, metadata) do
    irregular_plural = metadata["irregular_plural"]
    fleeting_a = metadata["fleeting_a"] == true

    # For animate accusative, we need to return the genitive form
    # This must be handled specially for fleeting A nouns
    if case_atom == :acc && word.animate do
      # Animate accusative = genitive, so recursively get the genitive form
      decline_consonant_plural(term, word, :gen, metadata)
    else
      # Determine the plural stem
      plural_stem =
        cond do
          # Use irregular plural stem if provided
          irregular_plural ->
            irregular_plural

          # For fleeting A nouns with gen_pl, use the original term (with A)
          fleeting_a && case_atom == :gen ->
            term

          # For fleeting A nouns (non-gen), use stem without A
          fleeting_a ->
            remove_fleeting_a(term)

          # Regular consonant stem with -ov-/-ev- insert
          true ->
            insert = get_plural_insert(term)
            term <> insert
        end

      # Get the ending
      ending = @consonant_pl_endings[case_atom]

      plural_stem <> ending
    end
  end

  # Remove the fleeting 'a' from the stem
  # e.g., "pas" -> "ps", "san" -> "sn", "vrabac" -> "vrabc"
  defp remove_fleeting_a(term) do
    # Find the last 'a' that's between consonants and remove it
    graphemes = String.graphemes(term)
    len = length(graphemes)

    if len < 3 do
      term
    else
      # Find position of fleeting 'a' (typically second to last position)
      # For "pas" -> remove 'a' at position 1 -> "ps"
      # For "vrabac" -> remove 'a' at position 4 -> "vrabc"
      find_and_remove_fleeting_a(graphemes)
    end
  end

  defp find_and_remove_fleeting_a(graphemes) do
    # Iterate from the end, looking for 'a' between consonants
    indexed = Enum.with_index(graphemes)

    # Find the rightmost 'a' that is surrounded by consonants
    result =
      indexed
      |> Enum.reverse()
      |> Enum.find(fn {char, idx} ->
        char == "a" && idx > 0 && idx < length(graphemes) - 1 &&
          is_consonant?(Enum.at(graphemes, idx - 1)) &&
          is_consonant?(Enum.at(graphemes, idx + 1))
      end)

    case result do
      {_, idx} ->
        graphemes
        |> List.delete_at(idx)
        |> Enum.join()

      nil ->
        Enum.join(graphemes)
    end
  end

  defp is_consonant?(char) when is_binary(char) do
    vowels = ~w(a e i o u)
    char not in vowels
  end

  # Determine plural insert: -ov-, -ev-, or nothing
  defp get_plural_insert(stem) do
    last_char = String.last(stem)

    # Check for digraphs first
    last_two = String.slice(stem, -2..-1//1)

    cond do
      last_two in ["dž", "lj", "nj"] -> "ev"
      last_char in @palatal_consonants -> "ev"
      # Most consonants get -ov-
      true -> "ov"
    end
  end

  # Apply palatalization for vocative
  defp apply_palatalization(stem) do
    last_char = String.last(stem)

    case Map.get(@palatalization_map, last_char) do
      nil ->
        stem

      replacement ->
        String.slice(stem, 0..-2//1) <> replacement
    end
  end

  # Remove ending from term
  defp remove_ending(term, ending) do
    if String.ends_with?(term, ending) do
      String.slice(term, 0, String.length(term) - String.length(ending))
    else
      term
    end
  end

  # Infer declension class from gender and term ending
  defp infer_declension_class(%Word{gender: gender, term: term}) do
    term_lower = String.downcase(term)

    case {gender, String.last(term_lower)} do
      {:masculine, "a"} -> "a-stem"
      {:masculine, "o"} -> "o-stem"
      {:masculine, _} -> "consonant"
      {:feminine, "a"} -> "a-stem"
      {:feminine, _} -> "i-stem"
      {:neuter, "o"} -> "o-stem"
      {:neuter, "e"} -> "e-stem"
      {:neuter, _} -> "o-stem"
      _ -> "consonant"
    end
  end
end
