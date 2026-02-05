defmodule Ohmyword.Linguistics.DispatcherTest do
  use Ohmyword.DataCase, async: true

  alias Ohmyword.Linguistics.Dispatcher

  import Ohmyword.VocabularyFixtures

  describe "inflect/1" do
    test "returns empty list for nil" do
      assert Dispatcher.inflect(nil) == []
    end

    test "returns forms for a noun using Nouns inflector" do
      word = noun_fixture(%{term: "pas"})
      forms = Dispatcher.inflect(word)

      # Nouns module generates 14 forms (7 cases x 2 numbers)
      assert length(forms) == 14
      assert {"pas", "nom_sg"} in forms
      assert {"pasa", "gen_sg"} in forms
    end

    test "returns forms for a verb using Verbs inflector" do
      word = verb_fixture(%{term: "pisati"})
      forms = Dispatcher.inflect(word)

      # Verbs module generates 16 forms (inf + 6 present + 6 past + 3 imperative)
      assert length(forms) == 16
      assert {"pisati", "inf"} in forms
      assert {"pisem", "pres_1sg"} in forms
    end

    test "returns forms for an invariable word" do
      word = word_fixture(%{term: "i", part_of_speech: :conjunction})
      forms = Dispatcher.inflect(word)

      assert [{"i", "invariable"}] = forms
    end

    test "downcases the term" do
      word = word_fixture(%{term: "KUĆA", part_of_speech: :adverb})
      forms = Dispatcher.inflect(word)

      assert [{"kuca", "base"}] = forms
    end
  end

  describe "get_inflector/1" do
    test "returns nil for nil" do
      assert Dispatcher.get_inflector(nil) == nil
    end

    test "returns Nouns inflector for noun" do
      word = noun_fixture()
      inflector = Dispatcher.get_inflector(word)

      assert inflector == Ohmyword.Linguistics.Nouns
    end

    test "returns Verbs inflector for verb" do
      word = verb_fixture()
      inflector = Dispatcher.get_inflector(word)

      assert inflector == Ohmyword.Linguistics.Verbs
    end

    test "returns Invariables inflector for adverb" do
      word = word_fixture(%{part_of_speech: :adverb})
      inflector = Dispatcher.get_inflector(word)

      assert inflector == Ohmyword.Linguistics.Invariables
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
