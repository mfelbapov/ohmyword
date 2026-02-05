defmodule Ohmyword.Utils.Transliteration do
  @moduledoc """
  Serbian Latin ↔ Cyrillic transliteration utility.

  All data is stored in Latin script. This module provides conversion
  to Cyrillic for display and from Cyrillic for search input normalization.

  Key implementation detail: Digraphs (Lj, Nj, Dž) must be processed
  BEFORE single characters to avoid incorrect splitting.
  """

  # Latin to Cyrillic mappings
  # Digraphs MUST come first in processing order
  @latin_digraphs_lower %{
    "lj" => "љ",
    "nj" => "њ",
    "dž" => "џ"
  }

  @latin_digraphs_title %{
    "Lj" => "Љ",
    "Nj" => "Њ",
    "Dž" => "Џ"
  }

  @latin_digraphs_upper %{
    "LJ" => "Љ",
    "NJ" => "Њ",
    "DŽ" => "Џ"
  }

  @latin_to_cyrillic_lower %{
    "a" => "а",
    "b" => "б",
    "c" => "ц",
    "č" => "ч",
    "ć" => "ћ",
    "d" => "д",
    "đ" => "ђ",
    "e" => "е",
    "f" => "ф",
    "g" => "г",
    "h" => "х",
    "i" => "и",
    "j" => "ј",
    "k" => "к",
    "l" => "л",
    "m" => "м",
    "n" => "н",
    "o" => "о",
    "p" => "п",
    "r" => "р",
    "s" => "с",
    "š" => "ш",
    "t" => "т",
    "u" => "у",
    "v" => "в",
    "z" => "з",
    "ž" => "ж"
  }

  @latin_to_cyrillic_upper %{
    "A" => "А",
    "B" => "Б",
    "C" => "Ц",
    "Č" => "Ч",
    "Ć" => "Ћ",
    "D" => "Д",
    "Đ" => "Ђ",
    "E" => "Е",
    "F" => "Ф",
    "G" => "Г",
    "H" => "Х",
    "I" => "И",
    "J" => "Ј",
    "K" => "К",
    "L" => "Л",
    "M" => "М",
    "N" => "Н",
    "O" => "О",
    "P" => "П",
    "R" => "Р",
    "S" => "С",
    "Š" => "Ш",
    "T" => "Т",
    "U" => "У",
    "V" => "В",
    "Z" => "З",
    "Ž" => "Ж"
  }

  # Cyrillic to Latin mappings
  @cyrillic_to_latin_lower %{
    "а" => "a",
    "б" => "b",
    "ц" => "c",
    "ч" => "č",
    "ћ" => "ć",
    "д" => "d",
    "ђ" => "đ",
    "е" => "e",
    "ф" => "f",
    "г" => "g",
    "х" => "h",
    "и" => "i",
    "ј" => "j",
    "к" => "k",
    "л" => "l",
    "љ" => "lj",
    "м" => "m",
    "н" => "n",
    "њ" => "nj",
    "о" => "o",
    "п" => "p",
    "р" => "r",
    "с" => "s",
    "ш" => "š",
    "т" => "t",
    "у" => "u",
    "в" => "v",
    "з" => "z",
    "ж" => "ž",
    "џ" => "dž"
  }

  @cyrillic_to_latin_upper %{
    "А" => "A",
    "Б" => "B",
    "Ц" => "C",
    "Ч" => "Č",
    "Ћ" => "Ć",
    "Д" => "D",
    "Ђ" => "Đ",
    "Е" => "E",
    "Ф" => "F",
    "Г" => "G",
    "Х" => "H",
    "И" => "I",
    "Ј" => "J",
    "К" => "K",
    "Л" => "L",
    "Љ" => "Lj",
    "М" => "M",
    "Н" => "N",
    "Њ" => "Nj",
    "О" => "O",
    "П" => "P",
    "Р" => "R",
    "С" => "S",
    "Ш" => "Š",
    "Т" => "T",
    "У" => "U",
    "В" => "V",
    "З" => "Z",
    "Ж" => "Ž",
    "Џ" => "Dž"
  }

  @doc """
  Converts Latin script text to Serbian Cyrillic.

  ## Examples

      iex> Ohmyword.Utils.Transliteration.to_cyrillic("Dobro jutro")
      "Добро јутро"

      iex> Ohmyword.Utils.Transliteration.to_cyrillic("ljubav")
      "љубав"
  """
  @spec to_cyrillic(String.t()) :: String.t()
  def to_cyrillic(text) when is_binary(text) do
    convert_latin_to_cyrillic(text, "")
  end

  @doc """
  Converts Serbian Cyrillic text to Latin script.

  ## Examples

      iex> Ohmyword.Utils.Transliteration.to_latin("Добро јутро")
      "Dobro jutro"

      iex> Ohmyword.Utils.Transliteration.to_latin("љубав")
      "ljubav"
  """
  @spec to_latin(String.t()) :: String.t()
  def to_latin(text) when is_binary(text) do
    text
    |> String.graphemes()
    |> Enum.map(&convert_cyrillic_char/1)
    |> Enum.join()
  end

  @doc """
  Strips Serbian Latin diacritics to plain ASCII equivalents.
  Useful for normalizing search queries.

  ## Examples

      iex> Ohmyword.Utils.Transliteration.strip_diacritics("čovek")
      "covek"

      iex> Ohmyword.Utils.Transliteration.strip_diacritics("ćevapi")
      "cevapi"
  """
  @spec strip_diacritics(String.t()) :: String.t()
  def strip_diacritics(text) when is_binary(text) do
    text
    |> String.replace(~r/[čć]/u, "c")
    |> String.replace(~r/[ČĆ]/u, "C")
    |> String.replace("š", "s")
    |> String.replace("Š", "S")
    |> String.replace("ž", "z")
    |> String.replace("Ž", "Z")
    |> String.replace("đ", "dj")
    |> String.replace("Đ", "Dj")
  end

  # Latin to Cyrillic conversion - must check digraphs first
  defp convert_latin_to_cyrillic("", acc), do: acc

  defp convert_latin_to_cyrillic(text, acc) do
    cond do
      # Check for uppercase digraphs first (LJ, NJ, DŽ)
      match = match_digraph(text, @latin_digraphs_upper) ->
        {cyrillic, rest} = match
        convert_latin_to_cyrillic(rest, acc <> cyrillic)

      # Check for title case digraphs (Lj, Nj, Dž)
      match = match_digraph(text, @latin_digraphs_title) ->
        {cyrillic, rest} = match
        convert_latin_to_cyrillic(rest, acc <> cyrillic)

      # Check for lowercase digraphs (lj, nj, dž)
      match = match_digraph(text, @latin_digraphs_lower) ->
        {cyrillic, rest} = match
        convert_latin_to_cyrillic(rest, acc <> cyrillic)

      # Single character conversion
      true ->
        {char, rest} = String.split_at(text, 1)
        cyrillic = convert_latin_char(char)
        convert_latin_to_cyrillic(rest, acc <> cyrillic)
    end
  end

  defp match_digraph(text, digraph_map) do
    Enum.find_value(digraph_map, fn {latin, cyrillic} ->
      if String.starts_with?(text, latin) do
        rest = String.slice(text, String.length(latin)..-1//1)
        {cyrillic, rest}
      end
    end)
  end

  defp convert_latin_char(char) do
    Map.get(@latin_to_cyrillic_lower, char) ||
      Map.get(@latin_to_cyrillic_upper, char) ||
      char
  end

  defp convert_cyrillic_char(char) do
    Map.get(@cyrillic_to_latin_lower, char) ||
      Map.get(@cyrillic_to_latin_upper, char) ||
      char
  end
end
