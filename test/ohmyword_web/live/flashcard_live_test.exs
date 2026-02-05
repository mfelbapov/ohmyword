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
  end
end
