defmodule Ohmyword.Linguistics.Transliteration do
  @moduledoc """
  Handles transliteration and diacritics stripping for Serbian text.

  The seed data uses ASCII-only forms (e.g., "pises" not "piseš").
  This module strips diacritics from engine output to match.
  """

  @diacritics_map %{
    "š" => "s",
    "đ" => "dj",
    "č" => "c",
    "ć" => "c",
    "ž" => "z",
    "Š" => "S",
    "Đ" => "Dj",
    "Č" => "C",
    "Ć" => "C",
    "Ž" => "Z"
  }

  @doc """
  Strips Serbian diacritics from a string, replacing them with ASCII equivalents.

  ## Examples

      iex> Transliteration.strip_diacritics("pišeš")
      "pises"

      iex> Transliteration.strip_diacritics("junače")
      "junace"
  """
  def strip_diacritics(text) when is_binary(text) do
    text
    |> String.graphemes()
    |> Enum.map(fn char -> Map.get(@diacritics_map, char, char) end)
    |> Enum.join()
  end
end
