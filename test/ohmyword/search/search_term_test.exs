defmodule Ohmyword.Search.SearchTermTest do
  use Ohmyword.DataCase, async: true

  alias Ohmyword.Search.SearchTerm

  import Ohmyword.VocabularyFixtures

  describe "changeset/2" do
    test "valid changeset with required fields" do
      word = word_fixture()

      attrs = %{
        term: "psa",
        display_form: "psa",
        form_tag: "gen_sg",
        word_id: word.id
      }

      changeset = SearchTerm.changeset(%SearchTerm{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset without required fields" do
      changeset = SearchTerm.changeset(%SearchTerm{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).term
      assert "can't be blank" in errors_on(changeset).display_form
      assert "can't be blank" in errors_on(changeset).form_tag
      assert "can't be blank" in errors_on(changeset).word_id
    end

    test "term is lowercased on insert" do
      word = word_fixture()

      attrs = %{
        term: "PSA",
        display_form: "psa",
        form_tag: "gen_sg",
        word_id: word.id
      }

      changeset = SearchTerm.changeset(%SearchTerm{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :term) == "psa"
    end

    test "display_form is lowercased" do
      word = word_fixture()

      attrs = %{
        term: "psa",
        display_form: "PSA",
        form_tag: "gen_sg",
        word_id: word.id
      }

      changeset = SearchTerm.changeset(%SearchTerm{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :display_form) == "psa"
    end

    test "form_tag is lowercased" do
      word = word_fixture()

      attrs = %{
        term: "psa",
        display_form: "psa",
        form_tag: "GEN_SG",
        word_id: word.id
      }

      changeset = SearchTerm.changeset(%SearchTerm{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :form_tag) == "gen_sg"
    end

    test "source defaults to :seed" do
      word = word_fixture()

      {:ok, search_term} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "psa",
          display_form: "psa",
          form_tag: "gen_sg",
          word_id: word.id
        })
        |> Repo.insert()

      assert search_term.source == :seed
    end

    test "locked defaults to false" do
      word = word_fixture()

      {:ok, search_term} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "psa",
          display_form: "psa",
          form_tag: "gen_sg",
          word_id: word.id
        })
        |> Repo.insert()

      assert search_term.locked == false
    end

    test "duplicate (term, word_id, form_tag) is rejected by unique index" do
      word = word_fixture()

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "psa",
          display_form: "psa",
          form_tag: "gen_sg",
          word_id: word.id
        })
        |> Repo.insert()

      # Same combination should fail
      {:error, changeset} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "psa",
          display_form: "psa",
          form_tag: "gen_sg",
          word_id: word.id
        })
        |> Repo.insert()

      errors = errors_on(changeset)
      # The unique constraint error can be on any of the fields in the composite
      assert Map.has_key?(errors, :term) or
               Map.has_key?(errors, :word_id) or
               Map.has_key?(errors, :form_tag)
    end

    test "same term with different form_tag is allowed" do
      word = word_fixture()

      {:ok, _} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "psa",
          display_form: "psa",
          form_tag: "gen_sg",
          word_id: word.id
        })
        |> Repo.insert()

      {:ok, search_term} =
        %SearchTerm{}
        |> SearchTerm.changeset(%{
          term: "psa",
          display_form: "psa",
          form_tag: "acc_sg",
          word_id: word.id
        })
        |> Repo.insert()

      assert search_term.term == "psa"
      assert search_term.form_tag == "acc_sg"
    end
  end
end
