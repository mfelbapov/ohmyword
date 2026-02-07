defmodule Ohmyword.Exercises.Sentence do
  @moduledoc """
  Schema for fill-in-the-blank exercise sentences.

  Each sentence contains a blank (marked as {blank} in the text) that the user
  must fill with the correct inflected form of the associated word.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "sentences" do
    field :text, :string
    field :translation, :string
    field :blank_form_tag, :string
    field :hint, :string

    belongs_to :word, Ohmyword.Vocabulary.Word

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(text translation blank_form_tag word_id)a
  @optional_fields ~w(hint)a

  def changeset(sentence, attrs) do
    sentence
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_blank_marker()
    |> foreign_key_constraint(:word_id)
  end

  defp validate_blank_marker(changeset) do
    case get_field(changeset, :text) do
      nil ->
        changeset

      text ->
        if String.contains?(text, "{blank}") do
          changeset
        else
          add_error(changeset, :text, "must contain {blank} placeholder")
        end
    end
  end
end
