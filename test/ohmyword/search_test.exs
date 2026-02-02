defmodule Ohmyword.SearchTest do
  use Ohmyword.DataCase, async: true

  alias Ohmyword.Search
  alias Ohmyword.Search.SearchTerm
  alias Ohmyword.Repo

  import Ohmyword.VocabularyFixtures

  describe "lookup/1" do
    test "returns empty list when no match" do
      assert Search.lookup("nonexistent") == []
    end

    test "returns word with form info on exact match" do
      word = noun_fixture(%{term: "pas", translation: "dog"})

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{term: "psa", form_tag: "gen_sg", word_id: word.id})
        |> Repo.insert()

      results = Search.lookup("psa")

      assert length(results) == 1
      [result] = results
      assert result.word.id == word.id
      assert result.word.term == "pas"
      assert result.matched_form == "psa"
      assert result.form_tag == "gen_sg"
    end

    test "is case insensitive" do
      word = noun_fixture(%{term: "pas", translation: "dog"})

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{term: "psa", form_tag: "gen_sg", word_id: word.id})
        |> Repo.insert()

      # Uppercase input should find lowercase data
      results = Search.lookup("PSA")

      assert length(results) == 1
      assert hd(results).matched_form == "psa"
    end

    test "Cyrillic input is transliterated and matched" do
      word = noun_fixture(%{term: "pas", translation: "dog"})

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{term: "psa", form_tag: "gen_sg", word_id: word.id})
        |> Repo.insert()

      # Cyrillic "пса" should find Latin "psa"
      results = Search.lookup("пса")

      assert length(results) == 1
      assert hd(results).word.term == "pas"
    end

    test "returns multiple results for homographs" do
      # "kosa" can mean "hair" or "scythe"
      word1 = feminine_noun_fixture(%{term: "kosa", translation: "hair"})
      word2 = feminine_noun_fixture(%{term: "kosa", translation: "scythe"})

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{term: "kosa", form_tag: "nom_sg", word_id: word1.id})
        |> Repo.insert()

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{term: "kosa", form_tag: "nom_sg", word_id: word2.id})
        |> Repo.insert()

      results = Search.lookup("kosa")

      assert length(results) == 2

      translations = Enum.map(results, & &1.word.translation)
      assert "hair" in translations
      assert "scythe" in translations
    end

    test "inflected form links to root word" do
      word = noun_fixture(%{term: "pas", translation: "dog"})

      # Add various forms
      for {term, tag} <- [{"pas", "nom_sg"}, {"psa", "gen_sg"}, {"psu", "dat_sg"}] do
        {:ok, _} =
          %SearchTerm{}
          |> SearchTerm.changeset(%{term: term, form_tag: tag, word_id: word.id})
          |> Repo.insert()
      end

      # All forms should return the same root word
      for search_term <- ["pas", "psa", "psu"] do
        results = Search.lookup(search_term)
        assert length(results) == 1
        assert hd(results).word.term == "pas"
      end
    end

    test "multiple forms of same word return with different form_tags" do
      word = verb_fixture(%{term: "pisati", translation: "to write"})

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{term: "pisati", form_tag: "inf", word_id: word.id})
        |> Repo.insert()

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{term: "pisem", form_tag: "pres_1sg", word_id: word.id})
        |> Repo.insert()

      results_inf = Search.lookup("pisati")
      assert length(results_inf) == 1
      assert hd(results_inf).form_tag == "inf"

      results_pres = Search.lookup("pisem")
      assert length(results_pres) == 1
      assert hd(results_pres).form_tag == "pres_1sg"
    end

    test "handles Cyrillic with digraphs" do
      word = feminine_noun_fixture(%{term: "ljubav", translation: "love"})

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{term: "ljubav", form_tag: "nom_sg", word_id: word.id})
        |> Repo.insert()

      # Cyrillic "љубав" should find Latin "ljubav"
      results = Search.lookup("љубав")

      assert length(results) == 1
      assert hd(results).word.translation == "love"
    end

    test "handles uppercase Cyrillic input" do
      word = noun_fixture(%{term: "pas", translation: "dog"})

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{term: "psa", form_tag: "gen_sg", word_id: word.id})
        |> Repo.insert()

      # Uppercase Cyrillic "ПСА" should find lowercase "psa"
      results = Search.lookup("ПСА")

      assert length(results) == 1
      assert hd(results).word.term == "pas"
    end
  end
end
