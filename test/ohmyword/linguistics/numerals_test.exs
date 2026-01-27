defmodule Ohmyword.Linguistics.NumeralsTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Linguistics.Numerals
  alias Ohmyword.Vocabulary.Word

  describe "applicable?/1" do
    test "returns true for numerals" do
      word = %Word{term: "jedan", part_of_speech: :numeral}
      assert Numerals.applicable?(word)
    end

    test "returns false for nouns" do
      word = %Word{term: "kuća", part_of_speech: :noun, gender: :feminine}
      refute Numerals.applicable?(word)
    end

    test "returns false for verbs" do
      word = %Word{term: "raditi", part_of_speech: :verb}
      refute Numerals.applicable?(word)
    end

    test "returns false for adjectives" do
      word = %Word{term: "dobar", part_of_speech: :adjective}
      refute Numerals.applicable?(word)
    end
  end

  describe "generate_forms/1 - jedan (1) cardinal" do
    setup do
      word = %Word{
        term: "jedan",
        part_of_speech: :numeral,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "numeral_type" => "cardinal",
          "numeral_value" => 1,
          "gender_forms" => true,
          "declines" => true
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates expected number of forms (7 cases x 3 genders - vocative)", %{forms: forms} do
      # 18 forms: 6 cases (no vocative) x 3 genders
      assert length(forms) == 18
    end

    test "nominative singular masculine", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "jedan"
    end

    test "nominative singular feminine", %{forms_map: fm} do
      assert fm["nom_sg_f"] == "jedna"
    end

    test "nominative singular neuter", %{forms_map: fm} do
      assert fm["nom_sg_n"] == "jedno"
    end

    test "genitive singular masculine", %{forms_map: fm} do
      assert fm["gen_sg_m"] == "jednog"
    end

    test "genitive singular feminine", %{forms_map: fm} do
      assert fm["gen_sg_f"] == "jedne"
    end

    test "genitive singular neuter", %{forms_map: fm} do
      assert fm["gen_sg_n"] == "jednog"
    end

    test "dative singular masculine", %{forms_map: fm} do
      assert fm["dat_sg_m"] == "jednom"
    end

    test "dative singular feminine", %{forms_map: fm} do
      assert fm["dat_sg_f"] == "jednoj"
    end

    test "accusative singular masculine (inanimate)", %{forms_map: fm} do
      assert fm["acc_sg_m"] == "jedan"
    end

    test "accusative singular feminine", %{forms_map: fm} do
      assert fm["acc_sg_f"] == "jednu"
    end

    test "accusative singular neuter", %{forms_map: fm} do
      assert fm["acc_sg_n"] == "jedno"
    end

    test "instrumental singular masculine", %{forms_map: fm} do
      assert fm["ins_sg_m"] == "jednim"
    end

    test "instrumental singular feminine", %{forms_map: fm} do
      assert fm["ins_sg_f"] == "jednom"
    end

    test "locative singular masculine", %{forms_map: fm} do
      assert fm["loc_sg_m"] == "jednom"
    end

    test "locative singular feminine", %{forms_map: fm} do
      assert fm["loc_sg_f"] == "jednoj"
    end
  end

  describe "generate_forms/1 - jedan (1) with animate" do
    setup do
      word = %Word{
        term: "jedan",
        part_of_speech: :numeral,
        gender: :masculine,
        animate: true,
        grammar_metadata: %{
          "numeral_type" => "cardinal",
          "numeral_value" => 1
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "accusative singular masculine (animate) uses genitive form", %{forms_map: fm} do
      assert fm["acc_sg_m"] == "jednog"
    end
  end

  describe "generate_forms/1 - dva (2) cardinal" do
    setup do
      word = %Word{
        term: "dva",
        part_of_speech: :numeral,
        gender: :masculine,
        grammar_metadata: %{
          "numeral_type" => "cardinal",
          "numeral_value" => 2,
          "gender_forms" => true,
          "declines" => true
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 12 forms (6 cases x 2 genders)", %{forms: forms} do
      assert length(forms) == 12
    end

    test "nominative masculine", %{forms_map: fm} do
      assert fm["nom_m"] == "dva"
    end

    test "nominative feminine", %{forms_map: fm} do
      assert fm["nom_f"] == "dve"
    end

    test "genitive masculine", %{forms_map: fm} do
      assert fm["gen_m"] == "dvaju"
    end

    test "genitive feminine", %{forms_map: fm} do
      assert fm["gen_f"] == "dveju"
    end

    test "dative masculine", %{forms_map: fm} do
      assert fm["dat_m"] == "dvama"
    end

    test "dative feminine", %{forms_map: fm} do
      assert fm["dat_f"] == "dvema"
    end

    test "accusative masculine", %{forms_map: fm} do
      assert fm["acc_m"] == "dva"
    end

    test "accusative feminine", %{forms_map: fm} do
      assert fm["acc_f"] == "dve"
    end

    test "instrumental masculine", %{forms_map: fm} do
      assert fm["ins_m"] == "dvama"
    end

    test "instrumental feminine", %{forms_map: fm} do
      assert fm["ins_f"] == "dvema"
    end

    test "locative masculine", %{forms_map: fm} do
      assert fm["loc_m"] == "dvama"
    end

    test "locative feminine", %{forms_map: fm} do
      assert fm["loc_f"] == "dvema"
    end
  end

  describe "generate_forms/1 - tri (3) cardinal" do
    setup do
      word = %Word{
        term: "tri",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "cardinal",
          "numeral_value" => 3,
          "gender_forms" => false,
          "declines" => true
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 6 forms (case only, no gender)", %{forms: forms} do
      assert length(forms) == 6
    end

    test "nominative", %{forms_map: fm} do
      assert fm["nom"] == "tri"
    end

    test "genitive", %{forms_map: fm} do
      assert fm["gen"] == "triju"
    end

    test "dative", %{forms_map: fm} do
      assert fm["dat"] == "trima"
    end

    test "accusative", %{forms_map: fm} do
      assert fm["acc"] == "tri"
    end

    test "instrumental", %{forms_map: fm} do
      assert fm["ins"] == "trima"
    end

    test "locative", %{forms_map: fm} do
      assert fm["loc"] == "trima"
    end
  end

  describe "generate_forms/1 - četiri (4) cardinal" do
    setup do
      word = %Word{
        term: "četiri",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "cardinal",
          "numeral_value" => 4,
          "gender_forms" => false,
          "declines" => true
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 6 forms (case only)", %{forms: forms} do
      assert length(forms) == 6
    end

    test "nominative", %{forms_map: fm} do
      assert fm["nom"] == "četiri"
    end

    test "genitive", %{forms_map: fm} do
      assert fm["gen"] == "četiriju"
    end

    test "dative", %{forms_map: fm} do
      assert fm["dat"] == "četirima"
    end

    test "accusative", %{forms_map: fm} do
      assert fm["acc"] == "četiri"
    end

    test "instrumental", %{forms_map: fm} do
      assert fm["ins"] == "četirima"
    end

    test "locative", %{forms_map: fm} do
      assert fm["loc"] == "četirima"
    end
  end

  describe "generate_forms/1 - pet (5) cardinal - invariable" do
    setup do
      word = %Word{
        term: "pet",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "cardinal",
          "numeral_value" => 5,
          "declines" => false
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "returns only base form", %{forms: forms} do
      assert length(forms) == 1
    end

    test "base form is correct", %{forms_map: fm} do
      assert fm["base"] == "pet"
    end
  end

  describe "generate_forms/1 - higher invariable cardinals" do
    test "šest returns only base form" do
      word = %Word{
        term: "šest",
        part_of_speech: :numeral,
        grammar_metadata: %{"numeral_type" => "cardinal", "numeral_value" => 6}
      }

      forms = Numerals.generate_forms(word)
      assert forms == [{"šest", "base"}]
    end

    test "deset returns only base form" do
      word = %Word{
        term: "deset",
        part_of_speech: :numeral,
        grammar_metadata: %{"numeral_type" => "cardinal", "numeral_value" => 10}
      }

      forms = Numerals.generate_forms(word)
      assert forms == [{"deset", "base"}]
    end

    test "dvadeset returns only base form" do
      word = %Word{
        term: "dvadeset",
        part_of_speech: :numeral,
        grammar_metadata: %{"numeral_type" => "cardinal", "numeral_value" => 20}
      }

      forms = Numerals.generate_forms(word)
      assert forms == [{"dvadeset", "base"}]
    end
  end

  describe "generate_forms/1 - prvi (1st) ordinal" do
    setup do
      word = %Word{
        term: "prvi",
        part_of_speech: :numeral,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "numeral_type" => "ordinal",
          "numeral_value" => 1
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 42 forms (7 cases x 2 numbers x 3 genders)", %{forms: forms} do
      assert length(forms) == 42
    end

    test "nominative singular masculine", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "prvi"
    end

    test "nominative singular feminine", %{forms_map: fm} do
      assert fm["nom_sg_f"] == "prva"
    end

    test "nominative singular neuter (hard stem)", %{forms_map: fm} do
      assert fm["nom_sg_n"] == "prvo"
    end

    test "genitive singular masculine", %{forms_map: fm} do
      assert fm["gen_sg_m"] == "prvog"
    end

    test "genitive singular feminine", %{forms_map: fm} do
      assert fm["gen_sg_f"] == "prve"
    end

    test "dative singular masculine", %{forms_map: fm} do
      assert fm["dat_sg_m"] == "prvom"
    end

    test "dative singular feminine", %{forms_map: fm} do
      assert fm["dat_sg_f"] == "prvoj"
    end

    test "accusative singular masculine (inanimate)", %{forms_map: fm} do
      assert fm["acc_sg_m"] == "prvi"
    end

    test "accusative singular feminine", %{forms_map: fm} do
      assert fm["acc_sg_f"] == "prvu"
    end

    test "instrumental singular masculine", %{forms_map: fm} do
      assert fm["ins_sg_m"] == "prvim"
    end

    test "locative singular masculine", %{forms_map: fm} do
      assert fm["loc_sg_m"] == "prvom"
    end

    test "nominative plural masculine", %{forms_map: fm} do
      assert fm["nom_pl_m"] == "prvi"
    end

    test "nominative plural feminine", %{forms_map: fm} do
      assert fm["nom_pl_f"] == "prve"
    end

    test "nominative plural neuter", %{forms_map: fm} do
      assert fm["nom_pl_n"] == "prva"
    end

    test "genitive plural masculine", %{forms_map: fm} do
      assert fm["gen_pl_m"] == "prvih"
    end
  end

  describe "generate_forms/1 - treći (3rd) ordinal with soft stem" do
    setup do
      word = %Word{
        term: "treći",
        part_of_speech: :numeral,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "numeral_type" => "ordinal",
          "numeral_value" => 3,
          "soft_stem" => true
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 42 forms", %{forms: forms} do
      assert length(forms) == 42
    end

    test "nominative singular masculine", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "treći"
    end

    test "nominative singular feminine", %{forms_map: fm} do
      assert fm["nom_sg_f"] == "treća"
    end

    test "nominative singular neuter uses -e for soft stem", %{forms_map: fm} do
      assert fm["nom_sg_n"] == "treće"
    end

    test "accusative singular neuter uses -e for soft stem", %{forms_map: fm} do
      assert fm["acc_sg_n"] == "treće"
    end

    test "vocative singular neuter uses -e for soft stem", %{forms_map: fm} do
      assert fm["voc_sg_n"] == "treće"
    end
  end

  describe "generate_forms/1 - ordinal with animate masculine" do
    setup do
      word = %Word{
        term: "prvi",
        part_of_speech: :numeral,
        gender: :masculine,
        animate: true,
        grammar_metadata: %{
          "numeral_type" => "ordinal",
          "numeral_value" => 1
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "accusative singular masculine (animate) uses genitive form", %{forms_map: fm} do
      assert fm["acc_sg_m"] == "prvog"
    end

    test "accusative plural masculine still uses -e", %{forms_map: fm} do
      assert fm["acc_pl_m"] == "prve"
    end
  end

  describe "generate_forms/1 - dvoje collective" do
    setup do
      word = %Word{
        term: "dvoje",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "collective",
          "numeral_value" => 2,
          "declines" => true
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 6 forms", %{forms: forms} do
      assert length(forms) == 6
    end

    test "nominative", %{forms_map: fm} do
      assert fm["nom"] == "dvoje"
    end

    test "genitive", %{forms_map: fm} do
      assert fm["gen"] == "dvoga"
    end

    test "dative", %{forms_map: fm} do
      assert fm["dat"] == "dvoma"
    end

    test "accusative", %{forms_map: fm} do
      assert fm["acc"] == "dvoje"
    end

    test "instrumental", %{forms_map: fm} do
      assert fm["ins"] == "dvoma"
    end

    test "locative", %{forms_map: fm} do
      assert fm["loc"] == "dvoma"
    end
  end

  describe "generate_forms/1 - troje collective" do
    setup do
      word = %Word{
        term: "troje",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "collective",
          "numeral_value" => 3
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 6 forms", %{forms: forms} do
      assert length(forms) == 6
    end

    test "nominative", %{forms_map: fm} do
      assert fm["nom"] == "troje"
    end

    test "genitive", %{forms_map: fm} do
      assert fm["gen"] == "troga"
    end

    test "dative", %{forms_map: fm} do
      assert fm["dat"] == "troma"
    end
  end

  describe "generate_forms/1 - četvoro collective" do
    setup do
      word = %Word{
        term: "četvoro",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "collective",
          "numeral_value" => 4
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 6 forms", %{forms: forms} do
      assert length(forms) == 6
    end

    test "nominative", %{forms_map: fm} do
      assert fm["nom"] == "četvoro"
    end

    test "genitive", %{forms_map: fm} do
      assert fm["gen"] == "četvorga"
    end

    test "dative", %{forms_map: fm} do
      assert fm["dat"] == "četvorma"
    end
  end

  describe "generate_forms/1 - oba/obe (both)" do
    setup do
      word = %Word{
        term: "oba",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "cardinal"
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 12 forms (6 cases x 2 genders)", %{forms: forms} do
      assert length(forms) == 12
    end

    test "nominative masculine", %{forms_map: fm} do
      assert fm["nom_m"] == "oba"
    end

    test "nominative feminine", %{forms_map: fm} do
      assert fm["nom_f"] == "obe"
    end

    test "genitive masculine", %{forms_map: fm} do
      assert fm["gen_m"] == "obaju"
    end

    test "genitive feminine", %{forms_map: fm} do
      assert fm["gen_f"] == "obeju"
    end

    test "dative masculine", %{forms_map: fm} do
      assert fm["dat_m"] == "oboma"
    end

    test "dative feminine", %{forms_map: fm} do
      assert fm["dat_f"] == "obema"
    end
  end

  describe "irregular form overrides" do
    setup do
      word = %Word{
        term: "prvi",
        part_of_speech: :numeral,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "numeral_type" => "ordinal",
          "irregular_forms" => %{
            "nom_sg_m" => "custom_prvi"
          }
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "applies irregular override", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "custom_prvi"
    end

    test "other forms are unchanged", %{forms_map: fm} do
      assert fm["nom_sg_f"] == "prva"
    end
  end

  describe "edge cases" do
    test "handles nil grammar_metadata" do
      word = %Word{
        term: "pet",
        part_of_speech: :numeral,
        grammar_metadata: nil
      }

      forms = Numerals.generate_forms(word)
      assert forms == [{"pet", "base"}]
    end

    test "handles empty grammar_metadata" do
      word = %Word{
        term: "pet",
        part_of_speech: :numeral,
        grammar_metadata: %{}
      }

      forms = Numerals.generate_forms(word)
      assert forms == [{"pet", "base"}]
    end

    test "lowercases the term" do
      word = %Word{
        term: "PET",
        part_of_speech: :numeral,
        grammar_metadata: %{"numeral_type" => "cardinal"}
      }

      forms = Numerals.generate_forms(word)
      assert forms == [{"pet", "base"}]
    end

    test "lowercases irregular form overrides" do
      word = %Word{
        term: "pet",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "cardinal",
          "irregular_forms" => %{
            "base" => "PET"
          }
        }
      }

      forms = Numerals.generate_forms(word)
      forms_map = Map.new(forms, fn {form, tag} -> {tag, form} end)
      assert forms_map["base"] == "pet"
    end

    test "infers cardinal type when not specified" do
      word = %Word{
        term: "dva",
        part_of_speech: :numeral
      }

      forms = Numerals.generate_forms(word)
      # Should generate dva paradigm forms
      assert length(forms) == 12
    end

    test "infers ordinal type for known ordinals" do
      word = %Word{
        term: "drugi",
        part_of_speech: :numeral,
        animate: false
      }

      forms = Numerals.generate_forms(word)
      # Should generate adjective-like forms
      assert length(forms) == 42
    end
  end

  describe "form tag format" do
    test "jedan uses nom_sg_m format" do
      word = %Word{
        term: "jedan",
        part_of_speech: :numeral,
        animate: false,
        grammar_metadata: %{"numeral_type" => "cardinal", "numeral_value" => 1}
      }

      forms = Numerals.generate_forms(word)
      tags = Enum.map(forms, &elem(&1, 1))

      assert "nom_sg_m" in tags
      assert "nom_sg_f" in tags
      assert "nom_sg_n" in tags
    end

    test "dva uses nom_m format (no number)" do
      word = %Word{
        term: "dva",
        part_of_speech: :numeral,
        grammar_metadata: %{"numeral_type" => "cardinal", "numeral_value" => 2}
      }

      forms = Numerals.generate_forms(word)
      tags = Enum.map(forms, &elem(&1, 1))

      assert "nom_m" in tags
      assert "nom_f" in tags
      refute Enum.any?(tags, &String.contains?(&1, "_sg"))
    end

    test "tri uses nom format (no gender or number)" do
      word = %Word{
        term: "tri",
        part_of_speech: :numeral,
        grammar_metadata: %{"numeral_type" => "cardinal", "numeral_value" => 3}
      }

      forms = Numerals.generate_forms(word)
      tags = Enum.map(forms, &elem(&1, 1))

      assert "nom" in tags
      assert "gen" in tags
      refute Enum.any?(tags, &String.contains?(&1, "_m"))
      refute Enum.any?(tags, &String.contains?(&1, "_sg"))
    end

    test "ordinals use nom_sg_m format with full declension" do
      word = %Word{
        term: "prvi",
        part_of_speech: :numeral,
        animate: false,
        grammar_metadata: %{"numeral_type" => "ordinal"}
      }

      forms = Numerals.generate_forms(word)
      tags = Enum.map(forms, &elem(&1, 1))

      assert "nom_sg_m" in tags
      assert "nom_pl_f" in tags
      assert "gen_sg_n" in tags
    end
  end

  # ============================================================================
  # EDGE CASES
  # ============================================================================

  describe "generate_forms/1 - cardinal 5+ invariable (sedam)" do
    setup do
      word = %Word{
        term: "sedam",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "cardinal",
          "numeral_value" => 7
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "returns only 1 form (base)", %{forms: forms} do
      assert length(forms) == 1
    end

    test "base form is sedam", %{forms_map: fm} do
      assert fm["base"] == "sedam"
    end
  end

  describe "generate_forms/1 - cardinal 100 invariable (sto)" do
    setup do
      word = %Word{
        term: "sto",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "cardinal",
          "numeral_value" => 100
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "returns only 1 form (base)", %{forms: forms} do
      assert length(forms) == 1
    end

    test "base form is sto", %{forms_map: fm} do
      assert fm["base"] == "sto"
    end
  end

  describe "generate_forms/1 - ordinal (drugi) hard stem" do
    setup do
      word = %Word{
        term: "drugi",
        part_of_speech: :numeral,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "numeral_type" => "ordinal",
          "numeral_value" => 2
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 42 forms", %{forms: forms} do
      assert length(forms) == 42
    end

    test "nominative singular masculine is drugi", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "drugi"
    end

    test "nominative singular feminine is druga", %{forms_map: fm} do
      assert fm["nom_sg_f"] == "druga"
    end

    test "nominative singular neuter uses -o (hard stem)", %{forms_map: fm} do
      assert fm["nom_sg_n"] == "drugo"
    end

    test "genitive singular masculine is drugog", %{forms_map: fm} do
      assert fm["gen_sg_m"] == "drugog"
    end
  end

  describe "generate_forms/1 - collective (petoro)" do
    setup do
      word = %Word{
        term: "petoro",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "collective",
          "numeral_value" => 5
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 6 forms", %{forms: forms} do
      assert length(forms) == 6
    end

    test "nominative is petoro", %{forms_map: fm} do
      assert fm["nom"] == "petoro"
    end

    test "genitive is petorga", %{forms_map: fm} do
      assert fm["gen"] == "petorga"
    end

    test "dative is petorma", %{forms_map: fm} do
      assert fm["dat"] == "petorma"
    end

    test "accusative is petoro", %{forms_map: fm} do
      assert fm["acc"] == "petoro"
    end

    test "instrumental is petorma", %{forms_map: fm} do
      assert fm["ins"] == "petorma"
    end

    test "locative is petorma", %{forms_map: fm} do
      assert fm["loc"] == "petorma"
    end
  end

  # ============================================================================
  # ADDITIONAL EDGE CASES
  # ============================================================================

  describe "generate_forms/1 - ordinal 5th (peti)" do
    setup do
      word = %Word{
        term: "peti",
        part_of_speech: :numeral,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "numeral_type" => "ordinal",
          "numeral_value" => 5
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 42 forms", %{forms: forms} do
      assert length(forms) == 42
    end

    test "nominative singular masculine is peti", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "peti"
    end

    test "nominative singular feminine is peta", %{forms_map: fm} do
      assert fm["nom_sg_f"] == "peta"
    end

    test "nominative singular neuter is peto", %{forms_map: fm} do
      assert fm["nom_sg_n"] == "peto"
    end

    test "genitive singular masculine is petog", %{forms_map: fm} do
      assert fm["gen_sg_m"] == "petog"
    end
  end

  describe "generate_forms/1 - ordinal 6th (šesti)" do
    setup do
      word = %Word{
        term: "šesti",
        part_of_speech: :numeral,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "numeral_type" => "ordinal",
          "numeral_value" => 6
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 42 forms", %{forms: forms} do
      assert length(forms) == 42
    end

    test "nominative singular masculine is šesti", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "šesti"
    end

    test "nominative singular neuter is šesto", %{forms_map: fm} do
      assert fm["nom_sg_n"] == "šesto"
    end

    test "genitive singular masculine is šestog", %{forms_map: fm} do
      assert fm["gen_sg_m"] == "šestog"
    end
  end

  describe "generate_forms/1 - ordinal 10th (deseti)" do
    setup do
      word = %Word{
        term: "deseti",
        part_of_speech: :numeral,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "numeral_type" => "ordinal",
          "numeral_value" => 10
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative singular masculine is deseti", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "deseti"
    end

    test "nominative singular neuter is deseto", %{forms_map: fm} do
      assert fm["nom_sg_n"] == "deseto"
    end
  end

  describe "generate_forms/1 - ordinal 100th (stoti)" do
    setup do
      word = %Word{
        term: "stoti",
        part_of_speech: :numeral,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "numeral_type" => "ordinal",
          "numeral_value" => 100
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative singular masculine is stoti", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "stoti"
    end

    test "nominative singular neuter is stoto", %{forms_map: fm} do
      assert fm["nom_sg_n"] == "stoto"
    end
  end

  describe "generate_forms/1 - ordinal 1000th (hiljaditi)" do
    setup do
      word = %Word{
        term: "hiljaditi",
        part_of_speech: :numeral,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "numeral_type" => "ordinal",
          "numeral_value" => 1000
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative singular masculine is hiljaditi", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "hiljaditi"
    end

    test "nominative singular neuter is hiljadito", %{forms_map: fm} do
      assert fm["nom_sg_n"] == "hiljadito"
    end
  end

  describe "generate_forms/1 - collective both (dvoje - already tested in main tests)" do
    # Note: "oboje" is not in the hardcoded collective paradigms
    # The test for dvoje already covers the collective numeral pattern
    # This test documents the "oba/obe" gender-based pattern instead
    setup do
      word = %Word{
        term: "oba",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "cardinal"
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 12 forms (6 cases x 2 genders)", %{forms: forms} do
      assert length(forms) == 12
    end

    test "nominative masculine is oba", %{forms_map: fm} do
      assert fm["nom_m"] == "oba"
    end

    test "nominative feminine is obe", %{forms_map: fm} do
      assert fm["nom_f"] == "obe"
    end
  end

  describe "generate_forms/1 - collective 6 (šestoro)" do
    setup do
      word = %Word{
        term: "šestoro",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "collective",
          "numeral_value" => 6
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 6 forms", %{forms: forms} do
      assert length(forms) == 6
    end

    test "nominative is šestoro", %{forms_map: fm} do
      assert fm["nom"] == "šestoro"
    end

    test "genitive is šestorga", %{forms_map: fm} do
      assert fm["gen"] == "šestorga"
    end
  end

  describe "generate_forms/1 - collective 8 (osmoro)" do
    setup do
      word = %Word{
        term: "osmoro",
        part_of_speech: :numeral,
        grammar_metadata: %{
          "numeral_type" => "collective",
          "numeral_value" => 8
        }
      }

      forms = Numerals.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 6 forms", %{forms: forms} do
      assert length(forms) == 6
    end

    test "nominative is osmoro", %{forms_map: fm} do
      assert fm["nom"] == "osmoro"
    end

    test "genitive is osmorga", %{forms_map: fm} do
      assert fm["gen"] == "osmorga"
    end
  end

end
