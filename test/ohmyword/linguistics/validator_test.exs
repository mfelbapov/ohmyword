defmodule Ohmyword.Linguistics.ValidatorTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Linguistics.Validator

  describe "validate/1" do
    test "returns passed result when all forms match" do
      # Use an invariable word (conjunction) for simplicity — engine returns single form
      entry = %{
        "term" => "i",
        "translation" => "and",
        "part_of_speech" => "conjunction",
        "forms" => [%{"term" => "i", "form_tag" => "invariable"}]
      }

      result = Validator.validate(entry)

      assert result.passed == true
      assert result.term == "i"
      assert result.part_of_speech == "conjunction"
      assert result.missing == []
      assert result.wrong == []
      assert result.extra == []
      assert result.expected_count == 1
      assert result.engine_count == 1
    end

    test "detects missing forms" do
      # Provide a form tag the engine won't generate
      entry = %{
        "term" => "i",
        "translation" => "and",
        "part_of_speech" => "conjunction",
        "forms" => [
          %{"term" => "i", "form_tag" => "invariable"},
          %{"term" => "ix", "form_tag" => "fake_tag"}
        ]
      }

      result = Validator.validate(entry)

      assert result.passed == false
      assert {"ix", "fake_tag"} in result.missing
    end

    test "detects wrong forms" do
      # Provide the right tag but wrong term
      entry = %{
        "term" => "i",
        "translation" => "and",
        "part_of_speech" => "conjunction",
        "forms" => [%{"term" => "wrong_form", "form_tag" => "invariable"}]
      }

      result = Validator.validate(entry)

      assert result.passed == false
      assert {"invariable", "wrong_form", "i"} in result.wrong
    end

    test "detects extra forms without failing" do
      # Provide fewer forms than engine generates
      entry = %{
        "term" => "ali",
        "translation" => "but",
        "part_of_speech" => "conjunction",
        "forms" => []
      }

      result = Validator.validate(entry)

      # Extra forms alone don't cause failure
      assert result.passed == true
      assert result.extra != [] || result.engine_count == 0
    end

    test "handles entry with no forms key" do
      entry = %{
        "term" => "i",
        "translation" => "and",
        "part_of_speech" => "conjunction"
      }

      result = Validator.validate(entry)

      # No expected forms, so nothing can be missing or wrong
      assert result.passed == true
      assert result.missing == []
      assert result.wrong == []
    end
  end

  describe "build_word_struct/1" do
    test "converts string-keyed map to Word struct" do
      entry = %{
        "term" => "pas",
        "translation" => "dog",
        "part_of_speech" => "noun",
        "gender" => "masculine",
        "animate" => true,
        "declension_class" => "consonant",
        "grammar_metadata" => %{"fleeting_a" => true}
      }

      word = Validator.build_word_struct(entry)

      assert word.term == "pas"
      assert word.translation == "dog"
      assert word.part_of_speech == :noun
      assert word.gender == :masculine
      assert word.animate == true
      assert word.declension_class == "consonant"
      assert word.grammar_metadata == %{"fleeting_a" => true}
    end

    test "handles nil optional fields" do
      entry = %{
        "term" => "ali",
        "translation" => "but",
        "part_of_speech" => "conjunction"
      }

      word = Validator.build_word_struct(entry)

      assert word.term == "ali"
      assert word.part_of_speech == :conjunction
      assert word.gender == nil
      assert word.verb_aspect == nil
      assert word.grammar_metadata == %{}
    end

    test "converts verb fields correctly" do
      entry = %{
        "term" => "pisati",
        "translation" => "to write",
        "part_of_speech" => "verb",
        "verb_aspect" => "imperfective",
        "conjugation_class" => "je_verb",
        "reflexive" => false,
        "grammar_metadata" => %{"present_stem" => "piš"}
      }

      word = Validator.build_word_struct(entry)

      assert word.part_of_speech == :verb
      assert word.verb_aspect == :imperfective
      assert word.conjugation_class == "je_verb"
      assert word.reflexive == false
      assert word.grammar_metadata == %{"present_stem" => "piš"}
    end
  end

  describe "compare_forms/2" do
    test "returns empty lists when forms match exactly" do
      forms = [{"kuća", "nom_sg"}, {"kuće", "gen_sg"}]
      result = Validator.compare_forms(forms, forms)

      assert result.missing == []
      assert result.wrong == []
      assert result.extra == []
    end

    test "finds missing forms" do
      expected = [{"kuća", "nom_sg"}, {"kuće", "gen_sg"}]
      engine = [{"kuća", "nom_sg"}]

      result = Validator.compare_forms(expected, engine)

      assert {"kuće", "gen_sg"} in result.missing
      assert result.wrong == []
    end

    test "finds wrong forms" do
      expected = [{"kuća", "nom_sg"}, {"kuće", "gen_sg"}]
      engine = [{"kuća", "nom_sg"}, {"kuce", "gen_sg"}]

      result = Validator.compare_forms(expected, engine)

      assert result.missing == []
      assert {"gen_sg", "kuće", "kuce"} in result.wrong
    end

    test "finds extra forms" do
      expected = [{"kuća", "nom_sg"}]
      engine = [{"kuća", "nom_sg"}, {"kuće", "gen_sg"}]

      result = Validator.compare_forms(expected, engine)

      assert result.missing == []
      assert result.wrong == []
      assert {"kuće", "gen_sg"} in result.extra
    end

    test "handles all three discrepancy types at once" do
      expected = [{"kuća", "nom_sg"}, {"kuće", "gen_sg"}, {"kući", "dat_sg"}]
      engine = [{"kuća", "nom_sg"}, {"kuce", "gen_sg"}, {"kuću", "acc_sg"}]

      result = Validator.compare_forms(expected, engine)

      # dat_sg is missing from engine
      assert {"kući", "dat_sg"} in result.missing
      # gen_sg has different term
      assert {"gen_sg", "kuće", "kuce"} in result.wrong
      # acc_sg is extra in engine
      assert {"kuću", "acc_sg"} in result.extra
    end
  end

  describe "format_result/1" do
    test "formats passing result" do
      result = %{
        term: "kuća",
        part_of_speech: "noun",
        passed: true,
        missing: [],
        wrong: [],
        extra: [],
        expected_count: 14,
        engine_count: 14
      }

      assert Validator.format_result(result) == "kuća (noun): PASS (14 forms)"
    end

    test "formats failing result with missing forms" do
      result = %{
        term: "kuća",
        part_of_speech: "noun",
        passed: false,
        missing: [{"kući", "dat_sg"}],
        wrong: [],
        extra: [],
        expected_count: 14,
        engine_count: 13
      }

      output = Validator.format_result(result)

      assert output =~ "kuća (noun): FAIL"
      assert output =~ "MISSING: dat_sg=kući"
      refute output =~ "WRONG:"
    end

    test "formats failing result with wrong forms" do
      result = %{
        term: "kuća",
        part_of_speech: "noun",
        passed: false,
        missing: [],
        wrong: [{"gen_sg", "kuće", "kuce"}],
        extra: [],
        expected_count: 14,
        engine_count: 14
      }

      output = Validator.format_result(result)

      assert output =~ "WRONG: gen_sg: expected 'kuće', got 'kuce'"
      refute output =~ "MISSING:"
    end

    test "formats result with extra forms" do
      result = %{
        term: "kuća",
        part_of_speech: "noun",
        passed: false,
        missing: [{"kući", "dat_sg"}],
        wrong: [],
        extra: [{"kuću", "acc_sg"}],
        expected_count: 14,
        engine_count: 14
      }

      output = Validator.format_result(result)

      assert output =~ "EXTRA (info): acc_sg=kuću"
    end
  end
end
