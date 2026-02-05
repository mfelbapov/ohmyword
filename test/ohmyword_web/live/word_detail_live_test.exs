defmodule OhmywordWeb.WordDetailLiveTest do
  use OhmywordWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Ohmyword.VocabularyFixtures

  describe "WordDetailLive" do
    test "renders word detail page for a noun", %{conn: conn} do
      word =
        noun_fixture(%{term: "grad", translation: "city", gender: :masculine, animate: false})

      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "grad"
      assert html =~ "city"
      assert html =~ "Noun"
      assert html =~ "Back to Dictionary"
    end

    test "shows badges for word attributes", %{conn: conn} do
      word = noun_fixture(%{term: "pas", translation: "dog", gender: :masculine, animate: true})
      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "Noun"
      # Masculine badge - blue color
      assert html =~ "bg-blue-100"
      # Animate badge
      assert html =~ "Anim"
    end

    test "shows verb aspect badge", %{conn: conn} do
      word = verb_fixture(%{term: "pisati", translation: "to write", verb_aspect: :imperfective})
      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "Verb"
      assert html =~ "IPF"
    end

    test "shows inflection table with case labels for nouns", %{conn: conn} do
      word =
        noun_fixture(%{term: "grad", translation: "city", gender: :masculine, animate: false})

      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "Nominative"
      assert html =~ "Genitive"
      assert html =~ "Dative"
      assert html =~ "Accusative"
      assert html =~ "Vocative"
      assert html =~ "Instrumental"
      assert html =~ "Locative"
      assert html =~ "Singular"
      assert html =~ "Plural"
    end

    test "renders verb conjugation sections", %{conn: conn} do
      word =
        verb_fixture(%{
          term: "pisati",
          translation: "to write",
          verb_aspect: :imperfective,
          conjugation_class: "e-verb"
        })

      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "Present Tense"
      assert html =~ "Past Participle"
      assert html =~ "Imperative"
      assert html =~ "Infinitive"
    end

    test "toggle script switches between Latin and Cyrillic", %{conn: conn} do
      word =
        noun_fixture(%{
          term: "ljubav",
          translation: "love",
          gender: :feminine,
          declension_class: "i-stem"
        })

      {:ok, view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "LAT"
      assert html =~ "ljubav"

      html = view |> element("button[phx-click=toggle_script]") |> render_click()

      assert html =~ "ЋИР"
      assert html =~ "љубав"
    end

    test "shows back link to dictionary", %{conn: conn} do
      word = word_fixture(%{term: "brzo", translation: "fast"})
      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "Back to Dictionary"
      assert html =~ ~s(href="/dictionary")
    end

    test "shows translations", %{conn: conn} do
      word =
        noun_fixture(%{
          term: "stan",
          translation: "apartment",
          gender: :masculine,
          animate: false,
          translations: ["flat", "dwelling"]
        })

      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "apartment"
      assert html =~ "flat, dwelling"
    end

    test "shows example sentence", %{conn: conn} do
      word =
        noun_fixture(%{
          term: "grad",
          translation: "city",
          gender: :masculine,
          animate: false,
          example_sentence_rs: "Beograd je glavni grad.",
          example_sentence_en: "Belgrade is the capital city."
        })

      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "Beograd je glavni grad."
      assert html =~ "Belgrade is the capital city."
    end

    test "shows usage notes when present", %{conn: conn} do
      word =
        noun_fixture(%{
          term: "grad",
          translation: "city",
          gender: :masculine,
          animate: false,
          usage_notes: "Can also mean hail (weather)."
        })

      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "Usage Notes"
      assert html =~ "Can also mean hail (weather)."
    end

    test "shows categories when present", %{conn: conn} do
      word =
        noun_fixture(%{
          term: "grad",
          translation: "city",
          gender: :masculine,
          animate: false,
          categories: ["geography", "basic"]
        })

      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "Categories"
      assert html =~ "geography"
      assert html =~ "basic"
    end

    test "shows grammar details", %{conn: conn} do
      word =
        noun_fixture(%{
          term: "grad",
          translation: "city",
          gender: :masculine,
          animate: false,
          declension_class: "consonant"
        })

      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "Grammar"
      assert html =~ "Declension class"
      assert html =~ "consonant"
    end

    test "returns error for non-existent word ID", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/dictionary/0")
      end
    end

    test "renders adjective with indefinite and definite sections", %{conn: conn} do
      word = adjective_fixture(%{term: "dobar", translation: "good"})
      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "Indefinite"
      assert html =~ "Definite"
    end

    test "renders invariable word forms", %{conn: conn} do
      word = word_fixture(%{term: "brzo", translation: "fast", part_of_speech: :adverb})
      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      assert html =~ "Inflected Forms"
    end

    test "adverb with derived_from shows related adjective section", %{conn: conn} do
      # Create the adjective that the adverb derives from
      _adj =
        adjective_fixture(%{term: "brz", translation: "fast", gender: :masculine})

      # Create the adverb with derived_from metadata
      adverb =
        word_fixture(%{
          term: "brzo",
          translation: "quickly",
          part_of_speech: :adverb,
          grammar_metadata: %{"derived_from" => "brz"}
        })

      {:ok, _view, html} = live(conn, ~p"/dictionary/#{adverb.id}")

      assert html =~ "Related Adjective"
      assert html =~ "brz"
      # Should show gender form badges
      assert html =~ "M "
      assert html =~ "F "
      assert html =~ "N "
    end

    test "adverb without derived_from does not show related adjective section", %{conn: conn} do
      adverb =
        word_fixture(%{
          term: "ovde",
          translation: "here",
          part_of_speech: :adverb,
          grammar_metadata: %{}
        })

      {:ok, _view, html} = live(conn, ~p"/dictionary/#{adverb.id}")

      refute html =~ "Related Adjective"
    end

    test "non-adverb words do not show related adjective section", %{conn: conn} do
      word =
        noun_fixture(%{term: "grad", translation: "city", gender: :masculine, animate: false})

      {:ok, _view, html} = live(conn, ~p"/dictionary/#{word.id}")

      refute html =~ "Related Adjective"
    end
  end
end
