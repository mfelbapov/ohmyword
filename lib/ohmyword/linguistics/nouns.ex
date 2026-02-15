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
  alias Ohmyword.Linguistics.SoundChanges
  alias Ohmyword.Linguistics.Helpers

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
      "e-stem" -> decline_e_stem(term, case_atom, number, metadata)
      "i-stem" -> decline_i_stem(term, case_atom, number, metadata)
      "consonant" -> decline_consonant(term, word, case_atom, number, metadata)
      _ -> decline_consonant(term, word, case_atom, number, metadata)
    end
  end

  # A-stem declension (feminine -a nouns and masculine -a nouns)
  defp decline_a_stem(term, case_atom, number) do
    stem = remove_ending(term, "a")
    ending = @a_stem_endings[number][case_atom]

    # Apply sibilarization for dative/locative singular
    stem =
      if number == :sg and case_atom in [:dat, :loc] do
        SoundChanges.sibilarize(stem)
      else
        stem
      end

    stem <> ending
  end

  # O-stem declension (neuter -o nouns)
  defp decline_o_stem(term, case_atom, number) do
    stem = remove_ending(term, "o")
    ending = @o_stem_endings[number][case_atom]
    stem <> ending
  end

  # E-stem declension (neuter -e nouns)
  defp decline_e_stem(term, case_atom, number, metadata) do
    base_stem = remove_ending(term, "e")
    extended_stem = metadata["extended_stem"]

    # Check for extended stem (et/en) in singular oblique cases and plural
    # e.g., dete -> det-et-a
    uses_extended =
      extended_stem != nil and
        (number == :pl or
           (number == :sg and case_atom != :nom and case_atom != :acc and case_atom != :voc))

    stem =
      if uses_extended do
        base_stem <> extended_stem
      else
        base_stem
      end

    # When extended stem is used for ins_sg, use -om instead of -em
    ending =
      if uses_extended and number == :sg and case_atom == :ins do
        "om"
      else
        @e_stem_endings[number][case_atom]
      end

    stem <> ending
  end

  # I-stem declension (feminine consonant nouns)
  defp decline_i_stem(term, case_atom, number, metadata) do
    extended_stem = metadata["extended_stem"]

    # Nominative and accusative singular use the base term
    is_direct = number == :sg and case_atom in [:nom, :acc]

    stem = if extended_stem && !is_direct, do: extended_stem, else: term

    # Handle instrumental singular with iotation + -u (ins_ju)
    if number == :sg and case_atom == :ins and metadata["ins_ju"] == true do
      iotated = SoundChanges.iotate(stem)
      iotated <> "u"
    else
      ending = @i_stem_endings[number][case_atom]
      stem <> ending
    end
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
    extended_stem = metadata["extended_stem"]

    # For nominative, always use the original term
    if case_atom == :nom do
      term
    else
      # Get the base stem (with fleeting A removed if applicable)
      base_stem =
        if fleeting_a do
          remove_fleeting_a(term)
        else
          term
        end

      # Use extended stem for oblique cases if provided
      stem =
        if extended_stem && case_atom != :voc do
          extended_stem
        else
          base_stem
        end

      # Handle vocative with palatalization
      stem =
        if case_atom == :voc && palatalization do
          apply_palatalization(base_stem)
        else
          stem
        end

      # Get the ending
      ending = @consonant_sg_endings[case_atom]

      # Handle accusative based on animacy
      if case_atom == :acc do
        if word.animate do
          # Animate: accusative = genitive
          oblique_stem = if extended_stem, do: extended_stem, else: base_stem
          oblique_stem <> @consonant_sg_endings[:gen]
        else
          # Inanimate: accusative = nominative
          term
        end
      else
        stem <> ending
      end
    end
  end

  defp decline_consonant_plural(term, _word, case_atom, metadata) do
    fleeting_a = metadata["fleeting_a"] == true
    palatalization = metadata["palatalization"] == true
    extended_stem = metadata["extended_stem"]
    drops_in_plural = metadata["drops_in_plural"] == true

    # Determine the base stem (with fleeting A removed if applicable)
    base_stem = if fleeting_a, do: remove_fleeting_a(term), else: term

    # Determine the plural stem
    plural_stem =
      cond do
        # -in suffix nouns (demonyms): drop -in in plural (građanin → građan-)
        drops_in_plural && String.ends_with?(term, "in") ->
          String.slice(term, 0..-3//1)

        # Extended stem gets -ov-/-ev- insert
        extended_stem ->
          insert = get_plural_insert(extended_stem)
          extended_stem <> insert

        # Palatalization nouns: sibilarize for nom/voc_pl, no -ov-/-ev- insert
        palatalization && case_atom in [:nom, :voc] ->
          SoundChanges.sibilarize(base_stem)

        # Palatalization nouns: sibilarize for dat/ins/loc_pl
        palatalization && case_atom in [:dat, :ins, :loc] ->
          SoundChanges.sibilarize(base_stem)

        # Palatalization nouns: gen_pl restores fleeting A, acc_pl uses base stem
        palatalization && case_atom == :gen ->
          term

        palatalization ->
          base_stem

        # For fleeting A nouns with gen_pl, use the original term (with A)
        fleeting_a && case_atom == :gen ->
          term

        # For fleeting A nouns (non-gen), use stem without A
        fleeting_a ->
          base_stem

        # Regular consonant stem: monosyllabic gets -ov-/-ev- insert, polysyllabic does not
        monosyllabic?(term) ->
          insert = get_plural_insert(term)
          term <> insert

        true ->
          term
      end

    # Get the ending
    ending = @consonant_pl_endings[case_atom]

    plural_stem <> ending
  end

  defp remove_fleeting_a(term), do: Helpers.remove_fleeting_a(term)

  # Check if a term is monosyllabic (has exactly one vowel)
  defp monosyllabic?(term) do
    vowel_count = term |> String.graphemes() |> Enum.count(&(&1 in ~w(a e i o u)))
    vowel_count <= 1
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
