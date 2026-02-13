defmodule Ohmyword.Vocabulary.Metadata.PrepositionMetadata do
  @moduledoc """
  Embedded schema for preposition grammar metadata validation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :governs, Ohmyword.Vocabulary.Metadata.GovernsType
    field :notes, :string
  end

  @fields ~w(governs notes)a

  def changeset(struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @fields)
  end
end
