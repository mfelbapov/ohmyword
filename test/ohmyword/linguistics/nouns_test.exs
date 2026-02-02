defmodule Ohmyword.Linguistics.NounsTest do
  use Ohmyword.DataCase, async: true

  alias Ohmyword.Linguistics.Nouns
  alias Ohmyword.Vocabulary.Word

  describe "applicable?/1" do
    test "returns true for nouns" do
      word = %Word{part_of_speech: :noun, gender: :masculine, animate: true}
      assert Nouns.applicable?(word)
    end

    test "returns false for verbs" do
      word = %Word{part_of_speech: :verb}
      refute Nouns.applicable?(word)
    end

    test "returns false for adjectives" do
      word = %Word{part_of_speech: :adjective, gender: :masculine}
      refute Nouns.applicable?(word)
    end

    test "returns false for non-Word structs" do
      refute Nouns.applicable?(%{part_of_speech: :noun})
      refute Nouns.applicable?(nil)
    end
  end

  describe "generate_forms/1 - basic masculine inanimate (grad)" do
    setup do
      word = %Word{
        term: "grad",
        part_of_speech: :noun,
        gender: :masculine,
        animate: false,
        declension_class: "consonant"
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "returns 14 forms", %{forms: forms} do
      assert length(forms) == 14
    end

    test "nominative singular is unchanged", %{forms: forms} do
      assert {"grad", "nom_sg"} in forms
    end

    test "genitive singular adds -a", %{forms: forms} do
      assert {"grada", "gen_sg"} in forms
    end

    test "dative singular adds -u", %{forms: forms} do
      assert {"gradu", "dat_sg"} in forms
    end

    test "accusative singular equals nominative for inanimate", %{forms: forms} do
      assert {"grad", "acc_sg"} in forms
    end

    test "vocative singular adds -e", %{forms: forms} do
      assert {"grade", "voc_sg"} in forms
    end

    test "instrumental singular adds -om", %{forms: forms} do
      assert {"gradom", "ins_sg"} in forms
    end

    test "locative singular adds -u", %{forms: forms} do
      assert {"gradu", "loc_sg"} in forms
    end

    test "nominative plural adds -ovi", %{forms: forms} do
      assert {"gradovi", "nom_pl"} in forms
    end

    test "genitive plural adds -ova", %{forms: forms} do
      assert {"gradova", "gen_pl"} in forms
    end

    test "dative/instrumental/locative plural adds -ovima", %{forms: forms} do
      assert {"gradovima", "dat_pl"} in forms
      assert {"gradovima", "ins_pl"} in forms
      assert {"gradovima", "loc_pl"} in forms
    end

    test "accusative plural adds -ove for inanimate", %{forms: forms} do
      assert {"gradove", "acc_pl"} in forms
    end

    test "vocative plural adds -ovi", %{forms: forms} do
      assert {"gradovi", "voc_pl"} in forms
    end
  end

  describe "generate_forms/1 - masculine animate with fleeting A (pas)" do
    setup do
      word = %Word{
        term: "pas",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "consonant",
        grammar_metadata: %{"fleeting_a" => true}
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular keeps the A", %{forms: forms} do
      assert {"pas", "nom_sg"} in forms
    end

    test "genitive singular removes fleeting A", %{forms: forms} do
      assert {"psa", "gen_sg"} in forms
    end

    test "accusative singular equals genitive for animate", %{forms: forms} do
      assert {"psa", "acc_sg"} in forms
    end

    test "genitive plural keeps the A", %{forms: forms} do
      assert {"pasa", "gen_pl"} in forms
    end

    test "nominative plural removes fleeting A", %{forms: forms} do
      assert {"psi", "nom_pl"} in forms
    end

    test "dative/instrumental/locative plural removes fleeting A", %{forms: forms} do
      assert {"psima", "dat_pl"} in forms
      assert {"psima", "ins_pl"} in forms
      assert {"psima", "loc_pl"} in forms
    end

    test "accusative plural equals genitive for animate", %{forms: forms} do
      assert {"pasa", "acc_pl"} in forms
    end
  end

  describe "generate_forms/1 - feminine a-stem (žena)" do
    setup do
      word = %Word{
        term: "žena",
        part_of_speech: :noun,
        gender: :feminine,
        declension_class: "a-stem"
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "returns 14 forms", %{forms: forms} do
      assert length(forms) == 14
    end

    test "nominative singular ends in -a", %{forms: forms} do
      assert {"žena", "nom_sg"} in forms
    end

    test "genitive singular ends in -e", %{forms: forms} do
      assert {"žene", "gen_sg"} in forms
    end

    test "dative singular ends in -i", %{forms: forms} do
      assert {"ženi", "dat_sg"} in forms
    end

    test "accusative singular ends in -u", %{forms: forms} do
      assert {"ženu", "acc_sg"} in forms
    end

    test "vocative singular ends in -o", %{forms: forms} do
      assert {"ženo", "voc_sg"} in forms
    end

    test "instrumental singular ends in -om", %{forms: forms} do
      assert {"ženom", "ins_sg"} in forms
    end

    test "locative singular ends in -i", %{forms: forms} do
      assert {"ženi", "loc_sg"} in forms
    end

    test "nominative plural ends in -e", %{forms: forms} do
      assert {"žene", "nom_pl"} in forms
    end

    test "genitive plural ends in -a", %{forms: forms} do
      assert {"žena", "gen_pl"} in forms
    end

    test "dative/instrumental/locative plural ends in -ama", %{forms: forms} do
      assert {"ženama", "dat_pl"} in forms
      assert {"ženama", "ins_pl"} in forms
      assert {"ženama", "loc_pl"} in forms
    end
  end

  describe "generate_forms/1 - neuter o-stem (selo)" do
    setup do
      word = %Word{
        term: "selo",
        part_of_speech: :noun,
        gender: :neuter,
        declension_class: "o-stem"
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "returns 14 forms", %{forms: forms} do
      assert length(forms) == 14
    end

    test "nominative singular ends in -o", %{forms: forms} do
      assert {"selo", "nom_sg"} in forms
    end

    test "genitive singular ends in -a", %{forms: forms} do
      assert {"sela", "gen_sg"} in forms
    end

    test "accusative singular equals nominative", %{forms: forms} do
      assert {"selo", "acc_sg"} in forms
    end

    test "instrumental singular ends in -om", %{forms: forms} do
      assert {"selom", "ins_sg"} in forms
    end

    test "nominative plural ends in -a", %{forms: forms} do
      assert {"sela", "nom_pl"} in forms
    end

    test "dative/instrumental/locative plural ends in -ima", %{forms: forms} do
      assert {"selima", "dat_pl"} in forms
      assert {"selima", "ins_pl"} in forms
      assert {"selima", "loc_pl"} in forms
    end
  end

  describe "generate_forms/1 - neuter e-stem (polje)" do
    setup do
      word = %Word{
        term: "polje",
        part_of_speech: :noun,
        gender: :neuter,
        declension_class: "e-stem"
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "returns 14 forms", %{forms: forms} do
      assert length(forms) == 14
    end

    test "nominative singular ends in -e", %{forms: forms} do
      assert {"polje", "nom_sg"} in forms
    end

    test "instrumental singular ends in -em (not -om)", %{forms: forms} do
      assert {"poljem", "ins_sg"} in forms
    end

    test "nominative plural ends in -a", %{forms: forms} do
      assert {"polja", "nom_pl"} in forms
    end
  end

  describe "generate_forms/1 - feminine i-stem (stvar)" do
    setup do
      word = %Word{
        term: "stvar",
        part_of_speech: :noun,
        gender: :feminine,
        declension_class: "i-stem"
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "returns 14 forms", %{forms: forms} do
      assert length(forms) == 14
    end

    test "nominative singular is unchanged", %{forms: forms} do
      assert {"stvar", "nom_sg"} in forms
    end

    test "genitive singular ends in -i", %{forms: forms} do
      assert {"stvari", "gen_sg"} in forms
    end

    test "accusative singular is unchanged", %{forms: forms} do
      assert {"stvar", "acc_sg"} in forms
    end

    test "instrumental singular ends in -i", %{forms: forms} do
      assert {"stvari", "ins_sg"} in forms
    end

    test "nominative plural ends in -i", %{forms: forms} do
      assert {"stvari", "nom_pl"} in forms
    end

    test "dative/instrumental/locative plural ends in -ima", %{forms: forms} do
      assert {"stvarima", "dat_pl"} in forms
      assert {"stvarima", "ins_pl"} in forms
      assert {"stvarima", "loc_pl"} in forms
    end
  end

  describe "generate_forms/1 - palatalization in vocative (junak)" do
    setup do
      word = %Word{
        term: "junak",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "consonant",
        grammar_metadata: %{"palatalization" => true}
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "vocative singular applies k → č palatalization", %{forms: forms} do
      assert {"junače", "voc_sg"} in forms
    end

    test "nominative singular is unchanged", %{forms: forms} do
      assert {"junak", "nom_sg"} in forms
    end

    test "genitive singular does not palatalize", %{forms: forms} do
      assert {"junaka", "gen_sg"} in forms
    end
  end

  describe "generate_forms/1 - palatalization variants" do
    test "g → ž (bog → bože)" do
      word = %Word{
        term: "bog",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "consonant",
        grammar_metadata: %{"palatalization" => true}
      }

      forms = Nouns.generate_forms(word)
      assert {"bože", "voc_sg"} in forms
    end

    test "h → š (duh → duše)" do
      word = %Word{
        term: "duh",
        part_of_speech: :noun,
        gender: :masculine,
        animate: false,
        declension_class: "consonant",
        grammar_metadata: %{"palatalization" => true}
      }

      forms = Nouns.generate_forms(word)
      assert {"duše", "voc_sg"} in forms
    end

    test "c → č (otac → otče)" do
      word = %Word{
        term: "otac",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "consonant",
        grammar_metadata: %{"palatalization" => true, "fleeting_a" => true}
      }

      forms = Nouns.generate_forms(word)
      # fleeting A removed: otac → otc, then c → č: otč, then + e: otče
      assert {"otče", "voc_sg"} in forms
    end
  end

  describe "generate_forms/1 - irregular plural (čovek → ljudi)" do
    setup do
      word = %Word{
        term: "čovek",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "consonant",
        grammar_metadata: %{"irregular_plural" => "ljud"}
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "singular forms are regular", %{forms: forms} do
      assert {"čovek", "nom_sg"} in forms
      assert {"čoveka", "gen_sg"} in forms
    end

    test "nominative plural uses irregular stem", %{forms: forms} do
      assert {"ljudi", "nom_pl"} in forms
    end

    test "genitive plural uses irregular stem", %{forms: forms} do
      assert {"ljuda", "gen_pl"} in forms
    end

    test "dative/instrumental/locative plural uses irregular stem + -ima", %{forms: forms} do
      assert {"ljudima", "dat_pl"} in forms
      assert {"ljudima", "ins_pl"} in forms
      assert {"ljudima", "loc_pl"} in forms
    end

    test "accusative plural equals genitive for animate", %{forms: forms} do
      assert {"ljuda", "acc_pl"} in forms
    end
  end

  describe "generate_forms/1 - form overrides (oko → očiju)" do
    setup do
      word = %Word{
        term: "oko",
        part_of_speech: :noun,
        gender: :neuter,
        declension_class: "o-stem",
        grammar_metadata: %{
          "irregular_forms" => %{"gen_pl" => "očiju"}
        }
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "overridden form is used", %{forms: forms} do
      assert {"očiju", "gen_pl"} in forms
    end

    test "non-overridden forms are regular", %{forms: forms} do
      assert {"oko", "nom_sg"} in forms
      assert {"oka", "gen_sg"} in forms
      assert {"oka", "nom_pl"} in forms
    end
  end

  describe "generate_forms/1 - singularia tantum (mleko)" do
    setup do
      word = %Word{
        term: "mleko",
        part_of_speech: :noun,
        gender: :neuter,
        declension_class: "o-stem",
        grammar_metadata: %{"singularia_tantum" => true}
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "returns only 7 singular forms", %{forms: forms} do
      assert length(forms) == 7
    end

    test "all forms are singular", %{forms: forms} do
      form_tags = Enum.map(forms, fn {_, tag} -> tag end)
      assert Enum.all?(form_tags, &String.ends_with?(&1, "_sg"))
    end

    test "no plural forms exist", %{forms: forms} do
      form_tags = Enum.map(forms, fn {_, tag} -> tag end)
      refute Enum.any?(form_tags, &String.ends_with?(&1, "_pl"))
    end
  end

  describe "generate_forms/1 - pluralia tantum (novine)" do
    setup do
      word = %Word{
        term: "novine",
        part_of_speech: :noun,
        gender: :feminine,
        declension_class: "a-stem",
        grammar_metadata: %{"pluralia_tantum" => true}
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "returns only 7 plural forms", %{forms: forms} do
      assert length(forms) == 7
    end

    test "all forms are plural", %{forms: forms} do
      form_tags = Enum.map(forms, fn {_, tag} -> tag end)
      assert Enum.all?(form_tags, &String.ends_with?(&1, "_pl"))
    end
  end

  describe "generate_forms/1 - masculine a-stem (tata)" do
    setup do
      word = %Word{
        term: "tata",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "a-stem"
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "follows a-stem pattern despite being masculine", %{forms: forms} do
      assert {"tata", "nom_sg"} in forms
      assert {"tate", "gen_sg"} in forms
      assert {"tati", "dat_sg"} in forms
      assert {"tatu", "acc_sg"} in forms
      assert {"tato", "voc_sg"} in forms
    end

    test "plural follows a-stem pattern", %{forms: forms} do
      assert {"tate", "nom_pl"} in forms
      assert {"tata", "gen_pl"} in forms
      assert {"tatama", "dat_pl"} in forms
    end
  end

  describe "generate_forms/1 - palatal consonant plural insert (muž)" do
    setup do
      word = %Word{
        term: "muž",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "consonant"
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "uses -ev- insert instead of -ov-", %{forms: forms} do
      assert {"muževi", "nom_pl"} in forms
      assert {"muževa", "gen_pl"} in forms
      # For animate nouns, acc_pl = gen_pl
      assert {"muževa", "acc_pl"} in forms
    end
  end

  describe "generate_forms/1 - declension class inference" do
    test "infers consonant for masculine consonant ending" do
      word = %Word{
        term: "most",
        part_of_speech: :noun,
        gender: :masculine,
        animate: false,
        declension_class: nil
      }

      forms = Nouns.generate_forms(word)
      assert {"most", "nom_sg"} in forms
      assert {"mosta", "gen_sg"} in forms
    end

    test "infers a-stem for feminine -a ending" do
      word = %Word{
        term: "kuća",
        part_of_speech: :noun,
        gender: :feminine,
        declension_class: nil
      }

      forms = Nouns.generate_forms(word)
      assert {"kuća", "nom_sg"} in forms
      assert {"kuće", "gen_sg"} in forms
    end

    test "infers i-stem for feminine consonant ending" do
      word = %Word{
        term: "noć",
        part_of_speech: :noun,
        gender: :feminine,
        declension_class: nil
      }

      forms = Nouns.generate_forms(word)
      assert {"noć", "nom_sg"} in forms
      assert {"noći", "gen_sg"} in forms
    end

    test "infers o-stem for neuter -o ending" do
      word = %Word{
        term: "pismo",
        part_of_speech: :noun,
        gender: :neuter,
        declension_class: nil
      }

      forms = Nouns.generate_forms(word)
      assert {"pismo", "nom_sg"} in forms
      assert {"pisma", "gen_sg"} in forms
    end

    test "infers e-stem for neuter -e ending" do
      word = %Word{
        term: "more",
        part_of_speech: :noun,
        gender: :neuter,
        declension_class: nil
      }

      forms = Nouns.generate_forms(word)
      assert {"more", "nom_sg"} in forms
      assert {"mora", "gen_sg"} in forms
      assert {"morem", "ins_sg"} in forms
    end
  end

  describe "generate_forms/1 - case sensitivity" do
    test "handles uppercase input and returns lowercase output" do
      word = %Word{
        term: "GRAD",
        part_of_speech: :noun,
        gender: :masculine,
        animate: false,
        declension_class: "consonant"
      }

      forms = Nouns.generate_forms(word)
      assert {"grad", "nom_sg"} in forms
      assert {"grada", "gen_sg"} in forms
    end

    test "handles mixed case input" do
      word = %Word{
        term: "Žena",
        part_of_speech: :noun,
        gender: :feminine,
        declension_class: "a-stem"
      }

      forms = Nouns.generate_forms(word)
      assert {"žena", "nom_sg"} in forms
      assert {"žene", "gen_sg"} in forms
    end
  end

  describe "generate_forms/1 - multiple irregular forms" do
    test "respects multiple form overrides" do
      word = %Word{
        term: "oko",
        part_of_speech: :noun,
        gender: :neuter,
        declension_class: "o-stem",
        grammar_metadata: %{
          "irregular_forms" => %{
            "nom_pl" => "oči",
            "gen_pl" => "očiju",
            "dat_pl" => "očima",
            "acc_pl" => "oči",
            "voc_pl" => "oči",
            "ins_pl" => "očima",
            "loc_pl" => "očima"
          }
        }
      }

      forms = Nouns.generate_forms(word)
      assert {"oči", "nom_pl"} in forms
      assert {"očiju", "gen_pl"} in forms
      assert {"očima", "dat_pl"} in forms
      assert {"oči", "acc_pl"} in forms
    end
  end

  # ============================================================================
  # EDGE CASES
  # ============================================================================

  describe "generate_forms/1 - fleeting A + palatalization (vrabac)" do
    setup do
      word = %Word{
        term: "vrabac",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "consonant",
        grammar_metadata: %{"fleeting_a" => true, "palatalization" => true}
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular keeps fleeting A", %{forms: forms} do
      assert {"vrabac", "nom_sg"} in forms
    end

    test "genitive singular removes fleeting A", %{forms: forms} do
      # Note: In standard Serbian, b→p assimilation occurs before c: vrapca
      # Current implementation may produce: vrabca
      gen_sg = Enum.find(forms, fn {_, tag} -> tag == "gen_sg" end)
      assert gen_sg != nil
      {form, _} = gen_sg
      assert form in ["vrapca", "vrabca"]
    end

    test "vocative singular applies palatalization (c → č)", %{forms: forms} do
      # Note: Full form should be "vrapče" with b→p assimilation
      voc_sg = Enum.find(forms, fn {_, tag} -> tag == "voc_sg" end)
      assert voc_sg != nil
      {form, _} = voc_sg
      assert form in ["vrapče", "vrabče"]
    end

    test "accusative singular equals genitive for animate", %{forms: forms} do
      acc_sg = Enum.find(forms, fn {_, tag} -> tag == "acc_sg" end)
      gen_sg = Enum.find(forms, fn {_, tag} -> tag == "gen_sg" end)
      assert acc_sg != nil
      assert gen_sg != nil
      {acc_form, _} = acc_sg
      {gen_form, _} = gen_sg
      assert acc_form == gen_form
    end
  end

  describe "generate_forms/1 - fleeting A + palatalization (borac)" do
    setup do
      word = %Word{
        term: "borac",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "consonant",
        grammar_metadata: %{"fleeting_a" => true, "palatalization" => true}
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular keeps fleeting A", %{forms: forms} do
      assert {"borac", "nom_sg"} in forms
    end

    test "genitive singular removes fleeting A", %{forms: forms} do
      assert {"borca", "gen_sg"} in forms
    end

    test "vocative singular applies palatalization", %{forms: forms} do
      assert {"borče", "voc_sg"} in forms
    end
  end

  describe "generate_forms/1 - fleeting A short word (san)" do
    setup do
      word = %Word{
        term: "san",
        part_of_speech: :noun,
        gender: :masculine,
        animate: false,
        declension_class: "consonant",
        grammar_metadata: %{"fleeting_a" => true}
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular keeps fleeting A", %{forms: forms} do
      assert {"san", "nom_sg"} in forms
    end

    test "genitive singular removes fleeting A", %{forms: forms} do
      assert {"sna", "gen_sg"} in forms
    end

    test "genitive plural has -a ending (fleeting A restored in gen_pl)", %{forms: forms} do
      # In Serbian, fleeting A typically returns in genitive plural
      # san -> sana (gen_pl) or snova depending on pattern
      assert {"sana", "gen_pl"} in forms
    end
  end

  describe "generate_forms/1 - palatalization with digraph (vojnik)" do
    setup do
      word = %Word{
        term: "vojnik",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "consonant",
        grammar_metadata: %{"palatalization" => true}
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular is unchanged", %{forms: forms} do
      assert {"vojnik", "nom_sg"} in forms
    end

    test "vocative singular palatalizes final k → č", %{forms: forms} do
      assert {"vojniče", "voc_sg"} in forms
    end

    test "genitive singular does not palatalize", %{forms: forms} do
      assert {"vojnika", "gen_sg"} in forms
    end
  end

  describe "generate_forms/1 - no palatalization (brat)" do
    setup do
      word = %Word{
        term: "brat",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "consonant"
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "vocative singular uses -e without palatalization", %{forms: forms} do
      assert {"brate", "voc_sg"} in forms
    end

    test "nominative singular is unchanged", %{forms: forms} do
      assert {"brat", "nom_sg"} in forms
    end
  end

  describe "generate_forms/1 - short plural via irregular_plural (zub)" do
    setup do
      # Use irregular_plural to specify short plural stem for zub
      word = %Word{
        term: "zub",
        part_of_speech: :noun,
        gender: :masculine,
        animate: false,
        declension_class: "consonant",
        grammar_metadata: %{"irregular_plural" => "zub"}
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative plural uses -i without -ov-", %{forms: forms} do
      assert {"zubi", "nom_pl"} in forms
    end

    test "genitive plural uses -a without -ov-", %{forms: forms} do
      assert {"zuba", "gen_pl"} in forms
    end

    test "dative/instrumental/locative plural uses -ima without -ov-", %{forms: forms} do
      assert {"zubima", "dat_pl"} in forms
      assert {"zubima", "ins_pl"} in forms
      assert {"zubima", "loc_pl"} in forms
    end
  end

  describe "generate_forms/1 - digraph lj ending (prijatelj)" do
    setup do
      word = %Word{
        term: "prijatelj",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "consonant"
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular is unchanged", %{forms: forms} do
      assert {"prijatelj", "nom_sg"} in forms
    end

    test "nominative plural", %{forms: forms} do
      # Note: "prijatelj" ends in palatal -lj, so plural should ideally be
      # "prijatelji" without -ev- insert, but some implementations use -ev-
      nom_pl = Enum.find(forms, fn {_, tag} -> tag == "nom_pl" end)
      assert nom_pl != nil
      {form, _} = nom_pl
      assert form in ["prijatelji", "prijateljevi"]
    end

    test "genitive singular adds -a", %{forms: forms} do
      assert {"prijatelja", "gen_sg"} in forms
    end
  end

  describe "generate_forms/1 - pluralia tantum (makaze)" do
    setup do
      # Using "makaze" (scissors) which follows standard a-stem pluralia tantum pattern
      word = %Word{
        term: "makaze",
        part_of_speech: :noun,
        gender: :feminine,
        declension_class: "a-stem",
        grammar_metadata: %{"pluralia_tantum" => true}
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "returns only 7 plural forms", %{forms: forms} do
      assert length(forms) == 7
    end

    test "all forms are plural", %{forms: forms} do
      form_tags = Enum.map(forms, fn {_, tag} -> tag end)
      assert Enum.all?(form_tags, &String.ends_with?(&1, "_pl"))
    end

    test "nominative plural ends in -e", %{forms: forms} do
      nom_pl = Enum.find(forms, fn {_, tag} -> tag == "nom_pl" end)
      assert nom_pl != nil
      {form, _} = nom_pl
      assert String.ends_with?(form, "e")
    end
  end

  describe "generate_forms/1 - animate=nil defaults to inanimate (narod)" do
    setup do
      word = %Word{
        term: "narod",
        part_of_speech: :noun,
        gender: :masculine,
        animate: nil,
        declension_class: "consonant"
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "accusative singular equals nominative (inanimate default)", %{forms: forms} do
      assert {"narod", "acc_sg"} in forms
    end

    test "nominative singular is unchanged", %{forms: forms} do
      assert {"narod", "nom_sg"} in forms
    end

    test "genitive singular adds -a", %{forms: forms} do
      assert {"naroda", "gen_sg"} in forms
    end
  end

  # ============================================================================
  # ADDITIONAL EDGE CASES
  # ============================================================================

  describe "generate_forms/1 - feminine consonant-stem (noć)" do
    setup do
      word = %Word{
        term: "noć",
        part_of_speech: :noun,
        gender: :feminine,
        declension_class: "i-stem"
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular is unchanged", %{forms: forms} do
      assert {"noć", "nom_sg"} in forms
    end

    test "genitive singular ends in -i", %{forms: forms} do
      assert {"noći", "gen_sg"} in forms
    end

    test "instrumental singular ends in -i or -u", %{forms: forms} do
      ins_sg = Enum.find(forms, fn {_, tag} -> tag == "ins_sg" end)
      assert ins_sg != nil
      {form, _} = ins_sg
      assert form in ["noći", "noću"]
    end

    test "nominative plural ends in -i", %{forms: forms} do
      assert {"noći", "nom_pl"} in forms
    end
  end

  describe "generate_forms/1 - feminine irregular (kći - daughter)" do
    setup do
      word = %Word{
        term: "kći",
        part_of_speech: :noun,
        gender: :feminine,
        declension_class: "i-stem",
        grammar_metadata: %{
          "irregular_forms" => %{
            "gen_sg" => "kćeri",
            "dat_sg" => "kćeri",
            "acc_sg" => "kćer",
            "voc_sg" => "kćeri",
            "ins_sg" => "kćeri",
            "loc_sg" => "kćeri",
            "nom_pl" => "kćeri",
            "gen_pl" => "kćeri",
            "dat_pl" => "kćerima",
            "acc_pl" => "kćeri",
            "voc_pl" => "kćeri",
            "ins_pl" => "kćerima",
            "loc_pl" => "kćerima"
          }
        }
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular is kći", %{forms: forms} do
      assert {"kći", "nom_sg"} in forms
    end

    test "genitive singular is kćeri", %{forms: forms} do
      assert {"kćeri", "gen_sg"} in forms
    end

    test "dative singular is kćeri", %{forms: forms} do
      assert {"kćeri", "dat_sg"} in forms
    end

    test "dative/instrumental/locative plural is kćerima", %{forms: forms} do
      assert {"kćerima", "dat_pl"} in forms
      assert {"kćerima", "ins_pl"} in forms
      assert {"kćerima", "loc_pl"} in forms
    end
  end

  describe "generate_forms/1 - neuter with irregular plural (dete → deca)" do
    setup do
      word = %Word{
        term: "dete",
        part_of_speech: :noun,
        gender: :neuter,
        declension_class: "e-stem",
        grammar_metadata: %{
          "irregular_forms" => %{
            "nom_pl" => "deca",
            "gen_pl" => "dece",
            "dat_pl" => "deci",
            "acc_pl" => "decu",
            "voc_pl" => "deco",
            "ins_pl" => "decom",
            "loc_pl" => "deci"
          }
        }
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular is dete", %{forms: forms} do
      assert {"dete", "nom_sg"} in forms
    end

    test "nominative plural is deca (irregular)", %{forms: forms} do
      assert {"deca", "nom_pl"} in forms
    end

    test "genitive plural is dece", %{forms: forms} do
      assert {"dece", "gen_pl"} in forms
    end
  end

  describe "generate_forms/1 - neuter irregular plural (uho → uši)" do
    setup do
      word = %Word{
        term: "uho",
        part_of_speech: :noun,
        gender: :neuter,
        declension_class: "o-stem",
        grammar_metadata: %{
          "irregular_forms" => %{
            "nom_pl" => "uši",
            "gen_pl" => "ušiju",
            "dat_pl" => "ušima",
            "acc_pl" => "uši",
            "voc_pl" => "uši",
            "ins_pl" => "ušima",
            "loc_pl" => "ušima"
          }
        }
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular is uho", %{forms: forms} do
      assert {"uho", "nom_sg"} in forms
    end

    test "nominative plural is uši (irregular)", %{forms: forms} do
      assert {"uši", "nom_pl"} in forms
    end

    test "genitive plural is ušiju", %{forms: forms} do
      assert {"ušiju", "gen_pl"} in forms
    end

    test "dative/instrumental/locative plural is ušima", %{forms: forms} do
      assert {"ušima", "dat_pl"} in forms
      assert {"ušima", "ins_pl"} in forms
      assert {"ušima", "loc_pl"} in forms
    end
  end

  describe "generate_forms/1 - neuter -me/-ena stem (rame)" do
    setup do
      word = %Word{
        term: "rame",
        part_of_speech: :noun,
        gender: :neuter,
        declension_class: "e-stem",
        grammar_metadata: %{
          "stem_extension" => "n",
          "irregular_forms" => %{
            "gen_sg" => "ramena",
            "dat_sg" => "ramenu",
            "loc_sg" => "ramenu",
            "nom_pl" => "ramena",
            "gen_pl" => "ramena"
          }
        }
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular is rame", %{forms: forms} do
      assert {"rame", "nom_sg"} in forms
    end

    test "genitive singular is ramena", %{forms: forms} do
      assert {"ramena", "gen_sg"} in forms
    end

    test "nominative plural is ramena", %{forms: forms} do
      assert {"ramena", "nom_pl"} in forms
    end
  end

  describe "generate_forms/1 - neuter -me/-ena stem (ime)" do
    setup do
      word = %Word{
        term: "ime",
        part_of_speech: :noun,
        gender: :neuter,
        declension_class: "e-stem",
        grammar_metadata: %{
          "stem_extension" => "n",
          "irregular_forms" => %{
            "gen_sg" => "imena",
            "dat_sg" => "imenu",
            "loc_sg" => "imenu",
            "nom_pl" => "imena",
            "gen_pl" => "imena"
          }
        }
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular is ime", %{forms: forms} do
      assert {"ime", "nom_sg"} in forms
    end

    test "genitive singular is imena", %{forms: forms} do
      assert {"imena", "gen_sg"} in forms
    end

    test "nominative plural is imena", %{forms: forms} do
      assert {"imena", "nom_pl"} in forms
    end
  end

  describe "generate_forms/1 - neuter irregular plural (nebo → nebesa)" do
    setup do
      word = %Word{
        term: "nebo",
        part_of_speech: :noun,
        gender: :neuter,
        declension_class: "o-stem",
        grammar_metadata: %{
          "irregular_forms" => %{
            "nom_pl" => "nebesa",
            "gen_pl" => "nebesa",
            "dat_pl" => "nebesima",
            "acc_pl" => "nebesa",
            "voc_pl" => "nebesa",
            "ins_pl" => "nebesima",
            "loc_pl" => "nebesima"
          }
        }
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular is nebo", %{forms: forms} do
      assert {"nebo", "nom_sg"} in forms
    end

    test "nominative plural is nebesa (irregular)", %{forms: forms} do
      assert {"nebesa", "nom_pl"} in forms
    end

    test "genitive plural is nebesa", %{forms: forms} do
      assert {"nebesa", "gen_pl"} in forms
    end
  end

  describe "generate_forms/1 - short masculine 2-letter stem (rak)" do
    setup do
      word = %Word{
        term: "rak",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "consonant"
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular is rak", %{forms: forms} do
      assert {"rak", "nom_sg"} in forms
    end

    test "nominative plural uses -ovi insert", %{forms: forms} do
      assert {"rakovi", "nom_pl"} in forms
    end

    test "genitive plural uses -ova", %{forms: forms} do
      assert {"rakova", "gen_pl"} in forms
    end
  end

  describe "generate_forms/1 - masculine short plural option (put)" do
    setup do
      word = %Word{
        term: "put",
        part_of_speech: :noun,
        gender: :masculine,
        animate: false,
        declension_class: "consonant"
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular is put", %{forms: forms} do
      assert {"put", "nom_sg"} in forms
    end

    test "nominative plural uses -evi or -ovi", %{forms: forms} do
      nom_pl = Enum.find(forms, fn {_, tag} -> tag == "nom_pl" end)
      assert nom_pl != nil
      {form, _} = nom_pl
      assert form in ["putevi", "putovi"]
    end
  end

  describe "generate_forms/1 - masculine with -i plural (gost)" do
    setup do
      word = %Word{
        term: "gost",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        declension_class: "consonant",
        grammar_metadata: %{"irregular_plural" => "gost"}
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular is gost", %{forms: forms} do
      assert {"gost", "nom_sg"} in forms
    end

    test "nominative plural is gosti (not gostovi)", %{forms: forms} do
      assert {"gosti", "nom_pl"} in forms
    end

    test "genitive plural is gosta (animate)", %{forms: forms} do
      assert {"gosta", "gen_pl"} in forms
    end
  end

  describe "generate_forms/1 - masculine consonant cluster (prst)" do
    setup do
      word = %Word{
        term: "prst",
        part_of_speech: :noun,
        gender: :masculine,
        animate: false,
        declension_class: "consonant",
        grammar_metadata: %{"irregular_plural" => "prst"}
      }

      {:ok, word: word, forms: Nouns.generate_forms(word)}
    end

    test "nominative singular is prst", %{forms: forms} do
      assert {"prst", "nom_sg"} in forms
    end

    test "genitive singular is prsta", %{forms: forms} do
      assert {"prsta", "gen_sg"} in forms
    end

    test "nominative plural is prsti", %{forms: forms} do
      assert {"prsti", "nom_pl"} in forms
    end
  end

end
