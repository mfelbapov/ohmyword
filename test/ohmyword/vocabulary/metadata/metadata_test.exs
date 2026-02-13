defmodule Ohmyword.Vocabulary.MetadataTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Vocabulary.Metadata
  alias Ohmyword.Vocabulary.Word

  describe "validate_metadata/1" do
    test "routes noun metadata to NounMetadata" do
      changeset = build_changeset(:noun, %{"fleeting_a" => true})
      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :grammar_metadata) == %{"fleeting_a" => true}
    end

    test "routes verb metadata to VerbMetadata" do
      changeset = build_changeset(:verb, %{"present_stem" => "piš"})
      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :grammar_metadata) == %{"present_stem" => "piš"}
    end

    test "routes adjective metadata to AdjectiveMetadata" do
      changeset = build_changeset(:adjective, %{"soft_stem" => true})
      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :grammar_metadata) == %{"soft_stem" => true}
    end

    test "routes adverb metadata to AdverbMetadata" do
      changeset = build_changeset(:adverb, %{"comparative" => "brže"})
      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :grammar_metadata) == %{"comparative" => "brže"}
    end

    test "routes pronoun metadata to PronounMetadata" do
      changeset = build_changeset(:pronoun, %{"pronoun_type" => "personal"})
      assert changeset.valid?

      assert Ecto.Changeset.get_change(changeset, :grammar_metadata) == %{
               "pronoun_type" => "personal"
             }
    end

    test "routes numeral metadata to NumeralMetadata" do
      changeset = build_changeset(:numeral, %{"numeral_type" => "cardinal", "numeral_value" => 5})
      assert changeset.valid?

      assert Ecto.Changeset.get_change(changeset, :grammar_metadata) == %{
               "numeral_type" => "cardinal",
               "numeral_value" => 5
             }
    end

    test "routes preposition metadata to PrepositionMetadata" do
      changeset = build_changeset(:preposition, %{"governs" => ["accusative"]})
      assert changeset.valid?

      assert Ecto.Changeset.get_change(changeset, :grammar_metadata) == %{
               "governs" => ["accusative"]
             }
    end

    test "enforces empty metadata for conjunction" do
      changeset = build_changeset(:conjunction, %{})
      assert changeset.valid?

      changeset = build_changeset(:conjunction, %{"some_field" => true})
      refute changeset.valid?
      assert errors_on(changeset).grammar_metadata
    end

    test "enforces empty metadata for interjection" do
      changeset = build_changeset(:interjection, %{})
      assert changeset.valid?

      changeset = build_changeset(:interjection, %{"some_field" => true})
      refute changeset.valid?
    end

    test "enforces empty metadata for particle" do
      changeset = build_changeset(:particle, %{})
      assert changeset.valid?

      changeset = build_changeset(:particle, %{"some_field" => true})
      refute changeset.valid?
    end

    test "no-op when part_of_speech is nil" do
      changeset =
        %Word{}
        |> Ecto.Changeset.cast(%{term: "test", translation: "test"}, [:term, :translation])
        |> Metadata.validate_metadata()

      # Should not add metadata errors (POS is nil, changeset already invalid for other reasons)
      refute Map.has_key?(errors_on(changeset), :grammar_metadata)
    end

    test "strips nil values from validated output" do
      changeset = build_changeset(:noun, %{"fleeting_a" => true})
      metadata = Ecto.Changeset.get_change(changeset, :grammar_metadata)

      # Should only have the one field, not nil entries for other fields
      assert metadata == %{"fleeting_a" => true}
      refute Map.has_key?(metadata, "palatalization")
    end

    test "strips unknown fields from output" do
      changeset = build_changeset(:noun, %{"fleeting_a" => true, "unknown_field" => "ignored"})
      assert changeset.valid?
      metadata = Ecto.Changeset.get_change(changeset, :grammar_metadata)
      refute Map.has_key?(metadata, "unknown_field")
    end

    test "output is string-keyed map" do
      changeset = build_changeset(:noun, %{"fleeting_a" => true, "extended_stem" => "imen"})
      metadata = Ecto.Changeset.get_change(changeset, :grammar_metadata)

      assert is_map(metadata)
      assert Enum.all?(Map.keys(metadata), &is_binary/1)
    end
  end

  # Helper to build a Word changeset with the given POS and metadata
  defp build_changeset(pos, metadata) do
    attrs = base_attrs(pos) |> Map.put(:grammar_metadata, metadata)
    Word.changeset(%Word{}, attrs)
  end

  defp base_attrs(:noun),
    do: %{
      term: "test",
      translation: "test",
      part_of_speech: :noun,
      gender: :masculine,
      animate: true
    }

  defp base_attrs(:verb),
    do: %{term: "test", translation: "test", part_of_speech: :verb, verb_aspect: :imperfective}

  defp base_attrs(:adjective),
    do: %{term: "test", translation: "test", part_of_speech: :adjective, gender: :masculine}

  defp base_attrs(:adverb), do: %{term: "test", translation: "test", part_of_speech: :adverb}

  defp base_attrs(:pronoun),
    do: %{term: "test", translation: "test", part_of_speech: :pronoun, gender: :masculine}

  defp base_attrs(:numeral), do: %{term: "test", translation: "test", part_of_speech: :numeral}

  defp base_attrs(:preposition),
    do: %{term: "test", translation: "test", part_of_speech: :preposition}

  defp base_attrs(:conjunction),
    do: %{term: "test", translation: "test", part_of_speech: :conjunction}

  defp base_attrs(:interjection),
    do: %{term: "test", translation: "test", part_of_speech: :interjection}

  defp base_attrs(:particle), do: %{term: "test", translation: "test", part_of_speech: :particle}

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
