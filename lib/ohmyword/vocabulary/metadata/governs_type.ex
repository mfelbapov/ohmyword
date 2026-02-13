defmodule Ohmyword.Vocabulary.Metadata.GovernsType do
  @moduledoc """
  Custom Ecto type for the `governs` field used by numerals and prepositions.

  Accepts either a bare string or a list of strings. Stores as-is to preserve
  the existing seed data shape.
  """

  use Ecto.Type

  @impl true
  def type, do: :any

  @impl true
  def cast(value) when is_binary(value), do: {:ok, value}

  def cast(value) when is_list(value) do
    if Enum.all?(value, &is_binary/1) do
      {:ok, value}
    else
      :error
    end
  end

  def cast(nil), do: {:ok, nil}
  def cast(_), do: :error

  @impl true
  def load(value), do: {:ok, value}

  @impl true
  def dump(value) when is_binary(value), do: {:ok, value}
  def dump(value) when is_list(value), do: {:ok, value}
  def dump(nil), do: {:ok, nil}
  def dump(_), do: :error
end
