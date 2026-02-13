defmodule Ohmyword.Vocabulary.Metadata.AdverbMetadataTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Vocabulary.Metadata.AdverbMetadata

  describe "changeset/2" do
    test "valid with empty attrs" do
      changeset = AdverbMetadata.changeset(%{})
      assert changeset.valid?
    end

    test "valid with all fields populated" do
      attrs = %{
        comparative: "brže",
        superlative: "najbrže",
        derived_from: "brz"
      }

      changeset = AdverbMetadata.changeset(attrs)
      assert changeset.valid?
    end

    test "rejects wrong type for string field" do
      changeset = AdverbMetadata.changeset(%{comparative: 42})
      refute changeset.valid?
      assert errors_on(changeset).comparative
    end

    test "unknown fields are silently dropped" do
      changeset = AdverbMetadata.changeset(%{fake: true, comparative: "brže"})
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
