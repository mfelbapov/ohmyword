defmodule Ohmyword.Exercises.Sentence do
  @moduledoc """
  Schema for exercise sentences.

  Each sentence is a full Serbian sentence with an English translation.
  Words in the sentence are annotated via `sentence_words` for use
  as fill-in-the-blank exercises at varying difficulty levels.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "sentences" do
    field :text_rs, :string
    field :text_en, :string

    has_many :sentence_words, Ohmyword.Exercises.SentenceWord
    has_many :words, through: [:sentence_words, :word]

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(text_rs text_en)a

  def changeset(sentence, attrs) do
    sentence
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
