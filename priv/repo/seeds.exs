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
  alias Ohmyword.Vocabulary.WordImporter

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
      |> Enum.each(fn entry ->
        case WordImporter.import_from_seed(entry) do
          {:ok, word} ->
            IO.puts("  Inserted: #{word.term}")

          {:error, changeset} ->
            IO.puts("  ERROR inserting #{entry["term"]}: #{inspect(changeset.errors)}")
        end
      end)

      # Link aspect pairs in second pass
      link_aspect_pairs()

      IO.puts("Vocabulary seeding complete!")
    else
      IO.puts("No vocabulary seed file found at #{seed_file}")
    end
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
end

# Sentences seeding
defmodule SentencesSeed do
  alias Ohmyword.Repo
  alias Ohmyword.Exercises.Sentence
  alias Ohmyword.Exercises.SentenceWord
  alias Ohmyword.Vocabulary.Word
  alias Ohmyword.Exercises

  def run do
    seed_file = Path.join(:code.priv_dir(:ohmyword), "repo/sentences_seed.json")

    if File.exists?(seed_file) do
      IO.puts("Loading sentences from #{seed_file}...")

      # Clear existing data for clean seed
      Repo.delete_all(SentenceWord)
      Repo.delete_all(Sentence)

      seed_file
      |> File.read!()
      |> Jason.decode!()
      |> Enum.each(&insert_sentence/1)

      IO.puts("Sentences seeding complete!")
    else
      IO.puts("No sentences seed file found at #{seed_file}")
    end
  end

  defp insert_sentence(entry) do
    attrs = %{
      text_rs: entry["text_rs"],
      text_en: entry["text_en"]
    }

    case %Sentence{} |> Sentence.changeset(attrs) |> Repo.insert() do
      {:ok, sentence} ->
        tokens = Exercises.tokenize(entry["text_rs"])
        insert_sentence_words(sentence, tokens, entry["words"] || [])
        IO.puts("  Inserted sentence: #{entry["text_rs"]}")

      {:error, changeset} ->
        IO.puts("  ERROR inserting sentence: #{inspect(changeset.errors)}")
    end
  end

  defp insert_sentence_words(sentence, tokens, word_annotations) do
    # Track which token positions have been consumed (for duplicate words)
    Enum.reduce(word_annotations, MapSet.new(), fn annotation, used_positions ->
      word_text = annotation["word"]
      word_term = annotation["word_term"]
      form_tag = annotation["form_tag"]

      case Repo.get_by(Word, term: word_term) do
        nil ->
          IO.puts("    SKIPPED word: '#{word_term}' not found in vocabulary")
          used_positions

        word ->
          # Find position by matching token (case-insensitive), skipping used positions
          position =
            tokens
            |> Enum.with_index()
            |> Enum.find(fn {token, idx} ->
              String.downcase(token) == String.downcase(word_text) &&
                idx not in used_positions
            end)

          case position do
            {_token, idx} ->
              %SentenceWord{}
              |> SentenceWord.changeset(%{
                position: idx,
                form_tag: form_tag,
                sentence_id: sentence.id,
                word_id: word.id
              })
              |> Repo.insert!()

              MapSet.put(used_positions, idx)

            nil ->
              IO.puts("    WARN: Could not find '#{word_text}' in sentence tokens")
              used_positions
          end
      end
    end)
  end
end

if Mix.env() != :test do
  VocabularySeed.run()
  SentencesSeed.run()
end
