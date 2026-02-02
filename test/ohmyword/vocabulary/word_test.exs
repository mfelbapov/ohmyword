defmodule Ohmyword.Vocabulary.WordTest do
  use Ohmyword.DataCase, async: true

  alias Ohmyword.Vocabulary.Word

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{
        term: "brzo",
        translation: "quickly",
        part_of_speech: :adverb
      }

      changeset = Word.changeset(%Word{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset without required fields" do
      changeset = Word.changeset(%Word{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).term
      assert "can't be blank" in errors_on(changeset).translation
      assert "can't be blank" in errors_on(changeset).part_of_speech
    end

    test "noun without gender fails validation" do
      attrs = %{
        term: "pas",
        translation: "dog",
        part_of_speech: :noun
      }

      changeset = Word.changeset(%Word{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).gender
    end

    test "noun with gender creates successfully" do
      attrs = %{
        term: "zena",
        translation: "woman",
        part_of_speech: :noun,
        gender: :feminine
      }

      changeset = Word.changeset(%Word{}, attrs)
      assert changeset.valid?
    end

    test "masculine noun without animate fails validation" do
      attrs = %{
        term: "pas",
        translation: "dog",
        part_of_speech: :noun,
        gender: :masculine
      }

      changeset = Word.changeset(%Word{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).animate
    end

    test "masculine noun with animate creates successfully" do
      attrs = %{
        term: "pas",
        translation: "dog",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true
      }

      changeset = Word.changeset(%Word{}, attrs)
      assert changeset.valid?
    end

    test "feminine noun does not require animate" do
      attrs = %{
        term: "zena",
        translation: "woman",
        part_of_speech: :noun,
        gender: :feminine
      }

      changeset = Word.changeset(%Word{}, attrs)
      assert changeset.valid?
    end

    test "adjective without gender fails validation" do
      attrs = %{
        term: "dobar",
        translation: "good",
        part_of_speech: :adjective
      }

      changeset = Word.changeset(%Word{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).gender
    end

    test "adjective with gender creates successfully" do
      attrs = %{
        term: "dobar",
        translation: "good",
        part_of_speech: :adjective,
        gender: :masculine
      }

      changeset = Word.changeset(%Word{}, attrs)
      assert changeset.valid?
    end

    test "pronoun without gender fails validation" do
      attrs = %{
        term: "on",
        translation: "he",
        part_of_speech: :pronoun
      }

      changeset = Word.changeset(%Word{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).gender
    end

    test "verb without aspect fails validation" do
      attrs = %{
        term: "pisati",
        translation: "to write",
        part_of_speech: :verb
      }

      changeset = Word.changeset(%Word{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).verb_aspect
    end

    test "verb with aspect creates successfully" do
      attrs = %{
        term: "pisati",
        translation: "to write",
        part_of_speech: :verb,
        verb_aspect: :imperfective
      }

      changeset = Word.changeset(%Word{}, attrs)
      assert changeset.valid?
    end

    test "proficiency level must be between 1 and 9" do
      base_attrs = %{
        term: "brzo",
        translation: "quickly",
        part_of_speech: :adverb
      }

      # Valid range
      changeset = Word.changeset(%Word{}, Map.put(base_attrs, :proficiency_level, 1))
      assert changeset.valid?

      changeset = Word.changeset(%Word{}, Map.put(base_attrs, :proficiency_level, 5))
      assert changeset.valid?

      # Invalid: 0 or less
      changeset = Word.changeset(%Word{}, Map.put(base_attrs, :proficiency_level, 0))
      refute changeset.valid?

      # Invalid: 10 or more
      changeset = Word.changeset(%Word{}, Map.put(base_attrs, :proficiency_level, 10))
      refute changeset.valid?
    end

    test "empty translations array is valid" do
      attrs = %{
        term: "brzo",
        translation: "quickly",
        part_of_speech: :adverb,
        translations: []
      }

      changeset = Word.changeset(%Word{}, attrs)
      assert changeset.valid?
    end

    test "translations array with values is valid" do
      attrs = %{
        term: "stan",
        translation: "apartment",
        part_of_speech: :noun,
        gender: :masculine,
        animate: false,
        translations: ["flat", "dwelling"]
      }

      changeset = Word.changeset(%Word{}, attrs)
      assert changeset.valid?
    end

    test "grammar_metadata accepts arbitrary maps" do
      attrs = %{
        term: "pas",
        translation: "dog",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        grammar_metadata: %{
          "fleeting_a" => true,
          "irregular_forms" => %{"gen_pl" => "pasa"}
        }
      }

      changeset = Word.changeset(%Word{}, attrs)
      assert changeset.valid?
    end

    test "categories array is valid" do
      attrs = %{
        term: "pas",
        translation: "dog",
        part_of_speech: :noun,
        gender: :masculine,
        animate: true,
        categories: ["animals", "pets"]
      }

      changeset = Word.changeset(%Word{}, attrs)
      assert changeset.valid?
    end
  end
end
