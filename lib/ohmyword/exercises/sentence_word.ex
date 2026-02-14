defmodule Ohmyword.Exercises.SentenceWord do
  @moduledoc """
  Schema for annotated words within a sentence.

  Links a position in a tokenized sentence to a vocabulary word and
  the specific inflected form_tag used at that position.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "sentence_words" do
    field :position, :integer
    field :form_tag, :string

    belongs_to :sentence, Ohmyword.Exercises.Sentence
    belongs_to :word, Ohmyword.Vocabulary.Word

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(position form_tag sentence_id word_id)a

  def changeset(sentence_word, attrs) do
    sentence_word
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:sentence_id)
    |> foreign_key_constraint(:word_id)
    |> unique_constraint([:sentence_id, :position])
  end
end
