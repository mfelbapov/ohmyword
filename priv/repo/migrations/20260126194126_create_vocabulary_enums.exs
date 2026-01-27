defmodule Ohmyword.Repo.Migrations.CreateVocabularyEnums do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE part_of_speech AS ENUM (
      'noun', 'verb', 'adjective', 'adverb', 'pronoun',
      'preposition', 'conjunction', 'interjection', 'particle', 'numeral'
    )
    """

    execute """
    CREATE TYPE grammatical_gender AS ENUM ('masculine', 'feminine', 'neuter')
    """

    execute """
    CREATE TYPE verb_aspect AS ENUM ('perfective', 'imperfective', 'biaspectual')
    """

    execute """
    CREATE TYPE search_term_source AS ENUM ('seed', 'manual', 'engine')
    """
  end

  def down do
    execute "DROP TYPE IF EXISTS search_term_source"
    execute "DROP TYPE IF EXISTS verb_aspect"
    execute "DROP TYPE IF EXISTS grammatical_gender"
    execute "DROP TYPE IF EXISTS part_of_speech"
  end
end
