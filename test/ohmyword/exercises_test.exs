defmodule Ohmyword.ExercisesTest do
  use Ohmyword.DataCase, async: true

  alias Ohmyword.Exercises
  alias Ohmyword.Exercises.Sentence

  import Ohmyword.ExercisesFixtures
  import Ohmyword.VocabularyFixtures

  describe "list_sentences/1" do
    test "returns all sentences when no filters" do
      sentence1 = sentence_fixture()
      sentence2 = sentence_fixture()

      sentences = Exercises.list_sentences()

      assert length(sentences) == 2
      ids = Enum.map(sentences, & &1.id)
      assert sentence1.id in ids
      assert sentence2.id in ids
    end

    test "filters by word_id" do
      word1 = noun_fixture()
      word2 = noun_fixture()
      sentence1 = sentence_fixture(%{word: word1})
      _sentence2 = sentence_fixture(%{word: word2})

      sentences = Exercises.list_sentences(word_id: word1.id)

      assert length(sentences) == 1
      assert hd(sentences).id == sentence1.id
    end

    test "filters by part_of_speech" do
      noun = noun_fixture()
      verb = verb_fixture()
      sentence_noun = sentence_fixture(%{word: noun})
      _sentence_verb = sentence_fixture(%{word: verb})

      sentences = Exercises.list_sentences(part_of_speech: :noun)

      assert length(sentences) == 1
      assert hd(sentences).id == sentence_noun.id
    end

    test "preloads word association" do
      sentence = sentence_fixture()

      [fetched] = Exercises.list_sentences()

      assert fetched.id == sentence.id
      assert %Ohmyword.Vocabulary.Word{} = fetched.word
    end
  end

  describe "get_sentence!/1" do
    test "returns the sentence with given id" do
      sentence = sentence_fixture()

      fetched = Exercises.get_sentence!(sentence.id)

      assert fetched.id == sentence.id
      assert fetched.text == sentence.text
    end

    test "preloads word association" do
      sentence = sentence_fixture()

      fetched = Exercises.get_sentence!(sentence.id)

      assert %Ohmyword.Vocabulary.Word{} = fetched.word
    end

    test "raises Ecto.NoResultsError for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Exercises.get_sentence!(0)
      end
    end
  end

  describe "get_random_sentence/1" do
    test "returns a sentence when sentences exist" do
      sentence_fixture()
      assert %Sentence{} = Exercises.get_random_sentence()
    end

    test "returns nil when no sentences exist" do
      assert Exercises.get_random_sentence() == nil
    end

    test "filters by part_of_speech" do
      noun = noun_fixture()
      verb = verb_fixture()
      sentence_noun = sentence_fixture(%{word: noun})
      _sentence_verb = sentence_fixture(%{word: verb})

      # Run multiple times to increase confidence
      for _ <- 1..10 do
        result = Exercises.get_random_sentence(part_of_speech: :noun)
        assert result.id == sentence_noun.id
      end
    end

    test "preloads word association" do
      sentence_fixture()

      result = Exercises.get_random_sentence()

      assert %Ohmyword.Vocabulary.Word{} = result.word
    end
  end

  describe "create_sentence/1" do
    test "creates a sentence with valid attrs" do
      word = noun_fixture()

      attrs = %{
        text: "Imam {blank}.",
        translation: "I have a thing.",
        blank_form_tag: "acc_sg",
        word_id: word.id
      }

      assert {:ok, %Sentence{} = sentence} = Exercises.create_sentence(attrs)
      assert sentence.text == "Imam {blank}."
      assert sentence.translation == "I have a thing."
      assert sentence.blank_form_tag == "acc_sg"
      assert sentence.word_id == word.id
    end

    test "creates a sentence with optional hint" do
      word = noun_fixture()

      attrs = %{
        text: "Vidim {blank}.",
        translation: "I see.",
        blank_form_tag: "acc_sg",
        hint: "accusative singular",
        word_id: word.id
      }

      assert {:ok, %Sentence{} = sentence} = Exercises.create_sentence(attrs)
      assert sentence.hint == "accusative singular"
    end

    test "returns error when text missing {blank}" do
      word = noun_fixture()

      attrs = %{
        text: "No blank here.",
        translation: "Test",
        blank_form_tag: "acc_sg",
        word_id: word.id
      }

      assert {:error, changeset} = Exercises.create_sentence(attrs)
      assert "must contain {blank} placeholder" in errors_on(changeset).text
    end

    test "returns error for missing required fields" do
      assert {:error, changeset} = Exercises.create_sentence(%{})
      assert errors_on(changeset).text
      assert errors_on(changeset).translation
      assert errors_on(changeset).blank_form_tag
      assert errors_on(changeset).word_id
    end
  end

  describe "update_sentence/2" do
    test "updates the sentence with valid attrs" do
      sentence = sentence_fixture()

      assert {:ok, updated} = Exercises.update_sentence(sentence, %{translation: "updated"})
      assert updated.translation == "updated"
    end

    test "returns error for invalid attrs" do
      sentence = sentence_fixture()
      assert {:error, %Ecto.Changeset{}} = Exercises.update_sentence(sentence, %{text: nil})
    end
  end

  describe "delete_sentence/1" do
    test "deletes the sentence" do
      sentence = sentence_fixture()
      assert {:ok, %Sentence{}} = Exercises.delete_sentence(sentence)

      assert_raise Ecto.NoResultsError, fn ->
        Exercises.get_sentence!(sentence.id)
      end
    end
  end

  describe "check_answer/2" do
    test "returns correct when input matches expected form exactly" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      assert {:correct, "psa"} = Exercises.check_answer(sentence, "psa")
    end

    test "returns correct for case-insensitive match" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      assert {:correct, "psa"} = Exercises.check_answer(sentence, "PSA")
    end

    test "returns correct for diacritic-insensitive match" do
      word = noun_fixture(%{term: "čovek"})

      search_term_fixture(%{
        word: word,
        term: "coveka",
        display_form: "čoveka",
        form_tag: "acc_sg"
      })

      sentence = sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      assert {:correct, "čoveka"} = Exercises.check_answer(sentence, "coveka")
    end

    test "returns correct for cyrillic input matching latin form" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      assert {:correct, "psa"} = Exercises.check_answer(sentence, "пса")
    end

    test "returns incorrect with expected forms when no match" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      assert {:incorrect, ["psa"]} = Exercises.check_answer(sentence, "wrong")
    end

    test "returns error when no forms found" do
      word = noun_fixture(%{term: "pas"})
      sentence = sentence_fixture(%{word: word, blank_form_tag: "nonexistent_tag"})

      assert {:error, :no_forms} = Exercises.check_answer(sentence, "anything")
    end

    test "trims whitespace from input" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      assert {:correct, "psa"} = Exercises.check_answer(sentence, "  psa  ")
    end
  end

  describe "get_expected_forms/1" do
    test "returns display forms for matching form_tag" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      assert ["psa"] = Exercises.get_expected_forms(sentence)
    end

    test "returns multiple forms when multiple search terms match" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "pasa", display_form: "pasa", form_tag: "gen_sg"})
      search_term_fixture(%{word: word, term: "pasa2", display_form: "pasa", form_tag: "gen_sg"})
      sentence = sentence_fixture(%{word: word, blank_form_tag: "gen_sg"})

      forms = Exercises.get_expected_forms(sentence)
      assert length(forms) == 2
    end

    test "returns empty list when no forms match" do
      word = noun_fixture(%{term: "pas"})
      sentence = sentence_fixture(%{word: word, blank_form_tag: "nonexistent"})

      assert [] = Exercises.get_expected_forms(sentence)
    end

    test "is case insensitive for form_tag" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_fixture(%{word: word, blank_form_tag: "ACC_SG"})

      assert ["psa"] = Exercises.get_expected_forms(sentence)
    end
  end

  describe "list_available_parts_of_speech/0" do
    test "returns empty list when no sentences exist" do
      assert Exercises.list_available_parts_of_speech() == []
    end

    test "returns distinct parts of speech sorted" do
      noun = noun_fixture()
      verb = verb_fixture()
      sentence_fixture(%{word: noun})
      sentence_fixture(%{word: verb})

      result = Exercises.list_available_parts_of_speech()

      assert result == [:noun, :verb]
    end

    test "does not include POS without sentences" do
      noun = noun_fixture()
      _verb = verb_fixture()
      sentence_fixture(%{word: noun})

      result = Exercises.list_available_parts_of_speech()

      assert result == [:noun]
    end
  end
end
