defmodule Ohmyword.Linguistics.Pronouns do
  @moduledoc """
  Serbian pronoun inflector that generates all declined forms.

  Handles:
  - Personal pronouns (ja, ti, on, ona, ono, mi, vi, oni) with clitics
  - Reflexive pronoun (sebe)
  - Possessive pronouns (moj, tvoj, svoj, naš, vaš, njegov, njen, njihov)
  - Demonstrative pronouns (ovaj, taj, onaj)
  - Interrogative pronouns (ko, šta, koji, čiji)
  - Relative, indefinite, and negative pronouns

  Most pronouns are highly irregular and use hardcoded paradigms.
  Possessive and some demonstrative pronouns use adjective-like declension.
  """

  @behaviour Ohmyword.Linguistics.Inflector

  alias Ohmyword.Vocabulary.Word

  # Personal pronoun paradigms with full forms and clitics
  @personal_pronouns %{
    # 1st person singular
    "ja" => [
      {"ja", "nom_sg"},
      {"mene", "gen_sg"},
      {"me", "gen_sg_clitic"},
      {"meni", "dat_sg"},
      {"mi", "dat_sg_clitic"},
      {"mene", "acc_sg"},
      {"me", "acc_sg_clitic"},
      {"mnom", "ins_sg"},
      {"mnome", "ins_sg_alt"},
      {"meni", "loc_sg"}
    ],
    # 2nd person singular
    "ti" => [
      {"ti", "nom_sg"},
      {"tebe", "gen_sg"},
      {"te", "gen_sg_clitic"},
      {"tebi", "dat_sg"},
      {"ti", "dat_sg_clitic"},
      {"tebe", "acc_sg"},
      {"te", "acc_sg_clitic"},
      {"tobom", "ins_sg"},
      {"tebi", "loc_sg"},
      {"ti", "voc_sg"}
    ],
    # 3rd person singular masculine
    "on" => [
      {"on", "nom_sg"},
      {"njega", "gen_sg"},
      {"ga", "gen_sg_clitic"},
      {"njemu", "dat_sg"},
      {"mu", "dat_sg_clitic"},
      {"njega", "acc_sg"},
      {"ga", "acc_sg_clitic"},
      {"njim", "ins_sg"},
      {"njime", "ins_sg_alt"},
      {"njemu", "loc_sg"}
    ],
    # 3rd person singular feminine
    "ona" => [
      {"ona", "nom_sg"},
      {"nje", "gen_sg"},
      {"je", "gen_sg_clitic"},
      {"njoj", "dat_sg"},
      {"joj", "dat_sg_clitic"},
      {"nju", "acc_sg"},
      {"je", "acc_sg_clitic"},
      {"ju", "acc_sg_clitic_alt"},
      {"njom", "ins_sg"},
      {"njome", "ins_sg_alt"},
      {"njoj", "loc_sg"}
    ],
    # 3rd person singular neuter
    "ono" => [
      {"ono", "nom_sg"},
      {"njega", "gen_sg"},
      {"ga", "gen_sg_clitic"},
      {"njemu", "dat_sg"},
      {"mu", "dat_sg_clitic"},
      {"njega", "acc_sg"},
      {"ga", "acc_sg_clitic"},
      {"njim", "ins_sg"},
      {"njime", "ins_sg_alt"},
      {"njemu", "loc_sg"}
    ],
    # 1st person plural
    "mi" => [
      {"mi", "nom_pl"},
      {"nas", "gen_pl"},
      {"nas", "gen_pl_clitic"},
      {"nama", "dat_pl"},
      {"nam", "dat_pl_clitic"},
      {"nas", "acc_pl"},
      {"nas", "acc_pl_clitic"},
      {"nama", "ins_pl"},
      {"nama", "loc_pl"}
    ],
    # 2nd person plural / formal
    "vi" => [
      {"vi", "nom_pl"},
      {"vas", "gen_pl"},
      {"vas", "gen_pl_clitic"},
      {"vama", "dat_pl"},
      {"vam", "dat_pl_clitic"},
      {"vas", "acc_pl"},
      {"vas", "acc_pl_clitic"},
      {"vama", "ins_pl"},
      {"vama", "loc_pl"},
      {"vi", "voc_pl"}
    ],
    # 3rd person plural masculine
    "oni" => [
      {"oni", "nom_pl_m"},
      {"one", "nom_pl_f"},
      {"ona", "nom_pl_n"},
      {"njih", "gen_pl"},
      {"ih", "gen_pl_clitic"},
      {"njima", "dat_pl"},
      {"im", "dat_pl_clitic"},
      {"njih", "acc_pl"},
      {"ih", "acc_pl_clitic"},
      {"njima", "ins_pl"},
      {"njima", "loc_pl"}
    ],
    # 3rd person plural feminine (same oblique forms as oni)
    "one" => [
      {"one", "nom_pl"},
      {"njih", "gen_pl"},
      {"ih", "gen_pl_clitic"},
      {"njima", "dat_pl"},
      {"im", "dat_pl_clitic"},
      {"njih", "acc_pl"},
      {"ih", "acc_pl_clitic"},
      {"njima", "ins_pl"},
      {"njima", "loc_pl"}
    ],
    # 3rd person plural neuter (same oblique forms as oni)
    # Note: "ona" as 3rd plural neuter is different from "ona" as 3rd sg feminine
    "ona_pl" => [
      {"ona", "nom_pl"},
      {"njih", "gen_pl"},
      {"ih", "gen_pl_clitic"},
      {"njima", "dat_pl"},
      {"im", "dat_pl_clitic"},
      {"njih", "acc_pl"},
      {"ih", "acc_pl_clitic"},
      {"njima", "ins_pl"},
      {"njima", "loc_pl"}
    ]
  }

  # Reflexive pronoun (no nominative, no number distinction)
  @reflexive_pronoun %{
    "sebe" => [
      {"sebe", "gen_sg"},
      {"se", "gen_sg_clitic"},
      {"sebi", "dat_sg"},
      {"si", "dat_sg_clitic"},
      {"sebe", "acc_sg"},
      {"se", "acc_sg_clitic"},
      {"sobom", "ins_sg"},
      {"sebi", "loc_sg"}
    ]
  }

  # Interrogative pronouns
  @interrogative_pronouns %{
    "ko" => [
      {"ko", "nom_sg"},
      {"koga", "gen_sg"},
      {"kome", "dat_sg"},
      {"komu", "dat_sg_alt"},
      {"koga", "acc_sg"},
      {"kim", "ins_sg"},
      {"kime", "ins_sg_alt"},
      {"kome", "loc_sg"},
      {"komu", "loc_sg_alt"}
    ],
    "šta" => [
      {"šta", "nom_sg"},
      {"čega", "gen_sg"},
      {"čemu", "dat_sg"},
      {"šta", "acc_sg"},
      {"čim", "ins_sg"},
      {"čime", "ins_sg_alt"},
      {"čemu", "loc_sg"}
    ],
    # ASCII variant of "šta"
    "sta" => [
      {"sta", "nom_sg"},
      {"cega", "gen_sg"},
      {"cemu", "dat_sg"},
      {"sta", "acc_sg"},
      {"cim", "ins_sg"},
      {"cime", "ins_sg_alt"},
      {"cemu", "loc_sg"}
    ],
    # "što" variant of "šta"
    "što" => [
      {"što", "nom_sg"},
      {"čega", "gen_sg"},
      {"čemu", "dat_sg"},
      {"što", "acc_sg"},
      {"čim", "ins_sg"},
      {"čime", "ins_sg_alt"},
      {"čemu", "loc_sg"}
    ]
  }

  # Hardcoded possessive pronoun paradigms for irregular forms (moj, tvoj, svoj)
  # These have contracted forms like "mog" instead of "mojog"
  @possessive_paradigms %{
    "moj" => [
      # Singular masculine
      {"moj", "nom_sg_m"},
      {"mog", "gen_sg_m"},
      {"moga", "gen_sg_m_alt"},
      {"mom", "dat_sg_m"},
      {"mome", "dat_sg_m_alt"},
      {"momu", "dat_sg_m_alt2"},
      {"moj", "acc_sg_m"},
      {"mog", "acc_sg_m_anim"},
      {"moj", "voc_sg_m"},
      {"mojim", "ins_sg_m"},
      {"mom", "loc_sg_m"},
      {"mome", "loc_sg_m_alt"},
      {"momu", "loc_sg_m_alt2"},
      # Singular feminine
      {"moja", "nom_sg_f"},
      {"moje", "gen_sg_f"},
      {"mojoj", "dat_sg_f"},
      {"moju", "acc_sg_f"},
      {"moja", "voc_sg_f"},
      {"mojom", "ins_sg_f"},
      {"mojoj", "loc_sg_f"},
      # Singular neuter
      {"moje", "nom_sg_n"},
      {"mog", "gen_sg_n"},
      {"moga", "gen_sg_n_alt"},
      {"mom", "dat_sg_n"},
      {"mome", "dat_sg_n_alt"},
      {"momu", "dat_sg_n_alt2"},
      {"moje", "acc_sg_n"},
      {"moje", "voc_sg_n"},
      {"mojim", "ins_sg_n"},
      {"mom", "loc_sg_n"},
      {"mome", "loc_sg_n_alt"},
      {"momu", "loc_sg_n_alt2"},
      # Plural masculine
      {"moji", "nom_pl_m"},
      {"mojih", "gen_pl_m"},
      {"mojim", "dat_pl_m"},
      {"mojima", "dat_pl_m_alt"},
      {"moje", "acc_pl_m"},
      {"moji", "voc_pl_m"},
      {"mojim", "ins_pl_m"},
      {"mojima", "ins_pl_m_alt"},
      {"mojim", "loc_pl_m"},
      {"mojima", "loc_pl_m_alt"},
      # Plural feminine
      {"moje", "nom_pl_f"},
      {"mojih", "gen_pl_f"},
      {"mojim", "dat_pl_f"},
      {"mojima", "dat_pl_f_alt"},
      {"moje", "acc_pl_f"},
      {"moje", "voc_pl_f"},
      {"mojim", "ins_pl_f"},
      {"mojima", "ins_pl_f_alt"},
      {"mojim", "loc_pl_f"},
      {"mojima", "loc_pl_f_alt"},
      # Plural neuter
      {"moja", "nom_pl_n"},
      {"mojih", "gen_pl_n"},
      {"mojim", "dat_pl_n"},
      {"mojima", "dat_pl_n_alt"},
      {"moja", "acc_pl_n"},
      {"moja", "voc_pl_n"},
      {"mojim", "ins_pl_n"},
      {"mojima", "ins_pl_n_alt"},
      {"mojim", "loc_pl_n"},
      {"mojima", "loc_pl_n_alt"}
    ],
    "tvoj" => [
      # Singular masculine
      {"tvoj", "nom_sg_m"},
      {"tvog", "gen_sg_m"},
      {"tvoga", "gen_sg_m_alt"},
      {"tvom", "dat_sg_m"},
      {"tvome", "dat_sg_m_alt"},
      {"tvomu", "dat_sg_m_alt2"},
      {"tvoj", "acc_sg_m"},
      {"tvog", "acc_sg_m_anim"},
      {"tvoj", "voc_sg_m"},
      {"tvojim", "ins_sg_m"},
      {"tvom", "loc_sg_m"},
      {"tvome", "loc_sg_m_alt"},
      {"tvomu", "loc_sg_m_alt2"},
      # Singular feminine
      {"tvoja", "nom_sg_f"},
      {"tvoje", "gen_sg_f"},
      {"tvojoj", "dat_sg_f"},
      {"tvoju", "acc_sg_f"},
      {"tvoja", "voc_sg_f"},
      {"tvojom", "ins_sg_f"},
      {"tvojoj", "loc_sg_f"},
      # Singular neuter
      {"tvoje", "nom_sg_n"},
      {"tvog", "gen_sg_n"},
      {"tvoga", "gen_sg_n_alt"},
      {"tvom", "dat_sg_n"},
      {"tvome", "dat_sg_n_alt"},
      {"tvomu", "dat_sg_n_alt2"},
      {"tvoje", "acc_sg_n"},
      {"tvoje", "voc_sg_n"},
      {"tvojim", "ins_sg_n"},
      {"tvom", "loc_sg_n"},
      {"tvome", "loc_sg_n_alt"},
      {"tvomu", "loc_sg_n_alt2"},
      # Plural masculine
      {"tvoji", "nom_pl_m"},
      {"tvojih", "gen_pl_m"},
      {"tvojim", "dat_pl_m"},
      {"tvojima", "dat_pl_m_alt"},
      {"tvoje", "acc_pl_m"},
      {"tvoji", "voc_pl_m"},
      {"tvojim", "ins_pl_m"},
      {"tvojima", "ins_pl_m_alt"},
      {"tvojim", "loc_pl_m"},
      {"tvojima", "loc_pl_m_alt"},
      # Plural feminine
      {"tvoje", "nom_pl_f"},
      {"tvojih", "gen_pl_f"},
      {"tvojim", "dat_pl_f"},
      {"tvojima", "dat_pl_f_alt"},
      {"tvoje", "acc_pl_f"},
      {"tvoje", "voc_pl_f"},
      {"tvojim", "ins_pl_f"},
      {"tvojima", "ins_pl_f_alt"},
      {"tvojim", "loc_pl_f"},
      {"tvojima", "loc_pl_f_alt"},
      # Plural neuter
      {"tvoja", "nom_pl_n"},
      {"tvojih", "gen_pl_n"},
      {"tvojim", "dat_pl_n"},
      {"tvojima", "dat_pl_n_alt"},
      {"tvoja", "acc_pl_n"},
      {"tvoja", "voc_pl_n"},
      {"tvojim", "ins_pl_n"},
      {"tvojima", "ins_pl_n_alt"},
      {"tvojim", "loc_pl_n"},
      {"tvojima", "loc_pl_n_alt"}
    ],
    "svoj" => [
      # Singular masculine
      {"svoj", "nom_sg_m"},
      {"svog", "gen_sg_m"},
      {"svoga", "gen_sg_m_alt"},
      {"svom", "dat_sg_m"},
      {"svome", "dat_sg_m_alt"},
      {"svomu", "dat_sg_m_alt2"},
      {"svoj", "acc_sg_m"},
      {"svog", "acc_sg_m_anim"},
      {"svoj", "voc_sg_m"},
      {"svojim", "ins_sg_m"},
      {"svom", "loc_sg_m"},
      {"svome", "loc_sg_m_alt"},
      {"svomu", "loc_sg_m_alt2"},
      # Singular feminine
      {"svoja", "nom_sg_f"},
      {"svoje", "gen_sg_f"},
      {"svojoj", "dat_sg_f"},
      {"svoju", "acc_sg_f"},
      {"svoja", "voc_sg_f"},
      {"svojom", "ins_sg_f"},
      {"svojoj", "loc_sg_f"},
      # Singular neuter
      {"svoje", "nom_sg_n"},
      {"svog", "gen_sg_n"},
      {"svoga", "gen_sg_n_alt"},
      {"svom", "dat_sg_n"},
      {"svome", "dat_sg_n_alt"},
      {"svomu", "dat_sg_n_alt2"},
      {"svoje", "acc_sg_n"},
      {"svoje", "voc_sg_n"},
      {"svojim", "ins_sg_n"},
      {"svom", "loc_sg_n"},
      {"svome", "loc_sg_n_alt"},
      {"svomu", "loc_sg_n_alt2"},
      # Plural masculine
      {"svoji", "nom_pl_m"},
      {"svojih", "gen_pl_m"},
      {"svojim", "dat_pl_m"},
      {"svojima", "dat_pl_m_alt"},
      {"svoje", "acc_pl_m"},
      {"svoji", "voc_pl_m"},
      {"svojim", "ins_pl_m"},
      {"svojima", "ins_pl_m_alt"},
      {"svojim", "loc_pl_m"},
      {"svojima", "loc_pl_m_alt"},
      # Plural feminine
      {"svoje", "nom_pl_f"},
      {"svojih", "gen_pl_f"},
      {"svojim", "dat_pl_f"},
      {"svojima", "dat_pl_f_alt"},
      {"svoje", "acc_pl_f"},
      {"svoje", "voc_pl_f"},
      {"svojim", "ins_pl_f"},
      {"svojima", "ins_pl_f_alt"},
      {"svojim", "loc_pl_f"},
      {"svojima", "loc_pl_f_alt"},
      # Plural neuter
      {"svoja", "nom_pl_n"},
      {"svojih", "gen_pl_n"},
      {"svojim", "dat_pl_n"},
      {"svojima", "dat_pl_n_alt"},
      {"svoja", "acc_pl_n"},
      {"svoja", "voc_pl_n"},
      {"svojim", "ins_pl_n"},
      {"svojima", "ins_pl_n_alt"},
      {"svojim", "loc_pl_n"},
      {"svojima", "loc_pl_n_alt"}
    ]
  }

  # Regular possessive pronoun stems (naš, vaš, njegov, etc.) for adjective-like declension
  @possessive_stems %{
    "naš" => "naš",
    "vaš" => "vaš",
    "njegov" => "njegov",
    "njen" => "njen",
    "njezin" => "njezin",
    "njihov" => "njihov"
  }

  # Demonstrative pronoun stems
  @demonstrative_stems %{
    "ovaj" => "ov",
    "taj" => "t",
    "onaj" => "on"
  }

  # Cases for adjective-like declension
  @cases [:nom, :gen, :dat, :acc, :voc, :ins, :loc]
  @genders [:m, :f, :n]
  @numbers [:sg, :pl]

  # Possessive/demonstrative singular endings
  @poss_sg_endings %{
    m: %{
      nom: :special,
      gen: "og",
      dat: "om",
      acc: :animate_dependent,
      voc: :special,
      ins: "im",
      loc: "om"
    },
    f: %{nom: "a", gen: "e", dat: "oj", acc: "u", voc: "a", ins: "om", loc: "oj"},
    n: %{nom: "e", gen: "og", dat: "om", acc: "e", voc: "e", ins: "im", loc: "om"}
  }

  # Possessive/demonstrative plural endings
  @poss_pl_endings %{
    m: %{nom: "i", gen: "ih", dat: "im", acc: "e", voc: "i", ins: "im", loc: "im"},
    f: %{nom: "e", gen: "ih", dat: "im", acc: "e", voc: "e", ins: "im", loc: "im"},
    n: %{nom: "a", gen: "ih", dat: "im", acc: "a", voc: "a", ins: "im", loc: "im"}
  }

  # Special demonstrative singular endings (ovaj/taj/onaj)
  @demo_sg_endings %{
    m: %{
      nom: "aj",
      gen: "og",
      dat: "om",
      acc: :animate_dependent,
      voc: "aj",
      ins: "im",
      loc: "om"
    },
    f: %{nom: "a", gen: "e", dat: "oj", acc: "u", voc: "a", ins: "om", loc: "oj"},
    n: %{nom: "o", gen: "og", dat: "om", acc: "o", voc: "o", ins: "im", loc: "om"}
  }

  @impl true
  def applicable?(%Word{part_of_speech: :pronoun}), do: true
  def applicable?(_), do: false

  @impl true
  def generate_forms(%Word{} = word) do
    metadata = word.grammar_metadata || %{}
    term = String.downcase(word.term)
    pronoun_type = metadata["pronoun_type"]

    cond do
      # Manual forms only - use hardcoded paradigms
      metadata["manual_forms_only"] == true ->
        lookup_manual_forms(term)

      # Personal pronouns
      pronoun_type == "personal" ->
        lookup_personal_pronoun(term)

      # Reflexive pronoun
      pronoun_type == "reflexive" ->
        lookup_reflexive_pronoun(term)

      # Possessive pronouns - adjective-like declension
      pronoun_type == "possessive" ->
        generate_possessive_forms(term, word)

      # Demonstrative pronouns
      pronoun_type == "demonstrative" ->
        generate_demonstrative_forms(term, word)

      # Interrogative pronouns
      pronoun_type == "interrogative" ->
        generate_interrogative_forms(term, word)

      # Relative pronouns - usually same as interrogative/adjective-like
      pronoun_type == "relative" ->
        generate_relative_forms(term, word)

      # Indefinite pronouns (neko, nešto, neki)
      pronoun_type == "indefinite" ->
        generate_indefinite_forms(term, word)

      # Negative pronouns (niko, ništa)
      pronoun_type == "negative" ->
        generate_negative_forms(term, word)

      # Default: try to detect from term
      true ->
        detect_and_generate(term, word)
    end
  end

  # Look up forms in all hardcoded paradigm tables
  defp lookup_manual_forms(term) do
    cond do
      Map.has_key?(@personal_pronouns, term) -> @personal_pronouns[term]
      Map.has_key?(@reflexive_pronoun, term) -> @reflexive_pronoun[term]
      Map.has_key?(@interrogative_pronouns, term) -> @interrogative_pronouns[term]
      Map.has_key?(@possessive_paradigms, term) -> @possessive_paradigms[term]
      true -> []
    end
  end

  defp lookup_personal_pronoun(term) do
    Map.get(@personal_pronouns, term, [])
  end

  defp lookup_reflexive_pronoun(term) do
    Map.get(@reflexive_pronoun, term, [])
  end

  # Generate possessive pronoun forms (adjective-like)
  defp generate_possessive_forms(term, word) do
    # Check for hardcoded paradigms first (moj, tvoj, svoj have contracted forms)
    case Map.get(@possessive_paradigms, term) do
      nil ->
        # Use regular adjective-like declension for naš, vaš, njegov, etc.
        stem = Map.get(@possessive_stems, term, term)
        soft = soft_stem?(stem)

        for number <- @numbers,
            gender <- @genders,
            case_atom <- @cases do
          form_tag = "#{case_atom}_#{number}_#{gender}"
          form = build_possessive_form(stem, term, case_atom, number, gender, word, soft)
          {form, form_tag}
        end

      paradigm ->
        paradigm
    end
  end

  defp build_possessive_form(stem, term, case_atom, number, gender, word, _soft) do
    endings = if number == :sg, do: @poss_sg_endings, else: @poss_pl_endings
    ending = endings[gender][case_atom]

    case ending do
      :special ->
        # Masculine nominative/vocative singular: use full term
        term

      :animate_dependent ->
        # Masculine accusative: depends on animacy
        animate = word.animate == true

        if number == :sg do
          if animate, do: stem <> "og", else: term
        else
          stem <> "e"
        end

      ending when is_binary(ending) ->
        stem <> ending
    end
  end

  # Generate demonstrative pronoun forms
  defp generate_demonstrative_forms(term, word) do
    stem = Map.get(@demonstrative_stems, term)

    if stem do
      for number <- @numbers,
          gender <- @genders,
          case_atom <- @cases do
        form_tag = "#{case_atom}_#{number}_#{gender}"
        form = build_demonstrative_form(stem, case_atom, number, gender, word)
        {form, form_tag}
      end
    else
      # Unknown demonstrative, return empty
      []
    end
  end

  defp build_demonstrative_form(stem, case_atom, number, gender, word) do
    endings = if number == :sg, do: @demo_sg_endings, else: @poss_pl_endings
    ending = endings[gender][case_atom]

    case ending do
      :animate_dependent ->
        animate = word.animate == true

        if number == :sg do
          if animate, do: stem <> "og", else: stem <> "aj"
        else
          stem <> "e"
        end

      ending when is_binary(ending) ->
        stem <> ending
    end
  end

  # Generate interrogative pronoun forms
  defp generate_interrogative_forms(term, word) do
    cond do
      # ko, šta, što - use hardcoded
      Map.has_key?(@interrogative_pronouns, term) ->
        @interrogative_pronouns[term]

      # koji, čiji - adjective-like
      term in ["koji", "čiji", "kakav"] ->
        generate_adjective_like_interrogative(term, word)

      true ->
        []
    end
  end

  # Generate adjective-like interrogative forms (koji, čiji, kakav)
  defp generate_adjective_like_interrogative(term, word) do
    {stem, soft} =
      case term do
        "koji" -> {"koj", true}
        "čiji" -> {"čij", true}
        "kakav" -> {"kakv", false}
        _ -> {term, false}
      end

    for number <- @numbers,
        gender <- @genders,
        case_atom <- @cases do
      form_tag = "#{case_atom}_#{number}_#{gender}"
      form = build_interrogative_adjective_form(stem, term, case_atom, number, gender, word, soft)
      {form, form_tag}
    end
  end

  defp build_interrogative_adjective_form(stem, term, case_atom, number, gender, word, soft) do
    # Use similar endings to possessive but with soft stem handling
    endings = if number == :sg, do: @poss_sg_endings, else: @poss_pl_endings
    ending = endings[gender][case_atom]

    case ending do
      :special ->
        # Masculine nominative singular
        if soft, do: stem <> "i", else: term

      :animate_dependent ->
        animate = word.animate == true

        if number == :sg do
          if animate, do: stem <> "eg", else: stem <> "i"
        else
          stem <> "e"
        end

      ending when is_binary(ending) ->
        # Soft stems use -eg instead of -og for genitive
        actual_ending =
          if soft and ending in ["og", "om"] do
            String.replace(ending, "o", "e")
          else
            ending
          end

        stem <> actual_ending
    end
  end

  # Generate relative pronoun forms (same as interrogative for koji/čiji)
  defp generate_relative_forms(term, word) do
    generate_interrogative_forms(term, word)
  end

  # Generate indefinite pronoun forms (neko, nešto, neki)
  defp generate_indefinite_forms(term, word) do
    cond do
      term == "neko" ->
        # Derived from "ko"
        @interrogative_pronouns["ko"]
        |> Enum.map(fn {form, tag} -> {"ne" <> form, tag} end)

      term == "nešto" ->
        # Derived from "šta/što"
        @interrogative_pronouns["šta"]
        |> Enum.map(fn {form, tag} ->
          new_form =
            case form do
              "šta" -> "nešto"
              "čega" -> "nečega"
              "čemu" -> "nečemu"
              "čim" -> "nečim"
              "čime" -> "nečime"
              _ -> "ne" <> form
            end

          {new_form, tag}
        end)

      term == "neki" ->
        # Adjective-like (like "koji")
        generate_adjective_like_interrogative("neki", word)
        |> Enum.map(fn {form, tag} ->
          # Fix the stem for "neki"
          new_form = String.replace(form, ~r/^nek/, "nek")
          {new_form, tag}
        end)

      true ->
        []
    end
  end

  # Generate negative pronoun forms (niko, ništa)
  defp generate_negative_forms(term, _word) do
    cond do
      term == "niko" ->
        # Derived from "ko"
        @interrogative_pronouns["ko"]
        |> Enum.map(fn {form, tag} ->
          new_form =
            case form do
              "ko" -> "niko"
              "koga" -> "nikoga"
              "kome" -> "nikome"
              "komu" -> "nikomu"
              "kim" -> "nikim"
              "kime" -> "nikime"
              _ -> "ni" <> form
            end

          {new_form, tag}
        end)

      term == "ništa" ->
        # Derived from "šta"
        @interrogative_pronouns["šta"]
        |> Enum.map(fn {form, tag} ->
          new_form =
            case form do
              "šta" -> "ništa"
              "čega" -> "ničega"
              "čemu" -> "ničemu"
              "čim" -> "ničim"
              "čime" -> "ničime"
              _ -> "ni" <> form
            end

          {new_form, tag}
        end)

      true ->
        []
    end
  end

  # Try to detect pronoun type from the term
  defp detect_and_generate(term, word) do
    cond do
      Map.has_key?(@personal_pronouns, term) ->
        @personal_pronouns[term]

      Map.has_key?(@reflexive_pronoun, term) ->
        @reflexive_pronoun[term]

      Map.has_key?(@interrogative_pronouns, term) ->
        @interrogative_pronouns[term]

      Map.has_key?(@possessive_paradigms, term) ->
        @possessive_paradigms[term]

      Map.has_key?(@possessive_stems, term) ->
        generate_possessive_forms(term, word)

      Map.has_key?(@demonstrative_stems, term) ->
        generate_demonstrative_forms(term, word)

      true ->
        # Unknown pronoun, return empty
        []
    end
  end

  # Check if stem ends with a soft consonant
  defp soft_stem?(stem) do
    soft_consonants = ~w(č ć š ž đ j)
    soft_digraphs = ~w(lj nj dž)

    last_two = String.slice(stem, -2..-1//1)
    last_one = String.last(stem)

    last_two in soft_digraphs || last_one in soft_consonants
  end
end
