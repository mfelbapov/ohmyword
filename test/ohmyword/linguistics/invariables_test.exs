defmodule Ohmyword.Linguistics.InvariablesTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Linguistics.Invariables
  alias Ohmyword.Vocabulary.Word

  describe "applicable?/1" do
    test "returns true for adverbs" do
      word = %Word{term: "brzo", part_of_speech: :adverb}
      assert Invariables.applicable?(word)
    end

    test "returns true for prepositions" do
      word = %Word{term: "u", part_of_speech: :preposition}
      assert Invariables.applicable?(word)
    end

    test "returns true for conjunctions" do
      word = %Word{term: "i", part_of_speech: :conjunction}
      assert Invariables.applicable?(word)
    end

    test "returns true for interjections" do
      word = %Word{term: "jao", part_of_speech: :interjection}
      assert Invariables.applicable?(word)
    end

    test "returns true for particles" do
      word = %Word{term: "li", part_of_speech: :particle}
      assert Invariables.applicable?(word)
    end

    test "returns false for nouns" do
      word = %Word{term: "kuća", part_of_speech: :noun, gender: :feminine}
      refute Invariables.applicable?(word)
    end

    test "returns false for verbs" do
      word = %Word{term: "raditi", part_of_speech: :verb}
      refute Invariables.applicable?(word)
    end

    test "returns false for adjectives" do
      word = %Word{term: "dobar", part_of_speech: :adjective, gender: :masculine}
      refute Invariables.applicable?(word)
    end

    test "returns false for pronouns" do
      word = %Word{term: "ja", part_of_speech: :pronoun, gender: :masculine}
      refute Invariables.applicable?(word)
    end

    test "returns false for numerals" do
      word = %Word{term: "jedan", part_of_speech: :numeral}
      refute Invariables.applicable?(word)
    end

    test "returns false for non-word structs" do
      refute Invariables.applicable?(%{})
      refute Invariables.applicable?(nil)
    end
  end

  describe "generate_forms/1 - simple adverb (ovde)" do
    test "returns only base form" do
      word = %Word{
        term: "ovde",
        part_of_speech: :adverb
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"ovde", "base"}]
    end
  end

  describe "generate_forms/1 - adverb with comparison (brzo)" do
    setup do
      word = %Word{
        term: "brzo",
        part_of_speech: :adverb,
        grammar_metadata: %{
          "comparative" => "brže",
          "superlative" => "najbrže",
          "derived_from" => "brz"
        }
      }

      forms = Invariables.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 3 forms", %{forms: forms} do
      assert length(forms) == 3
    end

    test "base form is correct", %{forms_map: fm} do
      assert fm["base"] == "brzo"
    end

    test "comparative form is correct", %{forms_map: fm} do
      assert fm["comp"] == "brže"
    end

    test "superlative form is correct", %{forms_map: fm} do
      assert fm["super"] == "najbrže"
    end
  end

  describe "generate_forms/1 - irregular adverb comparison (dobro)" do
    setup do
      word = %Word{
        term: "dobro",
        part_of_speech: :adverb,
        grammar_metadata: %{
          "comparative" => "bolje",
          "superlative" => "najbolje"
        }
      }

      forms = Invariables.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 3 forms", %{forms: forms} do
      assert length(forms) == 3
    end

    test "base form is correct", %{forms_map: fm} do
      assert fm["base"] == "dobro"
    end

    test "comparative form is correct", %{forms_map: fm} do
      assert fm["comp"] == "bolje"
    end

    test "superlative form is correct", %{forms_map: fm} do
      assert fm["super"] == "najbolje"
    end
  end

  describe "generate_forms/1 - preposition (u)" do
    test "returns only base form" do
      word = %Word{
        term: "u",
        part_of_speech: :preposition,
        grammar_metadata: %{
          "governs" => ["accusative", "locative"]
        }
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"u", "base"}]
    end
  end

  describe "generate_forms/1 - conjunction (i)" do
    test "returns only base form" do
      word = %Word{
        term: "i",
        part_of_speech: :conjunction
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"i", "base"}]
    end
  end

  describe "generate_forms/1 - interjection (jao)" do
    test "returns only base form" do
      word = %Word{
        term: "jao",
        part_of_speech: :interjection
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"jao", "base"}]
    end
  end

  describe "generate_forms/1 - particle (li)" do
    test "returns only base form" do
      word = %Word{
        term: "li",
        part_of_speech: :particle
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"li", "base"}]
    end
  end

  describe "generate_forms/1 - multi-word preposition" do
    test "handles multi-word expressions" do
      word = %Word{
        term: "bez obzira na",
        part_of_speech: :preposition,
        grammar_metadata: %{
          "governs" => "accusative"
        }
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"bez obzira na", "base"}]
    end
  end

  describe "edge cases" do
    test "handles nil grammar_metadata for adverb" do
      word = %Word{
        term: "ovde",
        part_of_speech: :adverb,
        grammar_metadata: nil
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"ovde", "base"}]
    end

    test "handles empty grammar_metadata for adverb" do
      word = %Word{
        term: "ovde",
        part_of_speech: :adverb,
        grammar_metadata: %{}
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"ovde", "base"}]
    end

    test "handles nil term" do
      word = %Word{
        term: nil,
        part_of_speech: :adverb
      }

      forms = Invariables.generate_forms(word)

      assert forms == []
    end

    test "handles empty term" do
      word = %Word{
        term: "",
        part_of_speech: :adverb
      }

      forms = Invariables.generate_forms(word)

      assert forms == []
    end

    test "lowercases the term" do
      word = %Word{
        term: "BRZO",
        part_of_speech: :adverb
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"brzo", "base"}]
    end

    test "lowercases comparative and superlative forms" do
      word = %Word{
        term: "BRZO",
        part_of_speech: :adverb,
        grammar_metadata: %{
          "comparative" => "BRŽE",
          "superlative" => "NAJBRŽE"
        }
      }

      forms = Invariables.generate_forms(word)
      forms_map = Map.new(forms, fn {form, tag} -> {tag, form} end)

      assert forms_map["base"] == "brzo"
      assert forms_map["comp"] == "brže"
      assert forms_map["super"] == "najbrže"
    end

    test "handles adverb with only comparative" do
      word = %Word{
        term: "brzo",
        part_of_speech: :adverb,
        grammar_metadata: %{
          "comparative" => "brže"
        }
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"brzo", "base"}, {"brže", "comp"}]
    end

    test "handles adverb with only superlative" do
      word = %Word{
        term: "brzo",
        part_of_speech: :adverb,
        grammar_metadata: %{
          "superlative" => "najbrže"
        }
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"brzo", "base"}, {"najbrže", "super"}]
    end

    test "handles empty string comparative" do
      word = %Word{
        term: "brzo",
        part_of_speech: :adverb,
        grammar_metadata: %{
          "comparative" => "",
          "superlative" => "najbrže"
        }
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"brzo", "base"}, {"najbrže", "super"}]
    end
  end

  describe "additional invariable examples" do
    test "adverb: sada (now)" do
      word = %Word{term: "sada", part_of_speech: :adverb}
      assert Invariables.generate_forms(word) == [{"sada", "base"}]
    end

    test "adverb: uvek (always)" do
      word = %Word{term: "uvek", part_of_speech: :adverb}
      assert Invariables.generate_forms(word) == [{"uvek", "base"}]
    end

    test "preposition: na (on)" do
      word = %Word{term: "na", part_of_speech: :preposition}
      assert Invariables.generate_forms(word) == [{"na", "base"}]
    end

    test "preposition: kod (at, by)" do
      word = %Word{term: "kod", part_of_speech: :preposition}
      assert Invariables.generate_forms(word) == [{"kod", "base"}]
    end

    test "conjunction: ili (or)" do
      word = %Word{term: "ili", part_of_speech: :conjunction}
      assert Invariables.generate_forms(word) == [{"ili", "base"}]
    end

    test "conjunction: ali (but)" do
      word = %Word{term: "ali", part_of_speech: :conjunction}
      assert Invariables.generate_forms(word) == [{"ali", "base"}]
    end

    test "interjection: ej (hey)" do
      word = %Word{term: "ej", part_of_speech: :interjection}
      assert Invariables.generate_forms(word) == [{"ej", "base"}]
    end

    test "interjection: bravo" do
      word = %Word{term: "bravo", part_of_speech: :interjection}
      assert Invariables.generate_forms(word) == [{"bravo", "base"}]
    end

    test "particle: ne (no)" do
      word = %Word{term: "ne", part_of_speech: :particle}
      assert Invariables.generate_forms(word) == [{"ne", "base"}]
    end

    test "particle: zar (rhetorical question)" do
      word = %Word{term: "zar", part_of_speech: :particle}
      assert Invariables.generate_forms(word) == [{"zar", "base"}]
    end
  end

  describe "adverbs with irregular comparison" do
    test "loše -> gore -> najgore" do
      word = %Word{
        term: "loše",
        part_of_speech: :adverb,
        grammar_metadata: %{
          "comparative" => "gore",
          "superlative" => "najgore"
        }
      }

      forms = Invariables.generate_forms(word)
      forms_map = Map.new(forms, fn {form, tag} -> {tag, form} end)

      assert forms_map["base"] == "loše"
      assert forms_map["comp"] == "gore"
      assert forms_map["super"] == "najgore"
    end

    test "daleko -> dalje -> najdalje" do
      word = %Word{
        term: "daleko",
        part_of_speech: :adverb,
        grammar_metadata: %{
          "comparative" => "dalje",
          "superlative" => "najdalje"
        }
      }

      forms = Invariables.generate_forms(word)
      forms_map = Map.new(forms, fn {form, tag} -> {tag, form} end)

      assert forms_map["base"] == "daleko"
      assert forms_map["comp"] == "dalje"
      assert forms_map["super"] == "najdalje"
    end

    test "blizu -> bliže -> najbliže" do
      word = %Word{
        term: "blizu",
        part_of_speech: :adverb,
        grammar_metadata: %{
          "comparative" => "bliže",
          "superlative" => "najbliže"
        }
      }

      forms = Invariables.generate_forms(word)
      forms_map = Map.new(forms, fn {form, tag} -> {tag, form} end)

      assert forms_map["base"] == "blizu"
      assert forms_map["comp"] == "bliže"
      assert forms_map["super"] == "najbliže"
    end
  end

  # ============================================================================
  # EDGE CASES
  # ============================================================================

  describe "generate_forms/1 - single-letter preposition (s)" do
    test "returns base form" do
      word = %Word{
        term: "s",
        part_of_speech: :preposition,
        grammar_metadata: %{"governs" => "genitive"}
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"s", "base"}]
    end
  end

  describe "generate_forms/1 - single-letter preposition (k)" do
    test "returns base form" do
      word = %Word{
        term: "k",
        part_of_speech: :preposition,
        grammar_metadata: %{"governs" => "dative"}
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"k", "base"}]
    end
  end

  describe "generate_forms/1 - single-letter conjunction (a)" do
    test "returns base form" do
      word = %Word{
        term: "a",
        part_of_speech: :conjunction
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"a", "base"}]
    end
  end

  describe "generate_forms/1 - two-letter particle (da)" do
    test "returns base form" do
      word = %Word{
        term: "da",
        part_of_speech: :particle
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"da", "base"}]
    end
  end

  describe "generate_forms/1 - adverb irregular comparison (mnogo)" do
    setup do
      word = %Word{
        term: "mnogo",
        part_of_speech: :adverb,
        grammar_metadata: %{
          "comparative" => "više",
          "superlative" => "najviše"
        }
      }

      forms = Invariables.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 3 forms", %{forms: forms} do
      assert length(forms) == 3
    end

    test "base form is mnogo", %{forms_map: fm} do
      assert fm["base"] == "mnogo"
    end

    test "comparative is više", %{forms_map: fm} do
      assert fm["comp"] == "više"
    end

    test "superlative is najviše", %{forms_map: fm} do
      assert fm["super"] == "najviše"
    end
  end

  # ============================================================================
  # ADDITIONAL EDGE CASES
  # ============================================================================

  describe "generate_forms/1 - interrogative adverb (gde/gdje)" do
    test "gde returns only base form" do
      word = %Word{
        term: "gde",
        part_of_speech: :adverb
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"gde", "base"}]
    end

    test "gdje returns only base form (Ijekavian variant)" do
      word = %Word{
        term: "gdje",
        part_of_speech: :adverb
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"gdje", "base"}]
    end
  end

  describe "generate_forms/1 - interrogative adverb (kada)" do
    test "returns only base form" do
      word = %Word{
        term: "kada",
        part_of_speech: :adverb
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"kada", "base"}]
    end
  end

  describe "generate_forms/1 - interrogative adverb (kako)" do
    test "returns only base form" do
      word = %Word{
        term: "kako",
        part_of_speech: :adverb
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"kako", "base"}]
    end
  end

  describe "generate_forms/1 - interrogative adverb (zašto)" do
    test "returns only base form" do
      word = %Word{
        term: "zašto",
        part_of_speech: :adverb
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"zašto", "base"}]
    end
  end

  describe "generate_forms/1 - frequency adverb with comparison (često)" do
    setup do
      word = %Word{
        term: "često",
        part_of_speech: :adverb,
        grammar_metadata: %{
          "comparative" => "češće",
          "superlative" => "najčešće"
        }
      }

      forms = Invariables.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 3 forms", %{forms: forms} do
      assert length(forms) == 3
    end

    test "base form is često", %{forms_map: fm} do
      assert fm["base"] == "često"
    end

    test "comparative is češće", %{forms_map: fm} do
      assert fm["comp"] == "češće"
    end

    test "superlative is najčešće", %{forms_map: fm} do
      assert fm["super"] == "najčešće"
    end
  end

  describe "generate_forms/1 - manner adverb with irregular comparison (visoko)" do
    setup do
      word = %Word{
        term: "visoko",
        part_of_speech: :adverb,
        grammar_metadata: %{
          "comparative" => "više",
          "superlative" => "najviše"
        }
      }

      forms = Invariables.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 3 forms", %{forms: forms} do
      assert length(forms) == 3
    end

    test "base form is visoko", %{forms_map: fm} do
      assert fm["base"] == "visoko"
    end

    test "comparative is više", %{forms_map: fm} do
      assert fm["comp"] == "više"
    end

    test "superlative is najviše", %{forms_map: fm} do
      assert fm["super"] == "najviše"
    end
  end

  describe "generate_forms/1 - manner adverb with comparison (nisko)" do
    setup do
      word = %Word{
        term: "nisko",
        part_of_speech: :adverb,
        grammar_metadata: %{
          "comparative" => "niže",
          "superlative" => "najniže"
        }
      }

      forms = Invariables.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 3 forms", %{forms: forms} do
      assert length(forms) == 3
    end

    test "base form is nisko", %{forms_map: fm} do
      assert fm["base"] == "nisko"
    end

    test "comparative is niže", %{forms_map: fm} do
      assert fm["comp"] == "niže"
    end

    test "superlative is najniže", %{forms_map: fm} do
      assert fm["super"] == "najniže"
    end
  end

  describe "generate_forms/1 - temporal preposition (pre/prije)" do
    test "pre returns only base form (Ekavian)" do
      word = %Word{
        term: "pre",
        part_of_speech: :preposition,
        grammar_metadata: %{"governs" => "genitive"}
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"pre", "base"}]
    end

    test "prije returns only base form (Ijekavian)" do
      word = %Word{
        term: "prije",
        part_of_speech: :preposition,
        grammar_metadata: %{"governs" => "genitive"}
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"prije", "base"}]
    end
  end

  describe "generate_forms/1 - temporal preposition (posle/poslije)" do
    test "posle returns only base form (Ekavian)" do
      word = %Word{
        term: "posle",
        part_of_speech: :preposition,
        grammar_metadata: %{"governs" => "genitive"}
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"posle", "base"}]
    end

    test "poslije returns only base form (Ijekavian)" do
      word = %Word{
        term: "poslije",
        part_of_speech: :preposition,
        grammar_metadata: %{"governs" => "genitive"}
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"poslije", "base"}]
    end
  end

  describe "generate_forms/1 - modal adverb (možda)" do
    test "returns only base form" do
      word = %Word{
        term: "možda",
        part_of_speech: :adverb
      }

      forms = Invariables.generate_forms(word)

      assert forms == [{"možda", "base"}]
    end
  end
end
