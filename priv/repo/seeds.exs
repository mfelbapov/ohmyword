# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Ohmyword.Repo.insert!(%Ohmyword.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

if Mix.env() != :test do
  alias Ohmyword.Accounts
  alias Ohmyword.Repo

  email = "a@a.a"
  password = "password"
  username = "username"

  if is_nil(Accounts.get_user_by_email(email)) do
    {:ok, user} =
      Accounts.register_user(%{
        email: email,
        password: password,
        username: username
      })

    # Update to admin role and confirm
    user
    |> Ecto.Changeset.change(role: :admin, confirmed_at: DateTime.utc_now(:second))
    |> Repo.update!()

    IO.puts("Admin user created: #{email} / #{password}")
  else
    IO.puts("Admin user already exists")
  end
end

# Vocabulary seeding
defmodule VocabularySeed do
  alias Ohmyword.Repo
  alias Ohmyword.Vocabulary.Word
  alias Ohmyword.Search.SearchTerm
  alias Ohmyword.Linguistics.CacheManager
  alias Ohmyword.Utils.Transliteration

  def run do
    seed_file = Path.join(:code.priv_dir(:ohmyword), "repo/vocabulary_seed.json")

    if File.exists?(seed_file) do
      IO.puts("Loading vocabulary from #{seed_file}...")

      # Clear existing vocabulary data for clean seed
      Repo.delete_all(SearchTerm)
      Repo.delete_all(Word)

      seed_file
      |> File.read!()
      |> Jason.decode!()
      |> Enum.each(&insert_word_with_forms/1)

      # Link aspect pairs in second pass
      link_aspect_pairs()

      IO.puts("Vocabulary seeding complete!")
    else
      IO.puts("No vocabulary seed file found at #{seed_file}")
    end
  end

  defp insert_word_with_forms(entry) do
    # Extract forms and aspect_pair_term (not part of Word schema)
    {forms, entry} = Map.pop(entry, "forms", [])
    {_aspect_pair_term, entry} = Map.pop(entry, "aspect_pair_term")

    # Convert string keys to atoms for changeset
    attrs = atomize_keys(entry)

    case %Word{} |> Word.changeset(attrs) |> Repo.insert() do
      {:ok, word} ->
        # Insert search terms for each form (locked)
        Enum.each(forms, fn form ->
          insert_search_term(word, form)
        end)

        # Run engine to fill any gaps (won't touch locked forms)
        {:ok, engine_count} = CacheManager.regenerate_word(word)

        if engine_count > 0 do
          IO.puts("  Inserted: #{word.term} (+#{engine_count} engine forms)")
        else
          IO.puts("  Inserted: #{word.term}")
        end

      {:error, changeset} ->
        IO.puts("  ERROR inserting #{entry["term"]}: #{inspect(changeset.errors)}")
    end
  end

  defp insert_search_term(word, %{"term" => term, "form_tag" => form_tag}) do
    %SearchTerm{}
    |> SearchTerm.changeset(%{
      term: term |> Transliteration.strip_diacritics() |> String.downcase(),
      display_form: String.downcase(term),
      form_tag: String.downcase(form_tag),
      word_id: word.id,
      source: :seed,
      locked: true
    })
    |> Repo.insert()
  end

  defp link_aspect_pairs do
    IO.puts("Linking aspect pairs...")

    seed_file = Path.join(:code.priv_dir(:ohmyword), "repo/vocabulary_seed.json")

    seed_file
    |> File.read!()
    |> Jason.decode!()
    |> Enum.filter(&Map.has_key?(&1, "aspect_pair_term"))
    |> Enum.each(fn entry ->
      term = entry["term"]
      pair_term = entry["aspect_pair_term"]

      with word when not is_nil(word) <- Repo.get_by(Word, term: term),
           pair when not is_nil(pair) <- Repo.get_by(Word, term: pair_term) do
        word
        |> Ecto.Changeset.change(aspect_pair_id: pair.id)
        |> Repo.update!()

        IO.puts("  Linked: #{term} <-> #{pair_term}")
      else
        _ -> IO.puts("  Could not link: #{term} -> #{pair_term}")
      end
    end)
  end

  defp atomize_keys(map) do
    Map.new(map, fn {k, v} ->
      key = String.to_existing_atom(k)
      value = convert_enum_value(key, v)
      {key, value}
    end)
  rescue
    ArgumentError -> map
  end

  defp convert_enum_value(:part_of_speech, v) when is_binary(v), do: String.to_existing_atom(v)
  defp convert_enum_value(:gender, v) when is_binary(v), do: String.to_existing_atom(v)
  defp convert_enum_value(:verb_aspect, v) when is_binary(v), do: String.to_existing_atom(v)
  defp convert_enum_value(_, v), do: v
end

if Mix.env() != :test do
  VocabularySeed.run()
end
