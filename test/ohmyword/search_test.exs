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
        |> SearchTerm.changeset(%{
          term: "psa",
          display_form: "psa",
          form_tag: "gen_sg",
          word_id: word.id
        })
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
        |> SearchTerm.changeset(%{
          term: "psa",
          display_form: "psa",
          form_tag: "gen_sg",
          word_id: word.id
        })
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
        |> SearchTerm.changeset(%{
          term: "psa",
          display_form: "psa",
          form_tag: "gen_sg",
          word_id: word.id
        })
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
        |> SearchTerm.changeset(%{
          term: "kosa",
          display_form: "kosa",
          form_tag: "nom_sg",
          word_id: word1.id
        })
        |> Repo.insert()

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "kosa",
          display_form: "kosa",
          form_tag: "nom_sg",
          word_id: word2.id
        })
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
          |> SearchTerm.changeset(%{
            term: term,
            display_form: term,
            form_tag: tag,
            word_id: word.id
          })
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
        |> SearchTerm.changeset(%{
          term: "pisati",
          display_form: "pisati",
          form_tag: "inf",
          word_id: word.id
        })
        |> Repo.insert()

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "pisem",
          display_form: "pisem",
          form_tag: "pres_1sg",
          word_id: word.id
        })
        |> Repo.insert()

      results_inf = Search.lookup("pisati")
      assert length(results_inf) == 1
      assert hd(results_inf).form_tag == "inf"

      results_pres = Search.lookup("pisem")
      assert length(results_pres) == 1
      assert hd(results_pres).form_tag == "pres_1sg"
    end

    test "deduplicates multiple forms of the same word with same surface text" do
      word = noun_fixture(%{term: "sam", translation: "alone"})

      # Three different form tags but same surface text "sam"
      for tag <- ["indef_nom_sg_m", "indef_voc_sg_m", "indef_acc_sg_m"] do
        {:ok, _} =
          %SearchTerm{}
          |> SearchTerm.changeset(%{
            term: "sam",
            display_form: "sam",
            form_tag: tag,
            word_id: word.id
          })
          |> Repo.insert()
      end

      results = Search.lookup("sam")

      # Should return only one result, not three
      assert length(results) == 1
      assert hd(results).word.id == word.id
      assert hd(results).matched_form == "sam"
    end

    test "deduplication preserves base form match" do
      word = noun_fixture(%{term: "pas", translation: "dog"})

      # "pas" matches as both nom_sg and some other tag
      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "pas",
          display_form: "pas",
          form_tag: "acc_sg",
          word_id: word.id
        })
        |> Repo.insert()

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "pas",
          display_form: "pas",
          form_tag: "nom_sg",
          word_id: word.id
        })
        |> Repo.insert()

      results = Search.lookup("pas")

      assert length(results) == 1
      # Should prefer the base form match (matched_form == word.term)
      assert hd(results).word.term == "pas"
      assert hd(results).matched_form == "pas"
    end

    test "deduplication still returns multiple results for different words" do
      word1 = noun_fixture(%{term: "sam", translation: "alone"})
      word2 = verb_fixture(%{term: "biti", translation: "to be"})

      # Same surface text "sam" for two different words
      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "sam",
          display_form: "sam",
          form_tag: "indef_nom_sg_m",
          word_id: word1.id
        })
        |> Repo.insert()

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "sam",
          display_form: "sam",
          form_tag: "indef_voc_sg_m",
          word_id: word1.id
        })
        |> Repo.insert()

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "sam",
          display_form: "sam",
          form_tag: "pres_1sg",
          word_id: word2.id
        })
        |> Repo.insert()

      results = Search.lookup("sam")

      # Two different words, not three rows
      assert length(results) == 2

      word_ids = Enum.map(results, & &1.word.id) |> Enum.sort()
      assert word_ids == Enum.sort([word1.id, word2.id])
    end

    test "handles Cyrillic with digraphs" do
      word = feminine_noun_fixture(%{term: "ljubav", translation: "love"})

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "ljubav",
          display_form: "ljubav",
          form_tag: "nom_sg",
          word_id: word.id
        })
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
        |> SearchTerm.changeset(%{
          term: "psa",
          display_form: "psa",
          form_tag: "gen_sg",
          word_id: word.id
        })
        |> Repo.insert()

      # Uppercase Cyrillic "ПСА" should find lowercase "psa"
      results = Search.lookup("ПСА")

      assert length(results) == 1
      assert hd(results).word.term == "pas"
    end

    test "finds word when searching with Latin diacritics" do
      word = noun_fixture(%{term: "čovek", translation: "man"})

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "covek",
          display_form: "čovek",
          form_tag: "nom_sg",
          word_id: word.id
        })
        |> Repo.insert()

      # Search with diacritic "č" should find via ASCII-stripped term
      results = Search.lookup("čovek")

      assert length(results) == 1
      assert hd(results).word.id == word.id
      assert hd(results).matched_form == "čovek"
    end

    test "English fallback finds word by primary translation" do
      word = word_fixture(%{term: "pas", translation: "dog", part_of_speech: :adverb})

      results = Search.lookup("dog")

      assert [result] = results
      assert result.word.id == word.id
      assert result.matched_form == "dog"
      assert result.form_tag == "translation"
    end

    test "English fallback finds word by alternative translation" do
      word =
        word_fixture(%{
          term: "kuca",
          translation: "house",
          translations: ["home", "dwelling"],
          part_of_speech: :adverb
        })

      results = Search.lookup("home")

      assert [result] = results
      assert result.word.id == word.id
      assert result.matched_form == "home"
      assert result.form_tag == "translation"
    end

    test "English search is case-insensitive" do
      word = word_fixture(%{term: "pas", translation: "dog", part_of_speech: :adverb})

      results = Search.lookup("Dog")

      assert [result] = results
      assert result.word.id == word.id
      assert result.form_tag == "translation"
    end

    test "English search matches individual words in multi-word translations" do
      word =
        word_fixture(%{term: "baciti", translation: "to throw", part_of_speech: :adverb})

      results = Search.lookup("throw")

      assert [result] = results
      assert result.word.id == word.id
      assert result.matched_form == "to throw"
    end

    test "English search does not match partial words" do
      _word =
        word_fixture(%{term: "baciti", translation: "to throw", part_of_speech: :adverb})

      assert Search.lookup("thro") == []
    end

    test "Serbian results take priority over English" do
      word = word_fixture(%{term: "put", translation: "road", part_of_speech: :adverb})

      search_term_fixture(%{word: word, term: "put", display_form: "put", form_tag: "nom_sg"})

      results = Search.lookup("put")

      assert [result] = results
      assert result.form_tag == "nom_sg"
    end

    test "English search does not duplicate words found in primary and alternative translations" do
      word =
        word_fixture(%{
          term: "kuca",
          translation: "home",
          translations: ["home sweet home"],
          part_of_speech: :adverb
        })

      results = Search.lookup("home")

      assert length(results) == 1
      assert hd(results).word.id == word.id
    end

    test "finds word with various Serbian diacritics" do
      word1 = feminine_noun_fixture(%{term: "šuma", translation: "forest"})
      word2 = feminine_noun_fixture(%{term: "žena", translation: "woman"})

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "suma",
          display_form: "šuma",
          form_tag: "nom_sg",
          word_id: word1.id
        })
        |> Repo.insert()

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "zena",
          display_form: "žena",
          form_tag: "nom_sg",
          word_id: word2.id
        })
        |> Repo.insert()

      # Search with diacritics should find via ASCII-stripped term
      assert length(Search.lookup("šuma")) == 1
      assert length(Search.lookup("žena")) == 1
    end
  end
end
