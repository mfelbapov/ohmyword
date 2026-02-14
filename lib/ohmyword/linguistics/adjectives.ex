defmodule Ohmyword.Linguistics.Adjectives do
  @moduledoc """
  Serbian adjective inflector that generates all declined forms.

  Handles:
  - Indefinite declension (42 forms: 7 cases x 2 numbers x 3 genders)
  - Definite declension (42 forms: 7 cases x 2 numbers x 3 genders)
  - Soft stem adjustments (č, ć, š, ž, đ, j, lj, nj, dž)
  - Fleeting vowel A (dobar → dobr-)
  - Animacy for masculine accusative singular
  - Indeclinable adjectives
  - Comparative and superlative forms (optional)
  - Irregular form overrides
  """

  @behaviour Ohmyword.Linguistics.Inflector

  alias Ohmyword.Vocabulary.Word
  alias Ohmyword.Linguistics.SoundChanges

  # Cases in Serbian
  @cases [:nom, :gen, :dat, :acc, :voc, :ins, :loc]
  @genders [:m, :f, :n]
  @numbers [:sg, :pl]

  # Soft consonants that require -e instead of -o in neuter
  @soft_consonants ~w(č ć š ž đ j)
  # Soft digraphs
  @soft_digraphs ~w(lj nj dž)

  # Indefinite singular endings by gender
  @indef_sg_endings %{
    m: %{nom: "", gen: "a", dat: "u", acc: :animate_dependent, voc: "", ins: "im", loc: "u"},
    f: %{nom: "a", gen: "e", dat: "oj", acc: "u", voc: "a", ins: "om", loc: "oj"},
    n: %{
      nom: :soft_dependent,
      gen: "a",
      dat: "u",
      acc: :soft_dependent,
      voc: :soft_dependent,
      ins: "im",
      loc: "u"
    }
  }

  # Indefinite plural endings by gender
  @indef_pl_endings %{
    m: %{nom: "i", gen: "ih", dat: "im", acc: "e", voc: "i", ins: "im", loc: "im"},
    f: %{nom: "e", gen: "ih", dat: "im", acc: "e", voc: "e", ins: "im", loc: "im"},
    n: %{nom: "a", gen: "ih", dat: "im", acc: "a", voc: "a", ins: "im", loc: "im"}
  }

  # Definite singular endings by gender
  # :soft_dependent_back — soft stems use -eg/-em, hard stems use -og/-om
  @def_sg_endings %{
    m: %{
      nom: "i",
      gen: :soft_dependent_back,
      dat: :soft_dependent_back,
      acc: :animate_dependent,
      voc: "i",
      ins: "im",
      loc: :soft_dependent_back
    },
    f: %{nom: "a", gen: "e", dat: "oj", acc: "u", voc: "a", ins: "om", loc: "oj"},
    n: %{
      nom: :soft_dependent,
      gen: :soft_dependent_back,
      dat: :soft_dependent_back,
      acc: :soft_dependent,
      voc: :soft_dependent,
      ins: "im",
      loc: :soft_dependent_back
    }
  }

  # Definite plural endings (same as indefinite plural)
  @def_pl_endings @indef_pl_endings

  @impl true
  def applicable?(%Word{part_of_speech: :adjective}), do: true
  def applicable?(_), do: false

  @impl true
  def generate_forms(%Word{} = word) do
    metadata = word.grammar_metadata || %{}

    # Handle indeclinable adjectives
    if metadata["indeclinable"] do
      [{String.downcase(word.term), "invariable"}]
    else
      term = String.downcase(word.term)
      stem = get_stem(term, metadata)
      soft = soft_stem?(stem) || metadata["soft_stem"] == true

      forms =
        if metadata["no_short_form"] do
          # Only generate definite forms
          generate_definite_forms(stem, word, metadata, soft)
        else
          # Generate both indefinite and definite forms
          generate_indefinite_forms(stem, word, metadata, soft) ++
            generate_definite_forms(stem, word, metadata, soft)
        end

      # Add alternate masculine accusative singular forms (animate/inanimate pair)
      forms = forms ++ alternate_masc_acc_sg_forms(stem, word, soft, metadata)

      # Add comparative and superlative if stems are provided
      forms =
        forms ++
          maybe_generate_comparative_forms(word, metadata, soft) ++
          maybe_generate_superlative_forms(word, metadata, soft)

      # Apply irregular form overrides
      apply_irregular_overrides(forms, metadata)
    end
  end

  # Get the stem by removing nominative ending and handling fleeting A if applicable
  defp get_stem(term, metadata) do
    # First remove the masculine nominative ending (-i for definite form citation)
    stem = remove_nominative_ending(term)

    # Then handle L-O alternation
    stem = SoundChanges.resolve_l_o_alternation(stem)

    # Then handle fleeting A if applicable
    stem =
      if metadata["fleeting_a"] == true do
        remove_fleeting_a(stem)
      else
        stem
      end

    # Handle voice assimilation (e.g., težak -> teška)
    SoundChanges.assimilate_voice(stem)
  end

  # Remove the masculine nominative ending from citation form
  # Adjectives may be cited in definite form (ending -i) or indefinite form (no ending)
  defp remove_nominative_ending(term) do
    if String.ends_with?(term, "i") do
      String.slice(term, 0..-2//1)
    else
      term
    end
  end

  # Check if stem ends with a soft consonant or digraph
  defp soft_stem?(stem) do
    last_two = String.slice(stem, -2..-1//1)
    last_one = String.last(stem)

    last_two in @soft_digraphs || last_one in @soft_consonants
  end

  # Remove the fleeting 'a' from the stem
  # e.g., "dobar" -> "dobr", "kratak" -> "kratk"
  defp remove_fleeting_a(term) do
    graphemes = String.graphemes(term)
    len = length(graphemes)

    if len < 3 do
      term
    else
      find_and_remove_fleeting_a(graphemes)
    end
  end

  defp find_and_remove_fleeting_a(graphemes) do
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

  # Generate 42 indefinite forms
  defp generate_indefinite_forms(stem, word, metadata, soft) do
    for number <- @numbers,
        gender <- @genders,
        case_atom <- @cases do
      form_tag = "indef_#{case_atom}_#{number}_#{gender}"

      form =
        build_indefinite_form(stem, word, case_atom, number, gender, metadata, soft, form_tag)

      {form, form_tag}
    end
  end

  # Generate 42 definite forms
  defp generate_definite_forms(stem, word, metadata, soft) do
    for number <- @numbers,
        gender <- @genders,
        case_atom <- @cases do
      form_tag = "def_#{case_atom}_#{number}_#{gender}"
      form = build_definite_form(stem, word, case_atom, number, gender, metadata, soft, form_tag)
      {form, form_tag}
    end
  end

  # Build a single indefinite form
  defp build_indefinite_form(stem, word, case_atom, number, gender, _metadata, soft, _form_tag) do
    # Special handling for Indefinite Nom/Voc Singular Masculine (both have empty ending)
    # If the input term appears to be indefinite (doesn't end in -i), maintain it as is
    # to preserve the "unmodified" form (before L-O or Fleeting A removal)
    if case_atom in [:nom, :voc] and number == :sg and gender == :m and
         not String.ends_with?(word.term, "i") do
      String.downcase(word.term)
    else
      endings = if number == :sg, do: @indef_sg_endings, else: @indef_pl_endings
      ending = endings[gender][case_atom]

      resolve_ending_and_build(stem, word, ending, case_atom, number, gender, soft, :indef)
    end
  end

  # Build a single definite form
  defp build_definite_form(stem, word, case_atom, number, gender, _metadata, soft, _form_tag) do
    endings = if number == :sg, do: @def_sg_endings, else: @def_pl_endings
    ending = endings[gender][case_atom]

    resolve_ending_and_build(stem, word, ending, case_atom, number, gender, soft, :def)
  end

  # Resolve special endings and build the form
  defp resolve_ending_and_build(stem, word, ending, case_atom, number, _gender, soft, declension) do
    case ending do
      :soft_dependent ->
        # Neuter nom/acc/voc: -o for hard stems, -e for soft stems
        actual_ending = if soft, do: "e", else: "o"
        stem <> actual_ending

      :soft_dependent_back ->
        # Definite gen/dat/loc m/n: soft stems use -eg/-em, hard use -og/-om
        resolve_soft_back_ending(stem, case_atom, soft)

      :animate_dependent ->
        # Masculine accusative: depends on animacy and number
        resolve_masculine_accusative(stem, word, number, soft, declension)

      ending when is_binary(ending) ->
        stem <> ending
    end
  end

  # Resolve back-vowel endings for definite m/n gen/dat/loc
  defp resolve_soft_back_ending(stem, case_atom, soft) do
    case case_atom do
      :gen -> stem <> if(soft, do: "eg", else: "og")
      _ -> stem <> if(soft, do: "em", else: "om")
    end
  end

  # Resolve masculine accusative based on animacy
  defp resolve_masculine_accusative(stem, word, number, soft, declension) do
    animate = word.animate == true

    case {number, animate, declension} do
      {:sg, true, :indef} ->
        # Animate singular indefinite: use genitive = stem + "a"
        stem <> "a"

      {:sg, false, :indef} ->
        # Inanimate singular indefinite: use nominative
        # Use original term if it looks indefinite
        if not String.ends_with?(word.term, "i") do
          String.downcase(word.term)
        else
          stem
        end

      {:sg, true, :def} ->
        # Animate singular definite: use genitive = stem + "og"/"eg"
        stem <> if(soft, do: "eg", else: "og")

      {:sg, false, :def} ->
        # Inanimate singular definite: use nominative = stem + "i"
        stem <> "i"

      {:pl, _, _} ->
        # Plural: always "e" (same for animate and inanimate)
        stem <> "e"
    end
  end

  # Generate alternate masculine accusative singular forms.
  # Adjectives can modify both animate and inanimate nouns, so both
  # accusative forms must be available. The main generation picks one
  # based on word.animate; this adds the other variant under the same form_tag.
  defp alternate_masc_acc_sg_forms(stem, word, soft, metadata) do
    if metadata["no_short_form"] do
      alternate_for_declension(stem, word, soft, :def)
    else
      alternate_for_declension(stem, word, soft, :indef) ++
        alternate_for_declension(stem, word, soft, :def)
    end
  end

  defp alternate_for_declension(stem, word, soft, declension) do
    animate = word.animate == true
    prefix = if declension == :indef, do: "indef", else: "def"
    form_tag = "#{prefix}_acc_sg_m"

    alt_form =
      if animate do
        # Main generated animate, add inanimate
        case declension do
          :indef ->
            if not String.ends_with?(word.term, "i"),
              do: String.downcase(word.term),
              else: stem

          :def ->
            stem <> "i"
        end
      else
        # Main generated inanimate, add animate
        case declension do
          :indef -> stem <> "a"
          :def -> stem <> if(soft, do: "eg", else: "og")
        end
      end

    [{alt_form, form_tag}]
  end

  # Generate comparative forms if comparative_stem is provided
  defp maybe_generate_comparative_forms(word, metadata, _soft) do
    case metadata["comparative_stem"] do
      nil ->
        []

      comp_stem ->
        # Comparative uses definite declension endings (always soft due to -ij- suffix)
        for number <- @numbers,
            gender <- @genders,
            case_atom <- @cases do
          form_tag = "comp_#{case_atom}_#{number}_#{gender}"

          form =
            build_definite_form(
              comp_stem,
              word,
              case_atom,
              number,
              gender,
              metadata,
              true,
              form_tag
            )

          {form, form_tag}
        end
    end
  end

  # Generate superlative forms if superlative_stem is provided (or derive from comparative)
  defp maybe_generate_superlative_forms(word, metadata, _soft) do
    super_stem =
      case metadata["superlative_stem"] do
        nil ->
          # Derive from comparative: add "naj" prefix
          case metadata["comparative_stem"] do
            nil -> nil
            comp_stem -> "naj" <> comp_stem
          end

        stem ->
          stem
      end

    case super_stem do
      nil ->
        []

      stem ->
        # Superlative uses definite declension endings (always soft)
        for number <- @numbers,
            gender <- @genders,
            case_atom <- @cases do
          form_tag = "super_#{case_atom}_#{number}_#{gender}"

          form =
            build_definite_form(stem, word, case_atom, number, gender, metadata, true, form_tag)

          {form, form_tag}
        end
    end
  end

  # Apply irregular form overrides
  defp apply_irregular_overrides(forms, metadata) do
    irregular_forms = metadata["irregular_forms"] || %{}

    Enum.map(forms, fn {form, tag} ->
      case Map.get(irregular_forms, tag) do
        nil -> {form, tag}
        override -> {String.downcase(override), tag}
      end
    end)
  end
end
