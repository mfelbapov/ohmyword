defmodule Ohmyword.Vocabulary.Metadata.VerbMetadataTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Vocabulary.Metadata.VerbMetadata

  describe "changeset/2" do
    test "valid with empty attrs" do
      changeset = VerbMetadata.changeset(%{})
      assert changeset.valid?
    end

    test "valid with all fields populated" do
      attrs = %{
        present_stem: "piš",
        past_stem: "pisa",
        present_conjugation_class: "e-verb",
        no_passive_participle: true,
        auxiliary: false,
        irregular_forms: %{"pres_1sg" => "jesam"}
      }

      changeset = VerbMetadata.changeset(attrs)
      assert changeset.valid?
    end

    test "validates present_conjugation_class inclusion" do
      for valid <- ~w(a-verb i-verb e-verb je-verb) do
        changeset = VerbMetadata.changeset(%{present_conjugation_class: valid})
        assert changeset.valid?, "expected #{valid} to be valid"
      end
    end

    test "rejects invalid present_conjugation_class" do
      changeset = VerbMetadata.changeset(%{present_conjugation_class: "x-verb"})
      refute changeset.valid?
      assert errors_on(changeset).present_conjugation_class
    end

    test "rejects wrong type for boolean field" do
      changeset = VerbMetadata.changeset(%{no_passive_participle: "yes"})
      refute changeset.valid?
      assert errors_on(changeset).no_passive_participle
    end

    test "irregular_forms must be string-to-string map" do
      changeset = VerbMetadata.changeset(%{irregular_forms: %{"pres_1sg" => 42}})
      refute changeset.valid?
      assert errors_on(changeset).irregular_forms
    end

    test "unknown fields are silently dropped" do
      changeset = VerbMetadata.changeset(%{fake_field: true, auxiliary: true})
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
