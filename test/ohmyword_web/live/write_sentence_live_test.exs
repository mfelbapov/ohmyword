defmodule OhmywordWeb.WriteSentenceLiveTest do
  use OhmywordWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Ohmyword.VocabularyFixtures
  import Ohmyword.ExercisesFixtures

  describe "WriteSentenceLive" do
    test "renders write sentence page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/write")
      assert html =~ "Write the Word"
      assert html =~ "Fill in the blank"
    end

    test "shows message when no sentences exist", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/write")
      assert html =~ "No sentences available"
      assert html =~ "Run seeds to populate"
    end

    test "shows sentence when sentences exist", %{conn: conn} do
      sentence = sentence_fixture(%{text: "Vidim {blank}.", translation: "I see."})
      {:ok, _view, html} = live(conn, ~p"/write")
      assert html =~ "Vidim"
      assert html =~ "_____"
      assert html =~ sentence.translation
    end

    test "shows word info badges", %{conn: conn} do
      noun = noun_fixture(%{term: "pas", translation: "dog", gender: :masculine})
      sentence_fixture(%{word: noun})

      {:ok, _view, html} = live(conn, ~p"/write")

      assert html =~ "Noun"
      assert html =~ "pas = dog"
    end

    test "shows hint derived from form_tag", %{conn: conn} do
      noun = noun_fixture(%{term: "pas"})
      sentence_fixture(%{word: noun, blank_form_tag: "acc_sg"})

      {:ok, _view, html} = live(conn, ~p"/write")

      assert html =~ "Accusative Singular"
    end

    test "shows custom hint when provided", %{conn: conn} do
      noun = noun_fixture(%{term: "pas"})
      sentence_fixture(%{word: noun, blank_form_tag: "acc_sg", hint: "custom hint"})

      {:ok, _view, html} = live(conn, ~p"/write")

      assert html =~ "custom hint"
    end

    test "submit correct answer shows success", %{conn: conn} do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      {:ok, view, _html} = live(conn, ~p"/write")

      html = view |> form("form[phx-submit=submit_answer]", %{answer: "psa"}) |> render_submit()

      assert html =~ "Correct!"
      assert html =~ "psa"
    end

    test "submit incorrect answer shows expected form", %{conn: conn} do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      {:ok, view, _html} = live(conn, ~p"/write")

      html = view |> form("form[phx-submit=submit_answer]", %{answer: "wrong"}) |> render_submit()

      assert html =~ "Not quite"
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

      sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      {:ok, view, _html} = live(conn, ~p"/write")

      html =
        view |> form("form[phx-submit=submit_answer]", %{answer: "coveka"}) |> render_submit()

      assert html =~ "Correct!"
    end

    test "accepts cyrillic answer", %{conn: conn} do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      {:ok, view, _html} = live(conn, ~p"/write")

      html = view |> form("form[phx-submit=submit_answer]", %{answer: "пса"}) |> render_submit()

      assert html =~ "Correct!"
    end

    test "next button loads new sentence", %{conn: conn} do
      word1 = noun_fixture(%{term: "pas1"})
      word2 = noun_fixture(%{term: "pas2"})
      sentence_fixture(%{word: word1, text: "Sentence {blank} one."})
      sentence_fixture(%{word: word2, text: "Sentence {blank} two."})

      {:ok, view, _html} = live(conn, ~p"/write")

      # Click next several times
      for _ <- 1..5 do
        view |> element("button[phx-click=next]") |> render_click()
      end

      # Should not crash
      html = render(view)
      assert html =~ "Write the Word"
    end

    test "next button clears result and input", %{conn: conn} do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      {:ok, view, _html} = live(conn, ~p"/write")

      # Submit an answer
      view |> form("form[phx-submit=submit_answer]", %{answer: "psa"}) |> render_submit()

      # Click next
      html = view |> element("button[phx-click=next]") |> render_click()

      # Result should be cleared
      refute html =~ "Correct!"
    end

    test "previous button is disabled on initial load", %{conn: conn} do
      sentence_fixture()
      {:ok, _view, html} = live(conn, ~p"/write")

      assert html =~ "previous"
      assert html =~ "disabled"
    end

    test "previous button works after clicking next", %{conn: conn} do
      word1 = noun_fixture(%{term: "word1"})
      word2 = noun_fixture(%{term: "word2"})
      sentence_fixture(%{word: word1})
      sentence_fixture(%{word: word2})

      {:ok, view, html} = live(conn, ~p"/write")

      # Remember what we saw initially
      initial_has_word1 = html =~ "word1"

      # Click next
      view |> element("button[phx-click=next]") |> render_click()

      # Click previous
      html = view |> element("button[phx-click=previous]") |> render_click()

      # Should match initial state
      if initial_has_word1 do
        assert html =~ "word1"
      end
    end

    test "toggle script switches between Latin and Cyrillic", %{conn: conn} do
      word = noun_fixture(%{term: "ljubav"})
      sentence_fixture(%{word: word, text: "Imam {blank}.", translation: "I have love."})

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
      sentence_fixture(%{word: noun})
      sentence_fixture(%{word: verb})

      {:ok, _view, html} = live(conn, ~p"/write")

      assert html =~ "All types"
      assert html =~ "Noun"
      assert html =~ "Verb"
    end

    test "POS filter limits sentences to matching type", %{conn: conn} do
      noun = noun_fixture(%{term: "uniquenoun"})
      verb = verb_fixture(%{term: "uniqueverb"})
      sentence_fixture(%{word: noun, text: "Noun {blank} sentence."})
      sentence_fixture(%{word: verb, text: "Verb {blank} sentence."})

      {:ok, view, _html} = live(conn, ~p"/write")

      # Filter to noun only
      html = view |> element("form[phx-change=filter_pos]") |> render_change(%{"pos" => "noun"})

      assert html =~ "uniquenoun"
    end

    test "empty state shows POS name when filtered", %{conn: conn} do
      noun = noun_fixture()
      sentence_fixture(%{word: noun})

      {:ok, view, _html} = live(conn, ~p"/write")

      # Filter to verb (no verb sentences exist)
      html = view |> element("form[phx-change=filter_pos]") |> render_change(%{"pos" => "verb"})

      assert html =~ "No Verb sentences"
    end

    test "input is readonly after submitting answer", %{conn: conn} do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      {:ok, view, _html} = live(conn, ~p"/write")

      # Submit an answer
      html = view |> form("form[phx-submit=submit_answer]", %{answer: "psa"}) |> render_submit()

      assert html =~ "readonly"
    end

    test "button shows Next after submitting answer", %{conn: conn} do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      {:ok, view, _html} = live(conn, ~p"/write")

      html = view |> form("form[phx-submit=submit_answer]", %{answer: "psa"}) |> render_submit()

      assert html =~ "Next →"
    end

    test "submitting again after result advances to next sentence", %{conn: conn} do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence_fixture(%{word: word, blank_form_tag: "acc_sg"})

      {:ok, view, _html} = live(conn, ~p"/write")

      # First submit: check the answer
      html = view |> form("form[phx-submit=submit_answer]", %{answer: "psa"}) |> render_submit()
      assert html =~ "Correct!"

      # Second submit: should advance to next (clears result)
      html = view |> form("form[phx-submit=submit_answer]", %{answer: ""}) |> render_submit()
      refute html =~ "Correct!"
      refute html =~ "Not quite"
    end
  end
end
