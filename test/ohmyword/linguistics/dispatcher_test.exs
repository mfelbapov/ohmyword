defmodule Ohmyword.Linguistics.DispatcherTest do
  use Ohmyword.DataCase, async: true

  alias Ohmyword.Linguistics.Dispatcher

  import Ohmyword.VocabularyFixtures

  describe "inflect/1" do
    test "returns empty list for nil" do
      assert Dispatcher.inflect(nil) == []
    end

    test "returns forms for a noun using stub inflector" do
      word = noun_fixture(%{term: "pas"})
      forms = Dispatcher.inflect(word)

      assert [{"pas", "base"}] = forms
    end

    test "returns forms for a verb using stub inflector" do
      word = verb_fixture(%{term: "pisati"})
      forms = Dispatcher.inflect(word)

      assert [{"pisati", "base"}] = forms
    end

    test "returns forms for an invariable word" do
      word = word_fixture(%{term: "i", part_of_speech: :conjunction})
      forms = Dispatcher.inflect(word)

      assert [{"i", "base"}] = forms
    end

    test "downcases the term" do
      word = word_fixture(%{term: "KUĆA", part_of_speech: :adverb})
      forms = Dispatcher.inflect(word)

      assert [{"kuća", "base"}] = forms
    end
  end

  describe "get_inflector/1" do
    test "returns nil for nil" do
      assert Dispatcher.get_inflector(nil) == nil
    end

    test "returns stub inflector for noun (real Nouns module not implemented yet)" do
      word = noun_fixture()
      inflector = Dispatcher.get_inflector(word)

      assert inflector == Ohmyword.Linguistics.StubInflector
    end

    test "returns stub inflector for verb (real Verbs module not implemented yet)" do
      word = verb_fixture()
      inflector = Dispatcher.get_inflector(word)

      assert inflector == Ohmyword.Linguistics.StubInflector
    end

    test "returns stub inflector for adverb" do
      word = word_fixture(%{part_of_speech: :adverb})
      inflector = Dispatcher.get_inflector(word)

      assert inflector == Ohmyword.Linguistics.StubInflector
    end
  end

  describe "inflectors/0" do
    test "returns list of registered inflector modules" do
      inflectors = Dispatcher.inflectors()

      assert is_list(inflectors)
      assert Ohmyword.Linguistics.StubInflector in inflectors
      assert Ohmyword.Linguistics.Nouns in inflectors
      assert Ohmyword.Linguistics.Verbs in inflectors
    end
  end
end
