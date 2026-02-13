defmodule Ohmyword.Vocabulary.Metadata.PronounMetadataTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Vocabulary.Metadata.PronounMetadata

  describe "changeset/2" do
    test "valid with empty attrs" do
      changeset = PronounMetadata.changeset(%{})
      assert changeset.valid?
    end

    test "valid with all fields populated" do
      attrs = %{
        pronoun_type: "personal",
        clitic_forms: %{"acc_sg" => "me", "dat_sg" => "mi"}
      }

      changeset = PronounMetadata.changeset(attrs)
      assert changeset.valid?
    end

    test "validates pronoun_type inclusion" do
      for valid <-
            ~w(personal reflexive possessive demonstrative interrogative relative indefinite negative) do
        changeset = PronounMetadata.changeset(%{pronoun_type: valid})
        assert changeset.valid?, "expected #{valid} to be valid"
      end
    end

    test "rejects invalid pronoun_type" do
      changeset = PronounMetadata.changeset(%{pronoun_type: "unknown"})
      refute changeset.valid?
      assert errors_on(changeset).pronoun_type
    end

    test "clitic_forms must be string-to-string map" do
      changeset = PronounMetadata.changeset(%{clitic_forms: %{"acc_sg" => 42}})
      refute changeset.valid?
      assert errors_on(changeset).clitic_forms
    end

    test "unknown fields are silently dropped" do
      changeset = PronounMetadata.changeset(%{fake: true, pronoun_type: "personal"})
      assert changeset.valid?
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
