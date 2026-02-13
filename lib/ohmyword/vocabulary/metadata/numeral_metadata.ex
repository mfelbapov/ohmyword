defmodule Ohmyword.Vocabulary.Metadata.NumeralMetadata do
  @moduledoc """
  Embedded schema for numeral grammar metadata validation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Ohmyword.Vocabulary.Metadata

  @primary_key false
  embedded_schema do
    field :numeral_type, :string
    field :numeral_value, :integer
    field :soft_stem, :boolean
    field :gender_forms, :boolean
    field :governs, Ohmyword.Vocabulary.Metadata.GovernsType
    field :irregular_forms, :map
  end

  @numeral_types ~w(cardinal ordinal collective)
  @fields ~w(numeral_type numeral_value soft_stem gender_forms governs irregular_forms)a

  def changeset(struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @fields)
    |> validate_inclusion(:numeral_type, @numeral_types)
    |> Metadata.validate_string_map(:irregular_forms)
  end
end
