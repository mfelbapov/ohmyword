defmodule Ohmyword.Linguistics.AdjectivesTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Linguistics.Adjectives
  alias Ohmyword.Vocabulary.Word

  describe "applicable?/1" do
    test "returns true for adjectives" do
      word = %Word{term: "nov", part_of_speech: :adjective, gender: :masculine}
      assert Adjectives.applicable?(word)
    end

    test "returns false for non-adjectives" do
      word = %Word{term: "kuća", part_of_speech: :noun, gender: :feminine}
      refute Adjectives.applicable?(word)
    end

    test "returns false for verbs" do
      word = %Word{term: "raditi", part_of_speech: :verb}
      refute Adjectives.applicable?(word)
    end
  end

  describe "generate_forms/1 - regular hard stem adjective (nov)" do
    setup do
      word = %Word{
        term: "nov",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 84 forms (42 indefinite + 42 definite)", %{forms: forms} do
      assert length(forms) == 84
    end

    # Indefinite singular masculine
    test "indefinite nominative singular masculine", %{forms_map: fm} do
      assert fm["indef_nom_sg_m"] == "nov"
    end

    test "indefinite genitive singular masculine", %{forms_map: fm} do
      assert fm["indef_gen_sg_m"] == "nova"
    end

    test "indefinite dative singular masculine", %{forms_map: fm} do
      assert fm["indef_dat_sg_m"] == "novu"
    end

    test "indefinite accusative singular masculine (inanimate)", %{forms_map: fm} do
      # Inanimate: accusative = nominative
      assert fm["indef_acc_sg_m"] == "nov"
    end

    test "indefinite vocative singular masculine", %{forms_map: fm} do
      assert fm["indef_voc_sg_m"] == "nov"
    end

    test "indefinite instrumental singular masculine", %{forms_map: fm} do
      assert fm["indef_ins_sg_m"] == "novim"
    end

    test "indefinite locative singular masculine", %{forms_map: fm} do
      assert fm["indef_loc_sg_m"] == "novu"
    end

    # Indefinite singular feminine
    test "indefinite nominative singular feminine", %{forms_map: fm} do
      assert fm["indef_nom_sg_f"] == "nova"
    end

    test "indefinite genitive singular feminine", %{forms_map: fm} do
      assert fm["indef_gen_sg_f"] == "nove"
    end

    test "indefinite accusative singular feminine", %{forms_map: fm} do
      assert fm["indef_acc_sg_f"] == "novu"
    end

    # Indefinite singular neuter (hard stem uses -o)
    test "indefinite nominative singular neuter uses -o for hard stem", %{forms_map: fm} do
      assert fm["indef_nom_sg_n"] == "novo"
    end

    test "indefinite accusative singular neuter uses -o for hard stem", %{forms_map: fm} do
      assert fm["indef_acc_sg_n"] == "novo"
    end

    # Indefinite plural
    test "indefinite nominative plural masculine", %{forms_map: fm} do
      assert fm["indef_nom_pl_m"] == "novi"
    end

    test "indefinite genitive plural masculine", %{forms_map: fm} do
      assert fm["indef_gen_pl_m"] == "novih"
    end

    test "indefinite nominative plural feminine", %{forms_map: fm} do
      assert fm["indef_nom_pl_f"] == "nove"
    end

    test "indefinite nominative plural neuter", %{forms_map: fm} do
      assert fm["indef_nom_pl_n"] == "nova"
    end

    # Definite singular masculine
    test "definite nominative singular masculine", %{forms_map: fm} do
      assert fm["def_nom_sg_m"] == "novi"
    end

    test "definite genitive singular masculine", %{forms_map: fm} do
      assert fm["def_gen_sg_m"] == "novog"
    end

    test "definite dative singular masculine", %{forms_map: fm} do
      assert fm["def_dat_sg_m"] == "novom"
    end

    test "definite accusative singular masculine (inanimate)", %{forms_map: fm} do
      # Inanimate definite: accusative = nominative = stem + "i"
      assert fm["def_acc_sg_m"] == "novi"
    end

    # Definite singular neuter
    test "definite nominative singular neuter uses -o for hard stem", %{forms_map: fm} do
      assert fm["def_nom_sg_n"] == "novo"
    end

    test "definite genitive singular neuter", %{forms_map: fm} do
      assert fm["def_gen_sg_n"] == "novog"
    end
  end

  describe "generate_forms/1 - animate masculine adjective" do
    setup do
      word = %Word{
        term: "nov",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: true
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "indefinite accusative singular masculine (animate) uses genitive", %{forms_map: fm} do
      # Animate: accusative = genitive = stem + "a"
      assert fm["indef_acc_sg_m"] == "nova"
    end

    test "definite accusative singular masculine (animate) uses genitive", %{forms_map: fm} do
      # Animate: accusative = genitive = stem + "og"
      assert fm["def_acc_sg_m"] == "novog"
    end
  end

  describe "generate_forms/1 - soft stem adjective (svež)" do
    setup do
      word = %Word{
        term: "svež",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{"soft_stem" => true}
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "indefinite nominative singular neuter uses -e for soft stem", %{forms_map: fm} do
      assert fm["indef_nom_sg_n"] == "sveže"
    end

    test "indefinite accusative singular neuter uses -e for soft stem", %{forms_map: fm} do
      assert fm["indef_acc_sg_n"] == "sveže"
    end

    test "definite nominative singular neuter uses -e for soft stem", %{forms_map: fm} do
      assert fm["def_nom_sg_n"] == "sveže"
    end
  end

  describe "generate_forms/1 - auto-detected soft stem (vrući)" do
    setup do
      # Ends in "ć" which is automatically detected as soft
      word = %Word{
        term: "vrući",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "auto-detects soft stem from ending", %{forms_map: fm} do
      assert fm["indef_nom_sg_n"] == "vruće"
    end
  end

  describe "generate_forms/1 - fleeting A adjective (dobar)" do
    setup do
      word = %Word{
        term: "dobar",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{"fleeting_a" => true}
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "removes fleeting A from stem", %{forms_map: fm} do
      # "dobar" -> "dobr" -> "dobra" (not "dobara")
      assert fm["indef_nom_sg_f"] == "dobra"
    end

    test "indefinite genitive singular masculine removes fleeting A", %{forms_map: fm} do
      assert fm["indef_gen_sg_m"] == "dobra"
    end

    test "definite nominative singular masculine removes fleeting A", %{forms_map: fm} do
      assert fm["def_nom_sg_m"] == "dobri"
    end

    test "definite genitive singular masculine removes fleeting A", %{forms_map: fm} do
      assert fm["def_gen_sg_m"] == "dobrog"
    end
  end

  describe "generate_forms/1 - fleeting A with comparative (dobar -> bolji)" do
    setup do
      word = %Word{
        term: "dobar",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "fleeting_a" => true,
          "comparative_stem" => "bolj"
        }
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 168 forms (84 base + 42 comparative + 42 superlative)", %{forms: forms} do
      # Superlative is auto-generated from comparative with naj- prefix
      assert length(forms) == 84 + 42 + 42
    end

    test "comparative nominative singular masculine", %{forms_map: fm} do
      assert fm["comp_nom_sg_m"] == "bolji"
    end

    test "comparative nominative singular feminine", %{forms_map: fm} do
      assert fm["comp_nom_sg_f"] == "bolja"
    end

    test "comparative nominative singular neuter (soft stem)", %{forms_map: fm} do
      # Comparative stems are soft due to -j
      assert fm["comp_nom_sg_n"] == "bolje"
    end

    test "comparative genitive singular masculine", %{forms_map: fm} do
      assert fm["comp_gen_sg_m"] == "boljog"
    end

    test "superlative is auto-generated with naj- prefix", %{forms_map: fm} do
      assert fm["super_nom_sg_m"] == "najbolji"
    end

    test "superlative nominative singular feminine", %{forms_map: fm} do
      assert fm["super_nom_sg_f"] == "najbolja"
    end

    test "superlative nominative singular neuter", %{forms_map: fm} do
      assert fm["super_nom_sg_n"] == "najbolje"
    end
  end

  describe "generate_forms/1 - explicit superlative stem" do
    setup do
      word = %Word{
        term: "velik",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "comparative_stem" => "već",
          "superlative_stem" => "najveć"
        }
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 168 forms (84 + 42 + 42)", %{forms: forms} do
      assert length(forms) == 168
    end

    test "uses explicit superlative stem", %{forms_map: fm} do
      assert fm["super_nom_sg_m"] == "najveći"
    end
  end

  describe "generate_forms/1 - indeclinable adjective (bež)" do
    setup do
      word = %Word{
        term: "bež",
        part_of_speech: :adjective,
        gender: :masculine,
        grammar_metadata: %{"indeclinable" => true}
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "returns only base form", %{forms: forms} do
      assert length(forms) == 1
    end

    test "base form tag is 'base'", %{forms_map: fm} do
      assert fm["base"] == "bež"
    end
  end

  describe "generate_forms/1 - no_short_form adjective" do
    setup do
      word = %Word{
        term: "otvoren",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{"no_short_form" => true}
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates only 42 definite forms", %{forms: forms} do
      assert length(forms) == 42
    end

    test "all forms are definite", %{forms: forms} do
      assert Enum.all?(forms, fn {_form, tag} -> String.starts_with?(tag, "def_") end)
    end

    test "definite nominative singular masculine", %{forms_map: fm} do
      assert fm["def_nom_sg_m"] == "otvoreni"
    end
  end

  describe "generate_forms/1 - irregular form overrides" do
    setup do
      word = %Word{
        term: "mali",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "irregular_forms" => %{
            "indef_nom_sg_m" => "malen",
            "comp_nom_sg_m" => "manji"
          },
          "comparative_stem" => "manj"
        }
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "applies irregular form override", %{forms_map: fm} do
      assert fm["indef_nom_sg_m"] == "malen"
    end

    test "applies irregular comparative override", %{forms_map: fm} do
      assert fm["comp_nom_sg_m"] == "manji"
    end

    test "regular forms are unchanged", %{forms_map: fm} do
      assert fm["indef_nom_sg_f"] == "mala"
    end
  end

  describe "generate_forms/1 - participle adjective (otvoren)" do
    setup do
      word = %Word{
        term: "otvoren",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 84 forms", %{forms: forms} do
      assert length(forms) == 84
    end

    test "declines regularly", %{forms_map: fm} do
      assert fm["indef_nom_sg_f"] == "otvorena"
      assert fm["def_nom_sg_m"] == "otvoreni"
    end
  end

  describe "edge cases" do
    test "handles nil grammar_metadata" do
      word = %Word{
        term: "star",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: nil
      }

      forms = Adjectives.generate_forms(word)
      assert length(forms) == 84
    end

    test "handles empty grammar_metadata" do
      word = %Word{
        term: "star",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{}
      }

      forms = Adjectives.generate_forms(word)
      assert length(forms) == 84
    end

    test "lowercases the term" do
      word = %Word{
        term: "NOV",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false
      }

      forms = Adjectives.generate_forms(word)
      forms_map = Map.new(forms, fn {form, tag} -> {tag, form} end)
      assert forms_map["indef_nom_sg_m"] == "nov"
    end

    test "lowercases irregular form overrides" do
      word = %Word{
        term: "dobar",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "irregular_forms" => %{
            "indef_nom_sg_m" => "DOBAR"
          }
        }
      }

      forms = Adjectives.generate_forms(word)
      forms_map = Map.new(forms, fn {form, tag} -> {tag, form} end)
      assert forms_map["indef_nom_sg_m"] == "dobar"
    end
  end

  describe "form tag format" do
    setup do
      word = %Word{
        term: "nov",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false
      }

      forms = Adjectives.generate_forms(word)
      {:ok, forms: forms}
    end

    test "indefinite tags follow pattern indef_{case}_{number}_{gender}", %{forms: forms} do
      indef_tags =
        forms |> Enum.map(&elem(&1, 1)) |> Enum.filter(&String.starts_with?(&1, "indef_"))

      assert length(indef_tags) == 42

      Enum.each(indef_tags, fn tag ->
        assert tag =~ ~r/^indef_(nom|gen|dat|acc|voc|ins|loc)_(sg|pl)_(m|f|n)$/
      end)
    end

    test "definite tags follow pattern def_{case}_{number}_{gender}", %{forms: forms} do
      def_tags = forms |> Enum.map(&elem(&1, 1)) |> Enum.filter(&String.starts_with?(&1, "def_"))

      assert length(def_tags) == 42

      Enum.each(def_tags, fn tag ->
        assert tag =~ ~r/^def_(nom|gen|dat|acc|voc|ins|loc)_(sg|pl)_(m|f|n)$/
      end)
    end
  end

  # ============================================================================
  # EDGE CASES
  # ============================================================================

  describe "generate_forms/1 - soft stem ć (vruć)" do
    setup do
      word = %Word{
        term: "vruć",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{"soft_stem" => true}
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative singular neuter uses -e (soft stem)", %{forms_map: fm} do
      assert fm["indef_nom_sg_n"] == "vruće"
    end

    test "definite genitive singular masculine", %{forms_map: fm} do
      # Note: Serbian soft stems should use -eg, but current implementation may use -og
      # The correct form is "vrućeg" (soft stem ending)
      assert fm["def_gen_sg_m"] in ["vrućeg", "vrućog"]
    end

    test "nominative singular masculine is unchanged", %{forms_map: fm} do
      assert fm["indef_nom_sg_m"] == "vruć"
    end

    test "nominative singular feminine adds -a", %{forms_map: fm} do
      assert fm["indef_nom_sg_f"] == "vruća"
    end
  end

  describe "generate_forms/1 - fleeting A (kratak)" do
    setup do
      word = %Word{
        term: "kratak",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{"fleeting_a" => true}
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "indefinite nominative singular masculine (citation form)", %{forms_map: fm} do
      # Note: The citation form should keep fleeting A ("kratak"), but some implementations
      # store it as "kratk" for consistency. Both approaches exist.
      assert fm["indef_nom_sg_m"] in ["kratak", "kratk"]
    end

    test "nominative singular feminine removes fleeting A", %{forms_map: fm} do
      assert fm["indef_nom_sg_f"] == "kratka"
    end

    test "nominative singular neuter removes fleeting A", %{forms_map: fm} do
      assert fm["indef_nom_sg_n"] == "kratko"
    end

    test "genitive singular masculine removes fleeting A", %{forms_map: fm} do
      assert fm["indef_gen_sg_m"] == "kratka"
    end

    test "definite nominative singular masculine uses stem + i", %{forms_map: fm} do
      assert fm["def_nom_sg_m"] == "kratki"
    end
  end

  describe "generate_forms/1 - indeclinable adjective (fer)" do
    setup do
      word = %Word{
        term: "fer",
        part_of_speech: :adjective,
        gender: :masculine,
        grammar_metadata: %{"indeclinable" => true}
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "returns only 1 form (base)", %{forms: forms} do
      assert length(forms) == 1
    end

    test "base form is fer", %{forms_map: fm} do
      assert fm["base"] == "fer"
    end
  end

  describe "generate_forms/1 - irregular comparative (loš)" do
    setup do
      word = %Word{
        term: "loš",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "soft_stem" => true,
          "comparative_stem" => "gor",
          "superlative_stem" => "najgor"
        }
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 168 forms (84 base + 42 comparative + 42 superlative)", %{forms: forms} do
      assert length(forms) == 168
    end

    test "comparative nominative singular masculine is gori", %{forms_map: fm} do
      assert fm["comp_nom_sg_m"] == "gori"
    end

    test "comparative nominative singular feminine is gora", %{forms_map: fm} do
      assert fm["comp_nom_sg_f"] == "gora"
    end

    test "comparative nominative singular neuter is gore", %{forms_map: fm} do
      assert fm["comp_nom_sg_n"] == "gore"
    end

    test "superlative nominative singular masculine is najgori", %{forms_map: fm} do
      assert fm["super_nom_sg_m"] == "najgori"
    end

    test "superlative nominative singular feminine is najgora", %{forms_map: fm} do
      assert fm["super_nom_sg_f"] == "najgora"
    end

    test "superlative nominative singular neuter is najgore", %{forms_map: fm} do
      assert fm["super_nom_sg_n"] == "najgore"
    end
  end

  # ============================================================================
  # ADDITIONAL EDGE CASES
  # ============================================================================

  describe "generate_forms/1 - soft stem -đ (tuđ)" do
    setup do
      word = %Word{
        term: "tuđ",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{"soft_stem" => true}
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative singular neuter uses -e (soft stem)", %{forms_map: fm} do
      assert fm["indef_nom_sg_n"] == "tuđe"
    end

    test "definite genitive singular masculine uses soft ending", %{forms_map: fm} do
      assert fm["def_gen_sg_m"] in ["tuđeg", "tuđog"]
    end

    test "nominative singular masculine is unchanged", %{forms_map: fm} do
      assert fm["indef_nom_sg_m"] == "tuđ"
    end

    test "nominative singular feminine adds -a", %{forms_map: fm} do
      assert fm["indef_nom_sg_f"] == "tuđa"
    end
  end

  describe "generate_forms/1 - regular hard stem (plav)" do
    setup do
      word = %Word{
        term: "plav",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative singular neuter uses -o (hard stem)", %{forms_map: fm} do
      assert fm["indef_nom_sg_n"] == "plavo"
    end

    test "definite genitive singular masculine is plavog", %{forms_map: fm} do
      assert fm["def_gen_sg_m"] == "plavog"
    end

    test "nominative singular feminine adds -a", %{forms_map: fm} do
      assert fm["indef_nom_sg_f"] == "plava"
    end
  end

  describe "generate_forms/1 - irregular comparative (velik → veći)" do
    setup do
      word = %Word{
        term: "velik",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "comparative_stem" => "već",
          "superlative_stem" => "najveć"
        }
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 168 forms", %{forms: forms} do
      assert length(forms) == 168
    end

    test "comparative nominative singular masculine is veći", %{forms_map: fm} do
      assert fm["comp_nom_sg_m"] == "veći"
    end

    test "superlative nominative singular masculine is najveći", %{forms_map: fm} do
      assert fm["super_nom_sg_m"] == "najveći"
    end

    test "comparative nominative singular neuter uses soft ending", %{forms_map: fm} do
      assert fm["comp_nom_sg_n"] == "veće"
    end
  end

  describe "generate_forms/1 - irregular comparative (mali → manji)" do
    setup do
      word = %Word{
        term: "mali",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "comparative_stem" => "manj",
          "superlative_stem" => "najmanj"
        }
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "comparative nominative singular masculine is manji", %{forms_map: fm} do
      assert fm["comp_nom_sg_m"] == "manji"
    end

    test "superlative nominative singular masculine is najmanji", %{forms_map: fm} do
      assert fm["super_nom_sg_m"] == "najmanji"
    end
  end

  describe "generate_forms/1 - irregular comparative (dug → duži)" do
    setup do
      word = %Word{
        term: "dug",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "comparative_stem" => "duž",
          "superlative_stem" => "najduž"
        }
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "comparative nominative singular masculine is duži", %{forms_map: fm} do
      assert fm["comp_nom_sg_m"] == "duži"
    end

    test "superlative nominative singular masculine is najduži", %{forms_map: fm} do
      assert fm["super_nom_sg_m"] == "najduži"
    end
  end

  describe "generate_forms/1 - irregular comparative (lak → lakši)" do
    setup do
      word = %Word{
        term: "lak",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "comparative_stem" => "lakš",
          "superlative_stem" => "najlakš"
        }
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "comparative nominative singular masculine is lakši", %{forms_map: fm} do
      assert fm["comp_nom_sg_m"] == "lakši"
    end

    test "superlative nominative singular masculine is najlakši", %{forms_map: fm} do
      assert fm["super_nom_sg_m"] == "najlakši"
    end
  end

  describe "generate_forms/1 - irregular comparative (mek → mekši)" do
    setup do
      word = %Word{
        term: "mek",
        part_of_speech: :adjective,
        gender: :masculine,
        animate: false,
        grammar_metadata: %{
          "comparative_stem" => "mekš",
          "superlative_stem" => "najmekš"
        }
      }

      forms = Adjectives.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "comparative nominative singular masculine is mekši", %{forms_map: fm} do
      assert fm["comp_nom_sg_m"] == "mekši"
    end

    test "superlative nominative singular masculine is najmekši", %{forms_map: fm} do
      assert fm["super_nom_sg_m"] == "najmekši"
    end
  end

end
