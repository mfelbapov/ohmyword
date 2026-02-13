defmodule Ohmyword.VocabularyTest do
  use Ohmyword.DataCase, async: true

  alias Ohmyword.Vocabulary
  alias Ohmyword.Vocabulary.Word

  import Ohmyword.VocabularyFixtures

  describe "list_words/1" do
    test "returns all words when no filters" do
      word1 = word_fixture()
      word2 = noun_fixture()
      word3 = verb_fixture()

      words = Vocabulary.list_words()

      assert length(words) == 3
      assert Enum.any?(words, &(&1.id == word1.id))
      assert Enum.any?(words, &(&1.id == word2.id))
      assert Enum.any?(words, &(&1.id == word3.id))
    end

    test "filters by part_of_speech" do
      _adverb = word_fixture(%{part_of_speech: :adverb})
      noun = noun_fixture()
      _verb = verb_fixture()

      words = Vocabulary.list_words(part_of_speech: :noun)

      assert length(words) == 1
      assert hd(words).id == noun.id
    end

    test "filters by proficiency_level" do
      word1 = word_fixture(%{proficiency_level: 1})
      _word2 = word_fixture(%{proficiency_level: 2})
      word3 = word_fixture(%{proficiency_level: 1})

      words = Vocabulary.list_words(proficiency_level: 1)

      assert length(words) == 2
      ids = Enum.map(words, & &1.id)
      assert word1.id in ids
      assert word3.id in ids
    end

    test "combines multiple filters" do
      _noun_level1 = noun_fixture(%{proficiency_level: 1})
      noun_level2 = noun_fixture(%{proficiency_level: 2})
      _verb_level2 = verb_fixture(%{proficiency_level: 2})

      words = Vocabulary.list_words(part_of_speech: :noun, proficiency_level: 2)

      assert length(words) == 1
      assert hd(words).id == noun_level2.id
    end
  end

  describe "get_word!/1" do
    test "returns the word with given id" do
      word = word_fixture()
      fetched = Vocabulary.get_word!(word.id)
      assert fetched.id == word.id
      assert fetched.term == word.term
    end

    test "raises Ecto.NoResultsError for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Vocabulary.get_word!(0)
      end
    end
  end

  describe "get_random_word/1" do
    test "returns a word when words exist" do
      word_fixture()
      assert %Word{} = Vocabulary.get_random_word()
    end

    test "returns nil when no words exist" do
      assert Vocabulary.get_random_word() == nil
    end

    test "respects proficiency_level filter" do
      word1 = word_fixture(%{proficiency_level: 1})
      _word2 = word_fixture(%{proficiency_level: 3})

      # Run multiple times to increase confidence
      for _ <- 1..10 do
        result = Vocabulary.get_random_word(proficiency_level: 1)
        assert result.id == word1.id
      end
    end
  end

  describe "list_available_parts_of_speech/0" do
    test "returns empty list when no words exist" do
      assert Vocabulary.list_available_parts_of_speech() == []
    end

    test "returns distinct parts of speech sorted" do
      noun_fixture()
      verb_fixture()
      word_fixture(%{part_of_speech: :adverb})

      result = Vocabulary.list_available_parts_of_speech()

      assert result == [:adverb, :noun, :verb]
    end

    test "does not include duplicates" do
      noun_fixture()
      noun_fixture(%{term: "kuća", translation: "house"})

      result = Vocabulary.list_available_parts_of_speech()

      assert result == [:noun]
    end
  end

  describe "create_word/1" do
    test "creates a word with valid attrs" do
      attrs = %{
        term: "brzo",
        translation: "quickly",
        part_of_speech: :adverb
      }

      assert {:ok, %Word{} = word} = Vocabulary.create_word(attrs)
      assert word.term == "brzo"
      assert word.translation == "quickly"
      assert word.part_of_speech == :adverb
    end

    test "returns error changeset for invalid attrs" do
      assert {:error, %Ecto.Changeset{}} = Vocabulary.create_word(%{})
    end

    test "creates word with all optional fields" do
      attrs = %{
        term: "pas",
        translation: "dog",
        translations: ["hound", "canine"],
        part_of_speech: :noun,
        proficiency_level: 1,
        gender: :masculine,
        animate: true,
        declension_class: "consonant",
        grammar_metadata: %{"fleeting_a" => true},
        categories: ["animals", "pets"],
        example_sentence_rs: "Pas laje.",
        example_sentence_en: "The dog barks."
      }

      assert {:ok, %Word{} = word} = Vocabulary.create_word(attrs)
      assert word.translations == ["hound", "canine"]
      assert word.gender == :masculine
      assert word.animate == true
      assert word.grammar_metadata == %{"fleeting_a" => true}
    end
  end

  describe "update_word/2" do
    test "updates the word with valid attrs" do
      word = word_fixture()

      assert {:ok, updated} = Vocabulary.update_word(word, %{translation: "updated"})
      assert updated.translation == "updated"
    end

    test "returns error changeset for invalid attrs" do
      word = word_fixture()
      assert {:error, %Ecto.Changeset{}} = Vocabulary.update_word(word, %{term: nil})
    end
  end

  describe "delete_word/1" do
    test "deletes the word" do
      word = word_fixture()
      assert {:ok, %Word{}} = Vocabulary.delete_word(word)

      assert_raise Ecto.NoResultsError, fn ->
        Vocabulary.get_word!(word.id)
      end
    end

    test "cascades delete to search_terms" do
      word = word_fixture()
      search_term = search_term_fixture(%{word: word, term: "form1", form_tag: "nom_sg"})

      {:ok, _} = Vocabulary.delete_word(word)

      # Search term should be deleted
      assert Ohmyword.Repo.get(Ohmyword.Search.SearchTerm, search_term.id) == nil
    end
  end

  describe "list_available_categories/1" do
    test "returns empty list when no words exist" do
      assert Vocabulary.list_available_categories() == []
    end

    test "returns distinct sorted categories" do
      word_fixture(%{categories: ["Food & Drink", "Nature & Environment"]})
      word_fixture(%{categories: ["Food & Drink", "People & Relationships"]})

      categories = Vocabulary.list_available_categories()

      assert categories == ["Food & Drink", "Nature & Environment", "People & Relationships"]
    end

    test "excludes words with empty categories" do
      word_fixture(%{categories: []})
      word_fixture(%{categories: ["Actions & Processes"]})

      assert Vocabulary.list_available_categories() == ["Actions & Processes"]
    end

    test "filters categories by part_of_speech" do
      noun_fixture(%{categories: ["Food & Drink"]})
      verb_fixture(%{categories: ["Actions & Activities"]})

      assert Vocabulary.list_available_categories(part_of_speech: :noun) == ["Food & Drink"]

      assert Vocabulary.list_available_categories(part_of_speech: :verb) == [
               "Actions & Activities"
             ]
    end

    test "returns empty list for POS with no categories" do
      word_fixture(%{part_of_speech: :conjunction, categories: []})

      assert Vocabulary.list_available_categories(part_of_speech: :conjunction) == []
    end
  end

  describe "list_available_parts_of_speech/1 with category filter" do
    test "filters POS by category" do
      noun_fixture(%{categories: ["Food & Drink"]})
      verb_fixture(%{categories: ["Actions & Activities"]})

      assert Vocabulary.list_available_parts_of_speech(category: "Food & Drink") == [:noun]
    end

    test "returns all POS when no category filter" do
      noun_fixture()
      verb_fixture()

      assert Vocabulary.list_available_parts_of_speech() == [:noun, :verb]
    end
  end

  describe "get_random_word/1 with category filter" do
    test "filters by category" do
      word_fixture(%{term: "hleb", categories: ["Food & Drink"]})
      word_fixture(%{term: "pas", categories: ["Nature & Environment"]})

      word = Vocabulary.get_random_word(category: "Food & Drink")

      assert word.term == "hleb"
    end

    test "returns nil when no words match category" do
      word_fixture(%{categories: ["Food & Drink"]})

      assert Vocabulary.get_random_word(category: "Abstract & Academic") == nil
    end

    test "combined part_of_speech and category filter" do
      noun_fixture(%{term: "hleb", categories: ["Food & Drink"]})
      verb_fixture(%{term: "jesti", categories: ["Food & Drink"]})
      noun_fixture(%{term: "kuca", categories: ["Nature & Environment"]})

      word = Vocabulary.get_random_word(part_of_speech: :noun, category: "Food & Drink")

      assert word.term == "hleb"
    end
  end
end
