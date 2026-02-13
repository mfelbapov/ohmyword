defmodule Ohmyword.Vocabulary.Metadata.AdverbMetadata do
  @moduledoc """
  Embedded schema for adverb grammar metadata validation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :comparative, :string
    field :superlative, :string
    field :derived_from, :string
  end

  @fields ~w(comparative superlative derived_from)a

  def changeset(struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @fields)
  end
end
