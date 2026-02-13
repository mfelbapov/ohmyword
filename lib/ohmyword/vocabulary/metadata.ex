defmodule Ohmyword.Vocabulary.Metadata do
  @moduledoc """
  Validates `grammar_metadata` for vocabulary words based on their part of speech.

  Routes to the correct embedded schema for validation, then converts the validated
  struct back to a clean string-keyed map for storage. This preserves compatibility
  with all inflectors that read metadata with string keys.
  """

  import Ecto.Changeset

  alias Ohmyword.Vocabulary.Metadata.{
    NounMetadata,
    VerbMetadata,
    AdjectiveMetadata,
    AdverbMetadata,
    PronounMetadata,
    NumeralMetadata,
    PrepositionMetadata
  }

  @no_metadata_pos ~w(conjunction interjection particle)a

  @pos_to_module %{
    noun: NounMetadata,
    verb: VerbMetadata,
    adjective: AdjectiveMetadata,
    adverb: AdverbMetadata,
    pronoun: PronounMetadata,
    numeral: NumeralMetadata,
    preposition: PrepositionMetadata
  }

  @doc """
  Validates `grammar_metadata` on a Word changeset based on `part_of_speech`.

  - POS with schemas: validates through the embedded schema, then stores as clean string-keyed map
  - conjunction/interjection/particle: rejects non-empty metadata
  - nil POS: no-op (changeset is already invalid)
  """
  def validate_metadata(changeset) do
    pos = get_field(changeset, :part_of_speech)
    metadata = get_field(changeset, :grammar_metadata) || %{}

    cond do
      is_nil(pos) ->
        changeset

      pos in @no_metadata_pos ->
        validate_empty_metadata(changeset, metadata)

      true ->
        validate_pos_metadata(changeset, pos, metadata)
    end
  end

  @doc """
  Validates that a map field contains only string keys and string values.
  Adds an error to the changeset if validation fails.
  """
  def validate_string_map(changeset, field) do
    case get_field(changeset, field) do
      nil ->
        changeset

      map when is_map(map) ->
        valid? =
          Enum.all?(map, fn {k, v} ->
            is_binary(k) and is_binary(v)
          end)

        if valid? do
          changeset
        else
          add_error(changeset, field, "must be a map with string keys and string values")
        end

      _ ->
        changeset
    end
  end

  defp validate_empty_metadata(changeset, metadata) when map_size(metadata) == 0 do
    changeset
  end

  defp validate_empty_metadata(changeset, _metadata) do
    add_error(changeset, :grammar_metadata, "must be empty for this part of speech")
  end

  defp validate_pos_metadata(changeset, pos, metadata) do
    module = Map.fetch!(@pos_to_module, pos)
    meta_changeset = module.changeset(atomize_keys(metadata))

    if meta_changeset.valid? do
      clean_map =
        meta_changeset
        |> apply_changes()
        |> to_string_map()

      put_change(changeset, :grammar_metadata, clean_map)
    else
      Enum.reduce(meta_changeset.errors, changeset, fn {field, {msg, opts}}, cs ->
        full_msg = "#{field} #{render_error(msg, opts)}"
        add_error(cs, :grammar_metadata, full_msg)
      end)
    end
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) ->
        {String.to_existing_atom(k), v}

      {k, v} when is_atom(k) ->
        {k, v}
    end)
  rescue
    ArgumentError -> map
  end

  defp to_string_map(struct) do
    struct
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)
  end

  defp render_error(msg, opts) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
