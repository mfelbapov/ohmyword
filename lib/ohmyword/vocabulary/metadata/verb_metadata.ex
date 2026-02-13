defmodule Ohmyword.Vocabulary.Metadata.VerbMetadata do
  @moduledoc """
  Embedded schema for verb grammar metadata validation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Ohmyword.Vocabulary.Metadata

  @primary_key false
  embedded_schema do
    field :present_stem, :string
    field :past_stem, :string
    field :present_conjugation_class, :string
    field :no_passive_participle, :boolean
    field :auxiliary, :boolean
    field :irregular_forms, :map
  end

  @conjugation_classes ~w(a-verb i-verb e-verb je-verb)
  @fields ~w(present_stem past_stem present_conjugation_class no_passive_participle auxiliary irregular_forms)a

  def changeset(struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @fields)
    |> validate_inclusion(:present_conjugation_class, @conjugation_classes)
    |> Metadata.validate_string_map(:irregular_forms)
  end
end
