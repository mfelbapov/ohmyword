defmodule OhmywordWeb.FlashcardLiveTest do
  use OhmywordWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Ohmyword.VocabularyFixtures

  describe "FlashcardLive" do
    test "renders flashcard page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/flashcards")
      assert html =~ "Flashcards"
      assert html =~ "Practice Serbian vocabulary"
    end

    test "shows message when no words exist", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/flashcards")
      assert html =~ "No vocabulary"
      assert html =~ "Run seeds to populate vocabulary"
    end

    test "shows word when words exist", %{conn: conn} do
      word = word_fixture(%{term: "testword", translation: "test translation"})
      {:ok, _view, html} = live(conn, ~p"/flashcards")
      assert html =~ word.term
    end

    test "shows part of speech badge", %{conn: conn} do
      noun_fixture(%{term: "pas", translation: "dog"})
      {:ok, _view, html} = live(conn, ~p"/flashcards")
      assert html =~ "Noun"
    end

    test "shows gender badge for nouns", %{conn: conn} do
      noun_fixture(%{term: "pas", translation: "dog", gender: :masculine})
      {:ok, _view, html} = live(conn, ~p"/flashcards")
      # Masculine badge shows "M" - check for the badge with bg-blue color (masculine)
      assert html =~ "bg-blue-100"
    end

    test "shows verb aspect badge for verbs", %{conn: conn} do
      verb_fixture(%{term: "pisati", translation: "to write", verb_aspect: :imperfective})
      {:ok, _view, html} = live(conn, ~p"/flashcards")
      # Imperfective shows "IPF"
      assert html =~ "IPF"
    end

    test "click flips card to show translation", %{conn: conn} do
      word = word_fixture(%{term: "testterm", translation: "testtranslation"})
      {:ok, view, html} = live(conn, ~p"/flashcards")

      # Initially card shows term
      assert html =~ word.term

      # Click to flip
      html = view |> element("div[phx-click=flip]") |> render_click()

      # After flip, translation should be visible
      assert html =~ word.translation
    end

    test "toggle script switches between Latin and Cyrillic", %{conn: conn} do
      word_fixture(%{term: "ljubav", translation: "love"})
      {:ok, view, html} = live(conn, ~p"/flashcards")

      # Initially in Latin mode
      assert html =~ "LAT"
      assert html =~ "ljubav"

      # Toggle to Cyrillic
      html = view |> element("button[phx-click=toggle_script]") |> render_click()

      # Now shows Cyrillic indicator and transliterated text
      assert html =~ "ЋИР"
      assert html =~ "љубав"
    end

    test "next button loads a new word", %{conn: conn} do
      word1 = word_fixture(%{term: "word1", translation: "trans1"})
      word2 = word_fixture(%{term: "word2", translation: "trans2"})

      {:ok, view, _html} = live(conn, ~p"/flashcards")

      # Click next multiple times - should get different words (with some probability)
      terms_seen =
        for _ <- 1..10 do
          view |> element("button[phx-click=next]") |> render_click()

          view
          |> render()
          |> then(fn html ->
            cond do
              html =~ word1.term -> word1.term
              html =~ word2.term -> word2.term
              true -> nil
            end
          end)
        end

      # Should have seen at least the first word at some point
      assert Enum.any?(terms_seen, &(&1 != nil))
    end

    test "displays example sentences on flipped card", %{conn: conn} do
      word =
        word_fixture(%{
          term: "example",
          translation: "example",
          example_sentence_rs: "Primer recenice.",
          example_sentence_en: "Example sentence."
        })

      {:ok, view, _html} = live(conn, ~p"/flashcards")

      # Flip card
      html = view |> element("div[phx-click=flip]") |> render_click()

      assert html =~ word.example_sentence_rs
      assert html =~ word.example_sentence_en
    end

    test "displays alternative translations on flipped card", %{conn: conn} do
      word_fixture(%{
        term: "stan",
        translation: "apartment",
        translations: ["flat", "dwelling"]
      })

      {:ok, view, _html} = live(conn, ~p"/flashcards")

      # Flip card
      html = view |> element("div[phx-click=flip]") |> render_click()

      assert html =~ "flat, dwelling"
    end

    test "animate badge displays for animate masculine nouns", %{conn: conn} do
      noun_fixture(%{term: "pas", translation: "dog", gender: :masculine, animate: true})
      {:ok, _view, html} = live(conn, ~p"/flashcards")
      assert html =~ "Anim"
    end

    test "POS filter dropdown renders with available types", %{conn: conn} do
      noun_fixture(%{term: "pas", translation: "dog"})
      verb_fixture(%{term: "pisati", translation: "to write"})

      {:ok, _view, html} = live(conn, ~p"/flashcards")

      assert html =~ "All types"
      assert html =~ "Noun"
      assert html =~ "Verb"
    end

    test "POS filter changes loaded word to matching type", %{conn: conn} do
      noun_fixture(%{term: "uniquenoun", translation: "a noun"})
      verb_fixture(%{term: "uniqueverb", translation: "a verb"})

      {:ok, view, _html} = live(conn, ~p"/flashcards")

      # Filter to noun only
      html = view |> element("form[phx-change=filter_pos]") |> render_change(%{"pos" => "noun"})

      assert html =~ "uniquenoun"
    end

    test "empty state shows POS name when filtered", %{conn: conn} do
      noun_fixture(%{term: "pas", translation: "dog"})

      {:ok, view, _html} = live(conn, ~p"/flashcards")

      # Filter to numeral (no numeral words exist)
      html =
        view |> element("form[phx-change=filter_pos]") |> render_change(%{"pos" => "numeral"})

      assert html =~ "No Numeral words"
      assert html =~ "No words match the current filters"
    end

    test "previous button is disabled on initial load", %{conn: conn} do
      word_fixture(%{term: "firstword", translation: "first"})
      {:ok, _view, html} = live(conn, ~p"/flashcards")

      # Previous button should exist but be disabled
      assert html =~ "previous"
      assert html =~ "disabled"
    end

    test "previous button becomes enabled after clicking next", %{conn: conn} do
      word_fixture(%{term: "word1", translation: "trans1"})
      word_fixture(%{term: "word2", translation: "trans2"})

      {:ok, view, _html} = live(conn, ~p"/flashcards")

      # Initially disabled
      assert has_element?(view, "button[phx-click=previous][disabled]")

      # Click next to build history
      view |> element("button[phx-click=next]") |> render_click()

      # Previous button should now be enabled (no disabled attribute)
      refute has_element?(view, "button[phx-click=previous][disabled]")
      assert has_element?(view, "button[phx-click=previous]")
    end

    test "clicking previous returns to the previous word", %{conn: conn} do
      word_fixture(%{term: "onlyword", translation: "only"})

      {:ok, view, html} = live(conn, ~p"/flashcards")

      # Note the initial word
      initial_term = "onlyword"
      assert html =~ initial_term

      # Click next (with only one word, it will load the same word, but history should still work)
      view |> element("button[phx-click=next]") |> render_click()

      # Click previous - should return to the saved word from history
      html = view |> element("button[phx-click=previous]") |> render_click()

      assert html =~ initial_term
    end

    test "previous button resets card to unflipped state", %{conn: conn} do
      word_fixture(%{term: "fliptest", translation: "flip"})

      {:ok, view, _html} = live(conn, ~p"/flashcards")

      # Click next then flip the card
      view |> element("button[phx-click=next]") |> render_click()
      view |> element("div[phx-click=flip]") |> render_click()

      # Click previous - card should be unflipped
      html = view |> element("button[phx-click=previous]") |> render_click()

      assert html =~ "Click to reveal translation"
    end

    test "previous button disabled again after going back to beginning", %{conn: conn} do
      word_fixture(%{term: "navword", translation: "nav"})

      {:ok, view, _html} = live(conn, ~p"/flashcards")

      # Click next once to build history of 1
      view |> element("button[phx-click=next]") |> render_click()

      # Click previous to go back - history should now be empty
      html = view |> element("button[phx-click=previous]") |> render_click()

      # Previous button should be disabled again
      assert html =~ "disabled"
    end

    test "can navigate back through multiple words", %{conn: conn} do
      word1 = word_fixture(%{term: "multi1", translation: "m1"})
      word2 = word_fixture(%{term: "multi2", translation: "m2"})

      {:ok, view, _html} = live(conn, ~p"/flashcards")

      # Click next several times to build history
      for _ <- 1..5 do
        view |> element("button[phx-click=next]") |> render_click()
      end

      # Click previous several times - should not crash and should show valid words
      for _ <- 1..5 do
        html = view |> element("button[phx-click=previous]") |> render_click()
        assert html =~ word1.term or html =~ word2.term
      end

      # After exhausting history, previous should be disabled
      html = render(view)
      assert html =~ "disabled"
    end

    test "category filter dropdown renders with available categories", %{conn: conn} do
      word_fixture(%{term: "hleb", categories: ["Food & Drink"]})
      word_fixture(%{term: "pas", categories: ["Nature & Environment"]})

      {:ok, _view, html} = live(conn, ~p"/flashcards")

      assert html =~ "All categories"
      assert html =~ "Food &amp; Drink"
      assert html =~ "Nature &amp; Environment"
    end

    test "category filter changes loaded word to matching category", %{conn: conn} do
      word_fixture(%{term: "uniquefood", categories: ["Food & Drink"]})
      word_fixture(%{term: "uniquenature", categories: ["Nature & Environment"]})

      {:ok, view, _html} = live(conn, ~p"/flashcards")

      html =
        view
        |> element("form[phx-change=filter_category]")
        |> render_change(%{"category" => "Food & Drink"})

      assert html =~ "uniquefood"
    end

    test "combined POS and category filter returns intersection", %{conn: conn} do
      noun_fixture(%{term: "foodnoun", categories: ["Food & Drink"]})
      verb_fixture(%{term: "foodverb", categories: ["Food & Drink"]})
      noun_fixture(%{term: "naturenoun", categories: ["Nature & Environment"]})

      {:ok, view, _html} = live(conn, ~p"/flashcards")

      # Filter to noun
      view |> element("form[phx-change=filter_pos]") |> render_change(%{"pos" => "noun"})

      # Then filter to Food & Drink
      html =
        view
        |> element("form[phx-change=filter_category]")
        |> render_change(%{"category" => "Food & Drink"})

      assert html =~ "foodnoun"
    end

    test "empty state when no words match combined filters", %{conn: conn} do
      noun_fixture(%{term: "foodnoun", categories: ["Food & Drink"]})
      verb_fixture(%{term: "natureverb", categories: ["Nature & Environment"]})

      {:ok, view, _html} = live(conn, ~p"/flashcards")

      # Filter to verb
      view |> element("form[phx-change=filter_pos]") |> render_change(%{"pos" => "verb"})

      # Then filter to Food & Drink (no verbs in Food & Drink)
      html =
        view
        |> element("form[phx-change=filter_category]")
        |> render_change(%{"category" => "Food & Drink"})

      assert html =~ "No Verb words in Food &amp; Drink"
      assert html =~ "No words match the current filters"
    end
  end
end
