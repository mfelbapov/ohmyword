defmodule Ohmyword.Search.SearchTerm do
  @moduledoc """
  Schema for search terms - the read cache for fast lookups.

  A flat denormalized table containing every searchable surface form
  (conjugations, declensions) mapped back to the root word.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @sources ~w(seed manual engine)a

  schema "search_terms" do
    field :term, :string
    field :display_form, :string
    field :form_tag, :string
    field :source, Ecto.Enum, values: @sources, default: :seed
    field :locked, :boolean, default: false

    belongs_to :word, Ohmyword.Vocabulary.Word

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(term display_form form_tag word_id)a
  @optional_fields ~w(source locked)a

  def changeset(search_term, attrs) do
    search_term
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> lowercase_term()
    |> lowercase_display_form()
    |> lowercase_form_tag()
    |> foreign_key_constraint(:word_id)
    |> unique_constraint([:term, :word_id, :form_tag])
  end

  defp lowercase_term(changeset) do
    case get_change(changeset, :term) do
      nil -> changeset
      term -> put_change(changeset, :term, String.downcase(term))
    end
  end

  defp lowercase_display_form(changeset) do
    case get_change(changeset, :display_form) do
      nil -> changeset
      display_form -> put_change(changeset, :display_form, String.downcase(display_form))
    end
  end

  defp lowercase_form_tag(changeset) do
    case get_change(changeset, :form_tag) do
      nil -> changeset
      form_tag -> put_change(changeset, :form_tag, String.downcase(form_tag))
    end
  end
end
