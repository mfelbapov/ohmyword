defmodule Ohmyword.Vocabulary.Metadata.AdjectiveMetadata do
  @moduledoc """
  Embedded schema for adjective grammar metadata validation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Ohmyword.Vocabulary.Metadata

  @primary_key false
  embedded_schema do
    field :fleeting_a, :boolean
    field :soft_stem, :boolean
    field :comparative_stem, :string
    field :superlative_stem, :string
    field :no_short_form, :boolean
    field :indeclinable, :boolean
    field :irregular_forms, :map
  end

  @fields ~w(fleeting_a soft_stem comparative_stem superlative_stem no_short_form indeclinable irregular_forms)a

  def changeset(struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @fields)
    |> Metadata.validate_string_map(:irregular_forms)
  end
end
