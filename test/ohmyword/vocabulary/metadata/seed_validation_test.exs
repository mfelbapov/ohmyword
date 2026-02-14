defmodule Ohmyword.Vocabulary.Metadata.SeedValidationTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Vocabulary.Word

  @seed_path "priv/repo/vocabulary_seed.json"

  describe "seed data validation" do
    test "all 525 seed words pass Word.changeset/2 validation" do
      words = @seed_path |> File.read!() |> Jason.decode!()
      assert length(words) == 525

      failures =
        words
        |> Enum.map(fn word ->
          attrs = build_attrs(word)
          changeset = Word.changeset(%Word{}, attrs)
          {word["term"], word["part_of_speech"], changeset.valid?, changeset.errors}
        end)
        |> Enum.reject(fn {_, _, valid?, _} -> valid? end)

      if failures != [] do
        failure_msgs =
          Enum.map_join(failures, "\n", fn {term, pos, _, errors} ->
            "  #{term} (#{pos}): #{inspect(errors)}"
          end)

        flunk("#{length(failures)} seed words failed validation:\n#{failure_msgs}")
      end
    end
  end

  defp build_attrs(word) do
    base = %{
      term: word["term"],
      translation: word["translation"],
      part_of_speech: String.to_atom(word["part_of_speech"]),
      grammar_metadata: word["grammar_metadata"] || %{},
      proficiency_level: word["proficiency_level"] || 1
    }

    base
    |> maybe_put(:gender, word["gender"], &String.to_atom/1)
    |> maybe_put_raw(:animate, word["animate"])
    |> maybe_put_raw(:declension_class, word["declension_class"])
    |> maybe_put(:verb_aspect, word["verb_aspect"], &String.to_atom/1)
    |> maybe_put_raw(:conjugation_class, word["conjugation_class"])
    |> maybe_put_raw(:reflexive, word["reflexive"])
    |> maybe_put_raw(:transitive, word["transitive"])
  end

  defp maybe_put(attrs, _key, nil, _transform), do: attrs
  defp maybe_put(attrs, key, value, transform), do: Map.put(attrs, key, transform.(value))

  defp maybe_put_raw(attrs, _key, nil), do: attrs
  defp maybe_put_raw(attrs, key, value), do: Map.put(attrs, key, value)
end
