defmodule Ohmyword.Vocabulary.Metadata.PrepositionMetadataTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Vocabulary.Metadata.PrepositionMetadata

  describe "changeset/2" do
    test "valid with empty attrs" do
      changeset = PrepositionMetadata.changeset(%{})
      assert changeset.valid?
    end

    test "valid with all fields populated" do
      attrs = %{
        governs: ["accusative", "locative"],
        notes: "used with motion verbs"
      }

      changeset = PrepositionMetadata.changeset(attrs)
      assert changeset.valid?
    end

    test "governs accepts a string" do
      changeset = PrepositionMetadata.changeset(%{governs: "genitive"})
      assert changeset.valid?
    end

    test "governs accepts a list of strings" do
      changeset = PrepositionMetadata.changeset(%{governs: ["genitive", "instrumental"]})
      assert changeset.valid?
    end

    test "rejects wrong type for string field" do
      changeset = PrepositionMetadata.changeset(%{notes: 42})
      refute changeset.valid?
      assert errors_on(changeset).notes
    end

    test "unknown fields are silently dropped" do
      changeset = PrepositionMetadata.changeset(%{fake: true, notes: "test"})
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
