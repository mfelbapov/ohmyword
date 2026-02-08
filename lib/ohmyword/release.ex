defmodule Ohmyword.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :ohmyword

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _repo ->
          seed_vocabulary()
          seed_sentences()
          create_admin_user()
        end)
    end
  end

  defp seed_vocabulary do
    alias Ohmyword.Repo
    alias Ohmyword.Vocabulary.Word
    alias Ohmyword.Search.SearchTerm
    alias Ohmyword.Linguistics.CacheManager
    alias Ohmyword.Utils.Transliteration

    seed_file = Path.join(:code.priv_dir(:ohmyword), "repo/vocabulary_seed.json")

    if File.exists?(seed_file) do
      IO.puts("Loading vocabulary from #{seed_file}...")

      Repo.delete_all(SearchTerm)
      Repo.delete_all(Word)

      seed_file
      |> File.read!()
      |> Jason.decode!()
      |> Enum.each(fn entry ->
        {forms, entry} = Map.pop(entry, "forms", [])
        {_aspect_pair_term, entry} = Map.pop(entry, "aspect_pair_term")

        attrs = atomize_keys(entry)

        case %Word{} |> Word.changeset(attrs) |> Repo.insert() do
          {:ok, word} ->
            Enum.each(forms, fn %{"term" => term, "form_tag" => form_tag} ->
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
            end)

            {:ok, engine_count} = CacheManager.regenerate_word(word)

            if engine_count > 0,
              do: IO.puts("  Inserted: #{word.term} (+#{engine_count} engine forms)")

          {:error, changeset} ->
            IO.puts("  ERROR: #{inspect(changeset.errors)}")
        end
      end)

      link_aspect_pairs()
      IO.puts("Vocabulary seeding complete!")
    else
      IO.puts("No vocabulary seed file found")
    end
  end

  defp link_aspect_pairs do
    alias Ohmyword.Repo
    alias Ohmyword.Vocabulary.Word

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
      end
    end)
  end

  defp seed_sentences do
    alias Ohmyword.Repo
    alias Ohmyword.Exercises.Sentence
    alias Ohmyword.Vocabulary.Word

    seed_file = Path.join(:code.priv_dir(:ohmyword), "repo/sentences_seed.json")

    if File.exists?(seed_file) do
      IO.puts("Loading sentences...")

      Repo.delete_all(Sentence)

      seed_file
      |> File.read!()
      |> Jason.decode!()
      |> Enum.each(fn entry ->
        word_term = entry["word_term"]

        case Repo.get_by(Word, term: word_term) do
          nil ->
            :skip

          word ->
            %Sentence{}
            |> Sentence.changeset(%{
              text: entry["text"],
              translation: entry["translation"],
              blank_form_tag: entry["blank_form_tag"],
              hint: entry["hint"],
              word_id: word.id
            })
            |> Repo.insert()
        end
      end)

      IO.puts("Sentences seeding complete!")
    end
  end

  defp create_admin_user do
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

      user
      |> Ecto.Changeset.change(role: :admin, confirmed_at: DateTime.utc_now(:second))
      |> Repo.update!()

      IO.puts("Admin user created: #{email}")
    end
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

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
