defmodule Ohmyword.Vocabulary.Metadata.AdjectiveMetadataTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Vocabulary.Metadata.AdjectiveMetadata

  describe "changeset/2" do
    test "valid with empty attrs" do
      changeset = AdjectiveMetadata.changeset(%{})
      assert changeset.valid?
    end

    test "valid with all fields populated" do
      attrs = %{
        fleeting_a: true,
        soft_stem: false,
        comparative_stem: "bolj",
        superlative_stem: "najbolj",
        no_short_form: false,
        indeclinable: false,
        irregular_forms: %{"nom_sg_m" => "dobar"}
      }

      changeset = AdjectiveMetadata.changeset(attrs)
      assert changeset.valid?
    end

    test "rejects wrong type for boolean field" do
      changeset = AdjectiveMetadata.changeset(%{soft_stem: "yes"})
      refute changeset.valid?
      assert errors_on(changeset).soft_stem
    end

    test "irregular_forms must be string-to-string map" do
      changeset = AdjectiveMetadata.changeset(%{irregular_forms: %{"nom" => 1}})
      refute changeset.valid?
      assert errors_on(changeset).irregular_forms
    end

    test "unknown fields are silently dropped" do
      changeset = AdjectiveMetadata.changeset(%{fake: true, fleeting_a: true})
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
