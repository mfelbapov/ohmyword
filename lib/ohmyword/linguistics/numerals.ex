defmodule Ohmyword.Linguistics.Numerals do
  @moduledoc """
  Serbian numeral inflector that generates all declined forms.

  Handles:
  - Cardinal numerals 1-4 (fully or partially declined)
  - Cardinal numerals 5+ (invariable)
  - Ordinal numerals (adjective-like declension)
  - Collective numerals (special declension)
  - Irregular form overrides
  """

  @behaviour Ohmyword.Linguistics.Inflector

  alias Ohmyword.Vocabulary.Word
  alias Ohmyword.Linguistics.Helpers

  @genders [:m, :f, :n]
  @numbers [:sg, :pl]

  # Soft consonants that require -e instead of -o in neuter
  @soft_consonants ~w(č ć š ž đ j)
  @soft_digraphs ~w(lj nj dž)

  # Hardcoded paradigm for "jedan" (1) - full adjectival declension
  @jedan_paradigm %{
    "nom_sg_m" => "jedan",
    "nom_sg_f" => "jedna",
    "nom_sg_n" => "jedno",
    "gen_sg_m" => "jednog",
    "gen_sg_f" => "jedne",
    "gen_sg_n" => "jednog",
    "dat_sg_m" => "jednom",
    "dat_sg_f" => "jednoj",
    "dat_sg_n" => "jednom",
    "acc_sg_m" => "jedan",
    "acc_sg_m_anim" => "jednog",
    "acc_sg_f" => "jednu",
    "acc_sg_n" => "jedno",
    "ins_sg_m" => "jednim",
    "ins_sg_f" => "jednom",
    "ins_sg_n" => "jednim",
    "loc_sg_m" => "jednom",
    "loc_sg_f" => "jednoj",
    "loc_sg_n" => "jednom"
  }

  # Hardcoded paradigm for "dva" (2) - gender forms + partial declension
  @dva_paradigm %{
    "nom_m" => "dva",
    "nom_f" => "dve",
    "nom_n" => "dva",
    "gen_m" => "dvaju",
    "gen_f" => "dveju",
    "gen" => "dvaju",
    "dat_m" => "dvama",
    "dat_f" => "dvema",
    "dat" => "dvama",
    "acc_m" => "dva",
    "acc_f" => "dve",
    "ins_m" => "dvama",
    "ins_f" => "dvema",
    "ins" => "dvama",
    "loc_m" => "dvama",
    "loc_f" => "dvema",
    "loc" => "dvama"
  }

  # Hardcoded paradigm for "tri" (3) - partial declension, no gender
  @tri_paradigm %{
    "nom" => "tri",
    "gen" => "triju",
    "dat" => "trima",
    "acc" => "tri",
    "ins" => "trima",
    "loc" => "trima"
  }

  # Hardcoded paradigm for "četiri" (4) - partial declension, no gender
  @cetiri_paradigm %{
    "nom" => "četiri",
    "gen" => "četiriju",
    "dat" => "četirima",
    "acc" => "četiri",
    "ins" => "četirima",
    "loc" => "četirima"
  }

  # Hardcoded paradigm for "oba/obe" (both) - like "dva"
  @oba_paradigm %{
    "nom_m" => "oba",
    "nom_f" => "obe",
    "gen_m" => "obaju",
    "gen_f" => "obeju",
    "dat_m" => "oboma",
    "dat_f" => "obema",
    "acc_m" => "oba",
    "acc_f" => "obe",
    "ins_m" => "oboma",
    "ins_f" => "obema",
    "loc_m" => "oboma",
    "loc_f" => "obema"
  }

  # Collective numerals paradigms
  @collective_paradigms %{
    "dvoje" => %{
      "nom" => "dvoje",
      "gen" => "dvoga",
      "dat" => "dvoma",
      "acc" => "dvoje",
      "ins" => "dvoma",
      "loc" => "dvoma"
    },
    "troje" => %{
      "nom" => "troje",
      "gen" => "troga",
      "dat" => "troma",
      "acc" => "troje",
      "ins" => "troma",
      "loc" => "troma"
    },
    "četvoro" => %{
      "nom" => "četvoro",
      "gen" => "četvorga",
      "dat" => "četvorma",
      "acc" => "četvoro",
      "ins" => "četvorma",
      "loc" => "četvorma"
    },
    "petoro" => %{
      "nom" => "petoro",
      "gen" => "petorga",
      "dat" => "petorma",
      "acc" => "petoro",
      "ins" => "petorma",
      "loc" => "petorma"
    },
    "šestoro" => %{
      "nom" => "šestoro",
      "gen" => "šestorga",
      "dat" => "šestorma",
      "acc" => "šestoro",
      "ins" => "šestorma",
      "loc" => "šestorma"
    },
    "sedmoro" => %{
      "nom" => "sedmoro",
      "gen" => "sedmorga",
      "dat" => "sedmorma",
      "acc" => "sedmoro",
      "ins" => "sedmorma",
      "loc" => "sedmorma"
    },
    "osmoro" => %{
      "nom" => "osmoro",
      "gen" => "osmorga",
      "dat" => "osmorma",
      "acc" => "osmoro",
      "ins" => "osmorma",
      "loc" => "osmorma"
    },
    "devetoro" => %{
      "nom" => "devetoro",
      "gen" => "devetorga",
      "dat" => "devetorma",
      "acc" => "devetoro",
      "ins" => "devetorma",
      "loc" => "devetorma"
    },
    "desetoro" => %{
      "nom" => "desetoro",
      "gen" => "desetorga",
      "dat" => "desetorma",
      "acc" => "desetoro",
      "ins" => "desetorma",
      "loc" => "desetorma"
    }
  }

  # Definite adjective singular endings by gender (for ordinals)
  # gen/dat/loc for m/n are soft-dependent: -og/-om for hard, -eg/-em for soft stems
  @def_sg_endings %{
    m: %{
      nom: "i",
      gen: :soft_back_vowel,
      dat: :soft_back_vowel_m,
      acc: :animate_dependent,
      voc: "i",
      ins: "im",
      loc: :soft_back_vowel_m
    },
    f: %{nom: "a", gen: "e", dat: "oj", acc: "u", voc: "a", ins: "om", loc: "oj"},
    n: %{
      nom: :soft_dependent,
      gen: :soft_back_vowel,
      dat: :soft_back_vowel_m,
      acc: :soft_dependent,
      voc: :soft_dependent,
      ins: "im",
      loc: :soft_back_vowel_m
    }
  }

  # Definite adjective plural endings by gender (for ordinals)
  @def_pl_endings %{
    m: %{nom: "i", gen: "ih", dat: "im", acc: "e", voc: "i", ins: "im", loc: "im"},
    f: %{nom: "e", gen: "ih", dat: "im", acc: "e", voc: "e", ins: "im", loc: "im"},
    n: %{nom: "a", gen: "ih", dat: "im", acc: "a", voc: "a", ins: "im", loc: "im"}
  }

  @impl true
  def applicable?(%Word{part_of_speech: :numeral}), do: true
  def applicable?(_), do: false

  @impl true
  def generate_forms(%Word{} = word) do
    metadata = word.grammar_metadata || %{}
    numeral_type = metadata["numeral_type"] || infer_numeral_type(word)

    forms =
      case numeral_type do
        "cardinal" -> generate_cardinal_forms(word, metadata)
        "ordinal" -> generate_ordinal_forms(word, metadata)
        "collective" -> generate_collective_forms(word, metadata)
        _ -> generate_cardinal_forms(word, metadata)
      end

    Helpers.apply_overrides(forms, metadata)
  end

  # Infer numeral type from the term if not explicitly provided
  defp infer_numeral_type(word) do
    term = String.downcase(word.term)

    cond do
      # Check for ordinal patterns (ending in -i, -a, -o for adjective-like)
      String.ends_with?(term, "i") &&
          term in ~w(prvi drugi treći četvrti peti šesti sedmi osmi deveti deseti
                     jedanaesti dvanaesti trinaesti četrnaesti petnaesti šesnaesti
                     sedamnaesti osamnaesti devetnaesti) ->
        "ordinal"

      # Check for collective patterns
      String.ends_with?(term, "oje") || String.ends_with?(term, "oro") ->
        "collective"

      # Default to cardinal
      true ->
        "cardinal"
    end
  end

  # Generate forms for cardinal numerals
  defp generate_cardinal_forms(word, metadata) do
    term = String.downcase(word.term)
    numeral_value = metadata["numeral_value"] || infer_numeral_value(term)

    cond do
      numeral_value == 1 || term in ~w(jedan jedna jedno) ->
        generate_jedan_forms(word, metadata)

      numeral_value == 2 || term in ~w(dva dve dvije) ->
        generate_dva_forms(metadata)

      term in ~w(oba obe obje) ->
        generate_oba_forms(metadata)

      numeral_value == 3 || term == "tri" ->
        generate_tri_forms()

      numeral_value == 4 || term == "četiri" ->
        generate_cetiri_forms()

      true ->
        # 5+ are invariable
        [{term, "base"}]
    end
  end

  # Infer numeral value from term
  defp infer_numeral_value(term) do
    case term do
      t when t in ~w(jedan jedna jedno) -> 1
      t when t in ~w(dva dve dvije) -> 2
      "tri" -> 3
      "četiri" -> 4
      "pet" -> 5
      "šest" -> 6
      "sedam" -> 7
      "osam" -> 8
      "devet" -> 9
      "deset" -> 10
      _ -> nil
    end
  end

  # Generate forms for "jedan" (1) with full adjectival declension
  defp generate_jedan_forms(word, _metadata) do
    animate = word.animate == true

    @jedan_paradigm
    |> Enum.flat_map(fn {tag, form} ->
      cond do
        # Handle animate-dependent accusative
        tag == "acc_sg_m_anim" && animate ->
          [{form, "acc_sg_m"}]

        tag == "acc_sg_m" && animate ->
          []

        tag == "acc_sg_m_anim" && !animate ->
          []

        tag == "acc_sg_m" && !animate ->
          [{form, tag}]

        String.ends_with?(tag, "_anim") ->
          []

        true ->
          [{form, tag}]
      end
    end)
  end

  # Generate forms for "dva" (2) with gender and partial declension
  defp generate_dva_forms(_metadata) do
    @dva_paradigm
    |> Enum.map(fn {tag, form} -> {form, tag} end)
  end

  # Generate forms for "oba/obe" (both)
  defp generate_oba_forms(_metadata) do
    @oba_paradigm
    |> Enum.map(fn {tag, form} -> {form, tag} end)
  end

  # Generate forms for "tri" (3)
  defp generate_tri_forms do
    @tri_paradigm
    |> Enum.map(fn {tag, form} -> {form, tag} end)
  end

  # Generate forms for "četiri" (4)
  defp generate_cetiri_forms do
    @cetiri_paradigm
    |> Enum.map(fn {tag, form} -> {form, tag} end)
  end

  # Generate forms for ordinal numerals (decline like adjectives)
  defp generate_ordinal_forms(word, metadata) do
    term = String.downcase(word.term)
    stem = get_ordinal_stem(term)
    soft = soft_stem?(stem) || metadata["soft_stem"] == true

    # Generate definite declension forms (ordinals use only definite)
    for number <- @numbers,
        gender <- @genders,
        case_atom <- [:nom, :gen, :dat, :acc, :voc, :ins, :loc] do
      form_tag = "#{case_atom}_#{number}_#{gender}"
      form = build_ordinal_form(stem, word, case_atom, number, gender, soft)
      {form, form_tag}
    end
  end

  # Get the stem of an ordinal numeral (remove -i ending)
  defp get_ordinal_stem(term) do
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

  # Build a single ordinal form
  defp build_ordinal_form(stem, word, case_atom, number, gender, soft) do
    endings = if number == :sg, do: @def_sg_endings, else: @def_pl_endings
    ending = endings[gender][case_atom]

    case ending do
      :soft_dependent ->
        # Neuter nom/acc/voc: -o for hard stems, -e for soft stems
        stem <> if(soft, do: "e", else: "o")

      :soft_back_vowel ->
        # gen m/n: -og for hard, -eg for soft
        stem <> if(soft, do: "eg", else: "og")

      :soft_back_vowel_m ->
        # dat/loc m/n: -om for hard, -em for soft
        stem <> if(soft, do: "em", else: "om")

      :animate_dependent ->
        # Masculine accusative: depends on animacy and number
        resolve_masculine_accusative(stem, word, number, soft)

      ending when is_binary(ending) ->
        stem <> ending
    end
  end

  # Resolve masculine accusative based on animacy
  defp resolve_masculine_accusative(stem, word, number, soft) do
    animate = word.animate == true

    case {number, animate} do
      {:sg, true} ->
        # Animate singular: use genitive = stem + "og"/"eg"
        stem <> if(soft, do: "eg", else: "og")

      {:sg, false} ->
        # Inanimate singular: use nominative = stem + "i"
        stem <> "i"

      {:pl, _} ->
        # Plural: always "e"
        stem <> "e"
    end
  end

  # Generate forms for collective numerals
  defp generate_collective_forms(word, metadata) do
    term = String.downcase(word.term)

    case Map.get(@collective_paradigms, term) do
      nil ->
        # Unknown collective, try to generate based on pattern
        generate_generic_collective_forms(term, metadata)

      paradigm ->
        paradigm
        |> Enum.map(fn {tag, form} -> {form, tag} end)
    end
  end

  # Generate forms for unknown collective numerals based on typical pattern
  defp generate_generic_collective_forms(term, _metadata) do
    # Most collectives end in -oje or -oro
    # Just return base form if we can't determine the pattern
    [{term, "base"}]
  end
end
