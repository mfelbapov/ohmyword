defmodule Ohmyword.Vocabulary.Metadata.NounMetadataTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Vocabulary.Metadata.NounMetadata

  describe "changeset/2" do
    test "valid with empty attrs" do
      changeset = NounMetadata.changeset(%{})
      assert changeset.valid?
    end

    test "valid with all fields populated" do
      attrs = %{
        fleeting_a: true,
        palatalization: true,
        ins_ju: true,
        extended_stem: "imen",
        drops_in_plural: false,
        singularia_tantum: false,
        pluralia_tantum: false,
        irregular_forms: %{"gen_pl" => "pasa"}
      }

      changeset = NounMetadata.changeset(attrs)
      assert changeset.valid?
    end

    test "rejects wrong type for boolean field" do
      changeset = NounMetadata.changeset(%{fleeting_a: "yes"})
      refute changeset.valid?
      assert errors_on(changeset).fleeting_a
    end

    test "rejects wrong type for string field" do
      changeset = NounMetadata.changeset(%{extended_stem: 42})
      refute changeset.valid?
      assert errors_on(changeset).extended_stem
    end

    test "irregular_forms must be string-to-string map" do
      changeset = NounMetadata.changeset(%{irregular_forms: %{"gen_pl" => 42}})
      refute changeset.valid?
      assert errors_on(changeset).irregular_forms
    end

    test "valid irregular_forms pass" do
      changeset =
        NounMetadata.changeset(%{irregular_forms: %{"nom_pl" => "ljudi", "gen_pl" => "ljudi"}})

      assert changeset.valid?
    end

    test "unknown fields are silently dropped" do
      changeset = NounMetadata.changeset(%{fake_field: true, fleeting_a: true})
      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :fleeting_a) == true
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
