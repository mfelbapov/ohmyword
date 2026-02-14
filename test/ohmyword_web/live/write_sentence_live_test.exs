defmodule OhmywordWeb.WriteSentenceLiveTest do
  use OhmywordWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Ohmyword.VocabularyFixtures
  import Ohmyword.ExercisesFixtures

  describe "WriteSentenceLive" do
    test "renders write sentence page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/write")
      assert html =~ "Write the Word"
      assert html =~ "Fill in the blanks"
    end

    test "shows message when no sentences exist", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/write")
      assert html =~ "No sentences available"
      assert html =~ "Run seeds to populate"
    end

    test "shows sentence text when sentences exist", %{conn: conn} do
      word = noun_fixture(%{term: "pas", translation: "dog"})
      sentence_with_words_fixture(%{word: word, text_rs: "Vidim psa.", text_en: "I see a dog."})

      {:ok, _view, html} = live(conn, ~p"/write")
      # Should show the translation
      assert html =~ "I see a dog."
    end

    test "shows word info badges for blanked words", %{conn: conn} do
      noun = noun_fixture(%{term: "pas", translation: "dog", gender: :masculine})
      sentence_with_words_fixture(%{word: noun})

      {:ok, _view, html} = live(conn, ~p"/write")

      assert html =~ "Noun"
      assert html =~ "pas = dog"
    end

    test "shows form tag hint for blanked words", %{conn: conn} do
      noun = noun_fixture(%{term: "pas"})
      sentence_with_words_fixture(%{word: noun, form_tag: "acc_sg"})

      {:ok, _view, html} = live(conn, ~p"/write")

      assert html =~ "Accusative Singular"
    end

    test "submit correct answer shows success", %{conn: conn} do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence_with_words_fixture(%{word: word, form_tag: "acc_sg", position: 1})

      {:ok, view, _html} = live(conn, ~p"/write")

      # Get the position of the blank
      sw_position = 1

      html =
        view
        |> form("form[phx-submit=submit_answers]", %{"answer" => %{"#{sw_position}" => "psa"}})
        |> render_submit()

      assert html =~ "psa"
    end

    test "submit incorrect answer shows expected form", %{conn: conn} do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence_with_words_fixture(%{word: word, form_tag: "acc_sg", position: 1})

      {:ok, view, _html} = live(conn, ~p"/write")

      html =
        view
        |> form("form[phx-submit=submit_answers]", %{"answer" => %{"1" => "wrong"}})
        |> render_submit()

      assert html =~ "Expected: psa"
    end

    test "accepts answer without diacritics", %{conn: conn} do
      word = noun_fixture(%{term: "čovek"})

      search_term_fixture(%{
        word: word,
        term: "coveka",
        display_form: "čoveka",
        form_tag: "acc_sg"
      })

      sentence_with_words_fixture(%{word: word, form_tag: "acc_sg", position: 1})

      {:ok, view, _html} = live(conn, ~p"/write")

      html =
        view
        |> form("form[phx-submit=submit_answers]", %{"answer" => %{"1" => "coveka"}})
        |> render_submit()

      assert html =~ "čoveka"
    end

    test "next button loads new sentence", %{conn: conn} do
      word1 = noun_fixture(%{term: "pas1"})
      word2 = noun_fixture(%{term: "pas2"})
      sentence_with_words_fixture(%{word: word1, text_rs: "Sentence one.", text_en: "One."})
      sentence_with_words_fixture(%{word: word2, text_rs: "Sentence two.", text_en: "Two."})

      {:ok, view, _html} = live(conn, ~p"/write")

      # Click next several times
      for _ <- 1..5 do
        view |> element("button[phx-click=next]") |> render_click()
      end

      # Should not crash
      html = render(view)
      assert html =~ "Write the Word"
    end

    test "previous button is disabled on initial load", %{conn: conn} do
      word = noun_fixture(%{term: "pas"})
      sentence_with_words_fixture(%{word: word})
      {:ok, _view, html} = live(conn, ~p"/write")

      assert html =~ "previous"
      assert html =~ "disabled"
    end

    test "previous button works after clicking next", %{conn: conn} do
      word1 = noun_fixture(%{term: "word1"})
      word2 = noun_fixture(%{term: "word2"})
      sentence_with_words_fixture(%{word: word1, text_rs: "Word1 here.", text_en: "W1."})
      sentence_with_words_fixture(%{word: word2, text_rs: "Word2 here.", text_en: "W2."})

      {:ok, view, _html} = live(conn, ~p"/write")

      # Click next
      view |> element("button[phx-click=next]") |> render_click()

      # Click previous
      html = view |> element("button[phx-click=previous]") |> render_click()

      # Should not crash
      assert html =~ "Write the Word"
    end

    test "toggle script switches between Latin and Cyrillic", %{conn: conn} do
      word = noun_fixture(%{term: "ljubav"})
      sentence_with_words_fixture(%{word: word, text_rs: "Imam ljubav.", text_en: "I have love."})

      {:ok, view, html} = live(conn, ~p"/write")

      # Initially Latin
      assert html =~ "LAT"

      # Toggle to Cyrillic
      html = view |> element("button[phx-click=toggle_script]") |> render_click()

      assert html =~ "ЋИР"
    end

    test "POS filter shows available types", %{conn: conn} do
      noun = noun_fixture()
      verb = verb_fixture()
      sentence_with_words_fixture(%{word: noun})
      sentence_with_words_fixture(%{word: verb})

      {:ok, _view, html} = live(conn, ~p"/write")

      assert html =~ "All types"
      assert html =~ "Noun"
      assert html =~ "Verb"
    end

    test "difficulty selector shows three levels", %{conn: conn} do
      word = noun_fixture()
      sentence_with_words_fixture(%{word: word})

      {:ok, _view, html} = live(conn, ~p"/write")

      assert html =~ "1 blank"
      assert html =~ "Some"
      assert html =~ "All"
    end

    test "changing difficulty re-selects blanks", %{conn: conn} do
      word = noun_fixture(%{term: "pas"})
      sentence = sentence_fixture(%{text_rs: "Vidim velikog psa.", text_en: "I see a big dog."})
      word2 = noun_fixture(%{term: "mačka"})
      sentence_word_fixture(%{sentence: sentence, word: word, position: 2, form_tag: "acc_sg"})
      sentence_word_fixture(%{sentence: sentence, word: word2, position: 1, form_tag: "acc_sg"})

      {:ok, view, _html} = live(conn, ~p"/write")

      # Switch to All difficulty
      html =
        view
        |> element(~s(button[phx-click="set_difficulty"][phx-value-level="3"]))
        |> render_click()

      # Should not crash
      assert html =~ "Write the Word"
    end

    test "submitting again after result advances to next sentence", %{conn: conn} do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence_with_words_fixture(%{word: word, form_tag: "acc_sg", position: 1})

      {:ok, view, _html} = live(conn, ~p"/write")

      # First submit
      view
      |> form("form[phx-submit=submit_answers]", %{"answer" => %{"1" => "psa"}})
      |> render_submit()

      # Second submit should advance to next
      html =
        view
        |> form("form[phx-submit=submit_answers]", %{"answer" => %{"1" => ""}})
        |> render_submit()

      # Result should be cleared
      refute html =~ "Expected:"
    end
  end
end
