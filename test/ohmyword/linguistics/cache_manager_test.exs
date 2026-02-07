defmodule Ohmyword.Linguistics.CacheManagerTest do
  use Ohmyword.DataCase, async: true

  alias Ohmyword.Linguistics.CacheManager
  alias Ohmyword.Search.SearchTerm

  import Ohmyword.VocabularyFixtures

  describe "regenerate_word/1 with Word struct" do
    test "creates search_terms with source: :engine" do
      word = noun_fixture(%{term: "pas"})

      # Nouns module generates 14 forms
      assert {:ok, 14} = CacheManager.regenerate_word(word)

      search_terms = Repo.all(from st in SearchTerm, where: st.word_id == ^word.id)
      assert length(search_terms) == 14

      # Check nom_sg form
      nom_sg = Enum.find(search_terms, &(&1.form_tag == "nom_sg"))
      assert nom_sg.term == "pas"
      assert nom_sg.display_form == "pas"
      assert nom_sg.source == :engine
      assert nom_sg.locked == false
    end

    test "preserves locked entries during regeneration" do
      word = noun_fixture(%{term: "pas"})

      # Create a locked entry first
      {:ok, locked_term} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "psa",
          display_form: "psa",
          form_tag: "gen_sg",
          word_id: word.id,
          source: :manual,
          locked: true
        })
        |> Repo.insert()

      # Regenerate - generates 14 forms, conflict handling may vary
      {:ok, count} = CacheManager.regenerate_word(word)
      assert count >= 13 and count <= 14

      # Check that locked entry still exists
      search_terms = Repo.all(from st in SearchTerm, where: st.word_id == ^word.id)

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
          display_form: "oldform",
          form_tag: "old_tag",
          word_id: word.id,
          source: :engine,
          locked: false
        })
        |> Repo.insert()

      # Verify it exists
      assert Repo.get_by(SearchTerm, term: "oldform", word_id: word.id)

      # Regenerate - 14 forms for noun
      assert {:ok, 14} = CacheManager.regenerate_word(word)

      # Old entry should be gone
      assert Repo.get_by(SearchTerm, term: "oldform", word_id: word.id) == nil

      # New entry should exist
      assert Repo.get_by(SearchTerm, term: "pas", word_id: word.id)
    end

    test "stores ASCII term and diacritical display_form" do
      word = noun_fixture(%{term: "Kuća"})

      # 14 forms for noun
      assert {:ok, 14} = CacheManager.regenerate_word(word)

      # Check that term is ASCII-stripped and lowercase, display_form preserves diacritics
      term = Repo.get_by(SearchTerm, word_id: word.id, form_tag: "nom_sg")
      assert term.term == "kuca"
      assert term.display_form == "kuća"
    end
  end

  describe "regenerate_word/1 with word ID" do
    test "loads word by ID and regenerates" do
      word = noun_fixture(%{term: "pas"})

      # 14 forms for noun
      assert {:ok, 14} = CacheManager.regenerate_word(word.id)

      term = Repo.get_by(SearchTerm, word_id: word.id, form_tag: "nom_sg")
      assert term.term == "pas"
      assert term.display_form == "pas"
      assert term.source == :engine
    end

    test "returns error for non-existent word ID" do
      assert {:error, :not_found} = CacheManager.regenerate_word(999_999)
    end

    test "accepts binary ID" do
      word = noun_fixture(%{term: "pas"})

      # 14 forms for noun
      assert {:ok, 14} = CacheManager.regenerate_word(to_string(word.id))
    end
  end

  describe "regenerate_all/0" do
    test "processes multiple words" do
      word1 = noun_fixture(%{term: "pas"})
      word2 = verb_fixture(%{term: "pisati"})
      word3 = word_fixture(%{term: "i", part_of_speech: :conjunction})

      # noun: 14 forms, verb: 24 forms (16 + 6 passive + 2 adverbial), conjunction: 1 form (stub) = 39 total
      assert {:ok, %{words: 3, forms: 39}} = CacheManager.regenerate_all()

      # Verify each word has search terms
      for word <- [word1, word2, word3] do
        assert Repo.exists?(from st in SearchTerm, where: st.word_id == ^word.id)
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
          display_form: "pas",
          form_tag: "nom_sg",
          word_id: word1.id,
          source: :seed,
          locked: false
        })
        |> Repo.insert()

      # Should still report 2 words processed
      # noun: 14 forms, verb: 24 forms (16 + 6 passive + 2 adverbial) = 38 total
      assert {:ok, %{words: 2, forms: 38}} = CacheManager.regenerate_all()
    end
  end
end
