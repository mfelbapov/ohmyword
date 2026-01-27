defmodule Ohmyword.Linguistics.CacheManagerTest do
  use Ohmyword.DataCase, async: true

  alias Ohmyword.Linguistics.CacheManager
  alias Ohmyword.Search.SearchTerm

  import Ohmyword.VocabularyFixtures

  describe "regenerate_word/1 with Word struct" do
    test "creates search_terms with source: :engine" do
      word = noun_fixture(%{term: "pas"})

      assert {:ok, 1} = CacheManager.regenerate_word(word)

      search_terms = Repo.all(from st in SearchTerm, where: st.word_id == ^word.id)
      assert length(search_terms) == 1

      [term] = search_terms
      assert term.term == "pas"
      assert term.form_tag == "base"
      assert term.source == :engine
      assert term.locked == false
    end

    test "preserves locked entries during regeneration" do
      word = noun_fixture(%{term: "pas"})

      # Create a locked entry first
      {:ok, locked_term} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "psa",
          form_tag: "gen_sg",
          word_id: word.id,
          source: :manual,
          locked: true
        })
        |> Repo.insert()

      # Regenerate
      assert {:ok, 1} = CacheManager.regenerate_word(word)

      # Check that locked entry still exists
      search_terms = Repo.all(from st in SearchTerm, where: st.word_id == ^word.id)
      assert length(search_terms) == 2

      locked_entries = Enum.filter(search_terms, & &1.locked)
      assert length(locked_entries) == 1
      assert hd(locked_entries).id == locked_term.id
      assert hd(locked_entries).term == "psa"
    end

    test "deletes old unlocked entries before inserting new ones" do
      word = noun_fixture(%{term: "pas"})

      # Create an unlocked engine entry
      {:ok, _old_term} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "oldform",
          form_tag: "old_tag",
          word_id: word.id,
          source: :engine,
          locked: false
        })
        |> Repo.insert()

      # Verify it exists
      assert Repo.get_by(SearchTerm, term: "oldform", word_id: word.id)

      # Regenerate
      assert {:ok, 1} = CacheManager.regenerate_word(word)

      # Old entry should be gone
      assert Repo.get_by(SearchTerm, term: "oldform", word_id: word.id) == nil

      # New entry should exist
      assert Repo.get_by(SearchTerm, term: "pas", word_id: word.id)
    end

    test "handles word with uppercase term" do
      word = noun_fixture(%{term: "Kuća"})

      assert {:ok, 1} = CacheManager.regenerate_word(word)

      term = Repo.get_by(SearchTerm, word_id: word.id)
      assert term.term == "kuća"
    end
  end

  describe "regenerate_word/1 with word ID" do
    test "loads word by ID and regenerates" do
      word = noun_fixture(%{term: "pas"})

      assert {:ok, 1} = CacheManager.regenerate_word(word.id)

      term = Repo.get_by(SearchTerm, word_id: word.id)
      assert term.term == "pas"
      assert term.source == :engine
    end

    test "returns error for non-existent word ID" do
      assert {:error, :not_found} = CacheManager.regenerate_word(999_999)
    end

    test "accepts binary ID" do
      word = noun_fixture(%{term: "pas"})

      assert {:ok, 1} = CacheManager.regenerate_word(to_string(word.id))
    end
  end

  describe "regenerate_all/0" do
    test "processes multiple words" do
      word1 = noun_fixture(%{term: "pas"})
      word2 = verb_fixture(%{term: "pisati"})
      word3 = word_fixture(%{term: "i", part_of_speech: :conjunction})

      assert {:ok, %{words: 3, forms: 3}} = CacheManager.regenerate_all()

      # Verify each word has a search term
      for word <- [word1, word2, word3] do
        assert Repo.get_by(SearchTerm, word_id: word.id)
      end
    end

    test "returns correct count even with some words already having terms" do
      word1 = noun_fixture(%{term: "pas"})
      _word2 = verb_fixture(%{term: "pisati"})

      # Pre-create a term for word1
      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "pas",
          form_tag: "nom_sg",
          word_id: word1.id,
          source: :seed,
          locked: false
        })
        |> Repo.insert()

      # Should still report 2 words processed
      assert {:ok, %{words: 2, forms: 2}} = CacheManager.regenerate_all()
    end
  end
end
