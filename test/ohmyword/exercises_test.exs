defmodule Ohmyword.ExercisesTest do
  use Ohmyword.DataCase, async: true

  alias Ohmyword.Exercises
  alias Ohmyword.Exercises.Sentence

  import Ohmyword.ExercisesFixtures
  import Ohmyword.VocabularyFixtures

  describe "tokenize/1" do
    test "splits sentence into word tokens" do
      assert Exercises.tokenize("Vidim velikog psa.") == ["Vidim", "velikog", "psa"]
    end

    test "handles punctuation" do
      assert Exercises.tokenize("Da, to je on!") == ["Da", "to", "je", "on"]
    end

    test "handles diacritical characters" do
      assert Exercises.tokenize("Čitam knjigu.") == ["Čitam", "knjigu"]
    end
  end

  describe "get_sentence!/1" do
    test "returns the sentence with preloaded sentence_words" do
      sentence = sentence_fixture()
      fetched = Exercises.get_sentence!(sentence.id)
      assert fetched.id == sentence.id
      assert is_list(fetched.sentence_words)
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

    test "filters by part_of_speech through sentence_words" do
      noun = noun_fixture()
      verb = verb_fixture()
      sentence_with_words_fixture(%{word: noun, text_rs: "Vidim psa.", position: 1})
      sentence_with_words_fixture(%{word: verb, text_rs: "Pisem tekst.", position: 0})

      for _ <- 1..10 do
        result = Exercises.get_random_sentence(part_of_speech: :noun)
        assert result != nil
        word_ids = Enum.map(result.sentence_words, & &1.word_id)
        assert noun.id in word_ids
      end
    end

    test "preloads sentence_words and their words" do
      sentence_with_words_fixture()
      result = Exercises.get_random_sentence()
      assert is_list(result.sentence_words)

      for sw <- result.sentence_words do
        assert %Ohmyword.Vocabulary.Word{} = sw.word
      end
    end
  end

  describe "create_sentence/1" do
    test "creates a sentence with valid attrs" do
      attrs = %{text_rs: "Nova rečenica.", text_en: "New sentence."}
      assert {:ok, %Sentence{} = sentence} = Exercises.create_sentence(attrs)
      assert sentence.text_rs == "Nova rečenica."
      assert sentence.text_en == "New sentence."
    end

    test "returns error for missing required fields" do
      assert {:error, changeset} = Exercises.create_sentence(%{})
      assert errors_on(changeset).text_rs
      assert errors_on(changeset).text_en
    end
  end

  describe "get_sentences_for_word/2" do
    test "returns sentences containing the given word" do
      word = noun_fixture(%{term: "pas"})
      s = sentence_with_words_fixture(%{word: word})

      result = Exercises.get_sentences_for_word(word.id)
      assert length(result) == 1
      assert hd(result).id == s.id
    end

    test "respects limit option" do
      word = noun_fixture(%{term: "pas"})
      sentence_with_words_fixture(%{word: word, text_rs: "Sentence one.", text_en: "One."})
      sentence_with_words_fixture(%{word: word, text_rs: "Sentence two.", text_en: "Two."})

      result = Exercises.get_sentences_for_word(word.id, limit: 1)
      assert length(result) == 1
    end

    test "returns empty list when word has no sentences" do
      word = noun_fixture()
      assert Exercises.get_sentences_for_word(word.id) == []
    end
  end

  describe "get_sentence_map_for_words/1" do
    test "returns map of word_id to sentences" do
      word1 = noun_fixture(%{term: "pas"})
      word2 = noun_fixture(%{term: "mačka"})
      sentence_with_words_fixture(%{word: word1, text_rs: "Vidim psa.", text_en: "I see a dog."})

      sentence_with_words_fixture(%{
        word: word2,
        text_rs: "Vidim mačku.",
        text_en: "I see a cat."
      })

      result = Exercises.get_sentence_map_for_words([word1.id, word2.id])

      assert Map.has_key?(result, word1.id)
      assert Map.has_key?(result, word2.id)
    end

    test "returns empty map for empty input" do
      assert Exercises.get_sentence_map_for_words([]) == %{}
    end
  end

  describe "select_blanks/2" do
    test "difficulty 1 returns one blank" do
      word = noun_fixture(%{term: "pas"})
      sentence = sentence_with_words_fixture(%{word: word})
      # Add a second word
      word2 = noun_fixture(%{term: "mačka"})
      sentence_word_fixture(%{sentence: sentence, word: word2, position: 2, form_tag: "nom_sg"})
      sentence = Repo.preload(sentence, [sentence_words: :word], force: true)

      blanks = Exercises.select_blanks(sentence, 1)
      assert length(blanks) == 1
    end

    test "difficulty 3 returns all blanks" do
      word = noun_fixture(%{term: "pas"})
      sentence = sentence_with_words_fixture(%{word: word})
      blanks = Exercises.select_blanks(sentence, 3)
      assert length(blanks) == length(sentence.sentence_words)
    end

    test "difficulty 2 returns approximately half" do
      word = noun_fixture(%{term: "pas"})
      sentence = sentence_with_words_fixture(%{word: word})
      # Add more words
      word2 = noun_fixture(%{term: "mačka"})
      word3 = verb_fixture(%{term: "gledati"})
      word4 = noun_fixture(%{term: "kuća"})
      sentence_word_fixture(%{sentence: sentence, word: word2, position: 2, form_tag: "nom_sg"})
      sentence_word_fixture(%{sentence: sentence, word: word3, position: 3, form_tag: "pres_1sg"})
      sentence_word_fixture(%{sentence: sentence, word: word4, position: 4, form_tag: "acc_sg"})
      sentence = Repo.preload(sentence, [sentence_words: :word], force: true)

      blanks = Exercises.select_blanks(sentence, 2)
      assert length(blanks) >= 1
      assert length(blanks) <= length(sentence.sentence_words)
    end
  end

  describe "check_answer/2" do
    test "returns correct when input matches expected form" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_with_words_fixture(%{word: word, form_tag: "acc_sg"})

      sw = hd(sentence.sentence_words)
      assert {:correct, "psa"} = Exercises.check_answer(sw, "psa")
    end

    test "returns correct for case-insensitive match" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_with_words_fixture(%{word: word, form_tag: "acc_sg"})

      sw = hd(sentence.sentence_words)
      assert {:correct, "psa"} = Exercises.check_answer(sw, "PSA")
    end

    test "returns correct for diacritic-insensitive match" do
      word = noun_fixture(%{term: "čovek"})

      search_term_fixture(%{
        word: word,
        term: "coveka",
        display_form: "čoveka",
        form_tag: "acc_sg"
      })

      sentence = sentence_with_words_fixture(%{word: word, form_tag: "acc_sg"})

      sw = hd(sentence.sentence_words)
      assert {:correct, "čoveka"} = Exercises.check_answer(sw, "coveka")
    end

    test "returns correct for cyrillic input" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_with_words_fixture(%{word: word, form_tag: "acc_sg"})

      sw = hd(sentence.sentence_words)
      assert {:correct, "psa"} = Exercises.check_answer(sw, "пса")
    end

    test "returns incorrect with expected forms when no match" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_with_words_fixture(%{word: word, form_tag: "acc_sg"})

      sw = hd(sentence.sentence_words)
      assert {:incorrect, ["psa"]} = Exercises.check_answer(sw, "wrong")
    end

    test "returns error when no forms found" do
      word = noun_fixture(%{term: "pas"})
      sentence = sentence_with_words_fixture(%{word: word, form_tag: "nonexistent_tag"})

      sw = hd(sentence.sentence_words)
      assert {:error, :no_forms} = Exercises.check_answer(sw, "anything")
    end

    test "trims whitespace from input" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_with_words_fixture(%{word: word, form_tag: "acc_sg"})

      sw = hd(sentence.sentence_words)
      assert {:correct, "psa"} = Exercises.check_answer(sw, "  psa  ")
    end
  end

  describe "check_all_answers/2" do
    test "checks multiple answers at once" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_with_words_fixture(%{word: word, form_tag: "acc_sg"})

      sw = hd(sentence.sentence_words)
      results = Exercises.check_all_answers(sentence, %{sw.position => "psa"})

      assert {:correct, "psa"} = results[sw.position]
    end

    test "handles string position keys" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_with_words_fixture(%{word: word, form_tag: "acc_sg"})

      sw = hd(sentence.sentence_words)
      results = Exercises.check_all_answers(sentence, %{"#{sw.position}" => "psa"})

      assert {:correct, "psa"} = results[sw.position]
    end
  end

  describe "get_expected_forms/1" do
    test "returns display forms for matching form_tag" do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence = sentence_with_words_fixture(%{word: word, form_tag: "acc_sg"})

      sw = hd(sentence.sentence_words)
      assert ["psa"] = Exercises.get_expected_forms(sw)
    end

    test "returns empty list when no forms match" do
      word = noun_fixture(%{term: "pas"})
      sentence = sentence_with_words_fixture(%{word: word, form_tag: "nonexistent"})

      sw = hd(sentence.sentence_words)
      assert [] = Exercises.get_expected_forms(sw)
    end
  end

  describe "list_available_parts_of_speech/0" do
    test "returns empty list when no sentences exist" do
      assert Exercises.list_available_parts_of_speech() == []
    end

    test "returns distinct parts of speech sorted" do
      noun = noun_fixture()
      verb = verb_fixture()
      sentence_with_words_fixture(%{word: noun})
      sentence_with_words_fixture(%{word: verb})

      result = Exercises.list_available_parts_of_speech()
      assert result == [:noun, :verb]
    end
  end
end
