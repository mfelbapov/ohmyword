defmodule Ohmyword.Vocabulary.Metadata.PronounMetadata do
  @moduledoc """
  Embedded schema for pronoun grammar metadata validation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Ohmyword.Vocabulary.Metadata

  @primary_key false
  embedded_schema do
    field :pronoun_type, :string
    field :clitic_forms, :map
  end

  @pronoun_types ~w(personal reflexive possessive demonstrative interrogative relative indefinite negative)
  @fields ~w(pronoun_type clitic_forms)a

  def changeset(struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @fields)
    |> validate_inclusion(:pronoun_type, @pronoun_types)
    |> Metadata.validate_string_map(:clitic_forms)
  end
end
