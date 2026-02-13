defmodule Ohmyword.Vocabulary.Metadata.NounMetadata do
  @moduledoc """
  Embedded schema for noun grammar metadata validation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Ohmyword.Vocabulary.Metadata

  @primary_key false
  embedded_schema do
    field :fleeting_a, :boolean
    field :palatalization, :boolean
    field :ins_ju, :boolean
    field :extended_stem, :string
    field :drops_in_plural, :boolean
    field :singularia_tantum, :boolean
    field :pluralia_tantum, :boolean
    field :irregular_forms, :map
  end

  @fields ~w(fleeting_a palatalization ins_ju extended_stem drops_in_plural singularia_tantum pluralia_tantum irregular_forms)a

  def changeset(struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @fields)
    |> Metadata.validate_string_map(:irregular_forms)
  end
end
