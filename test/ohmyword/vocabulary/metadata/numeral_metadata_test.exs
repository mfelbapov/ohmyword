defmodule Ohmyword.Vocabulary.Metadata.NumeralMetadataTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Vocabulary.Metadata.NumeralMetadata

  describe "changeset/2" do
    test "valid with empty attrs" do
      changeset = NumeralMetadata.changeset(%{})
      assert changeset.valid?
    end

    test "valid with all fields populated" do
      attrs = %{
        numeral_type: "ordinal",
        numeral_value: 3,
        soft_stem: true,
        gender_forms: false,
        governs: "gen_sg",
        irregular_forms: %{"nom_sg_m" => "treći"}
      }

      changeset = NumeralMetadata.changeset(attrs)
      assert changeset.valid?
    end

    test "validates numeral_type inclusion" do
      for valid <- ~w(cardinal ordinal collective) do
        changeset = NumeralMetadata.changeset(%{numeral_type: valid})
        assert changeset.valid?, "expected #{valid} to be valid"
      end
    end

    test "rejects invalid numeral_type" do
      changeset = NumeralMetadata.changeset(%{numeral_type: "fractional"})
      refute changeset.valid?
      assert errors_on(changeset).numeral_type
    end

    test "governs accepts a string" do
      changeset = NumeralMetadata.changeset(%{governs: "gen_sg"})
      assert changeset.valid?
    end

    test "governs accepts a list of strings" do
      changeset = NumeralMetadata.changeset(%{governs: ["genitive", "accusative"]})
      assert changeset.valid?
    end

    test "governs rejects non-string list items" do
      changeset = NumeralMetadata.changeset(%{governs: [1, 2]})
      refute changeset.valid?
      assert errors_on(changeset).governs
    end

    test "irregular_forms must be string-to-string map" do
      changeset = NumeralMetadata.changeset(%{irregular_forms: %{"nom" => 1}})
      refute changeset.valid?
      assert errors_on(changeset).irregular_forms
    end

    test "unknown fields are silently dropped" do
      changeset = NumeralMetadata.changeset(%{fake: true, numeral_type: "cardinal"})
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
