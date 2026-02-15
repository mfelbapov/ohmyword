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

      html = render_submit(view, "submit_answers", %{"answer" => %{"#{sw_position}" => "psa"}})

      assert html =~ "psa"
    end

    test "submit incorrect answer shows expected form", %{conn: conn} do
      word = noun_fixture(%{term: "pas"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})
      sentence_with_words_fixture(%{word: word, form_tag: "acc_sg", position: 1})

      {:ok, view, _html} = live(conn, ~p"/write")

      html = render_submit(view, "submit_answers", %{"answer" => %{"1" => "wrong"}})

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

      html = render_submit(view, "submit_answers", %{"answer" => %{"1" => "coveka"}})

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
      assert html =~ "Ćć"

      # Toggle to Cyrillic
      html = view |> element("button[phx-click=toggle_script]") |> render_click()

      assert html =~ "Ћћ"
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

      assert html =~ "Easy"
      assert html =~ "Medium"
      assert html =~ "Hard"
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
      render_submit(view, "submit_answers", %{"answer" => %{"1" => "psa"}})

      # Second submit should advance to next
      html = render_submit(view, "submit_answers", %{"answer" => %{"1" => ""}})

      # Result should be cleared
      refute html =~ "Expected:"
    end
  end

  describe "SR→EN direction" do
    test "direction toggle renders and defaults to EN→SR", %{conn: conn} do
      word = noun_fixture(%{term: "pas", translation: "dog"})
      sentence_with_words_fixture(%{word: word})

      {:ok, _view, html} = live(conn, ~p"/write")

      # Direction toggle should be present
      assert html =~ "SR → EN"
      assert html =~ "EN → SR"
      # Default subtitle for EN→SR
      assert html =~ "Fill in the blanks"
    end

    test "toggling direction switches to SR→EN mode", %{conn: conn} do
      word = noun_fixture(%{term: "pas", translation: "dog"})
      sentence_with_words_fixture(%{word: word, text_rs: "Vidim psa.", text_en: "I see a dog."})

      {:ok, view, _html} = live(conn, ~p"/write")

      html = view |> element("button[phx-click=toggle_direction]") |> render_click()

      # Subtitle should change to new SR→EN subtitle
      assert html =~ "Translate the highlighted Serbian words into English"
    end

    test "SR→EN shows all Serbian words visible (highlighted, not blanked)", %{conn: conn} do
      word = noun_fixture(%{term: "pas", translation: "dog"})
      sentence_with_words_fixture(%{word: word, text_rs: "Vidim psa.", text_en: "I see a dog."})

      {:ok, view, _html} = live(conn, ~p"/write")

      # Toggle to SR→EN
      html = view |> element("button[phx-click=toggle_direction]") |> render_click()

      # ALL Serbian words should be visible (highlighted, not blanked)
      assert html =~ "Vidim"
      assert html =~ "psa"
      # English sentence should NOT be shown before submission
      refute html =~ "I see a dog."
    end

    test "SR→EN easy mode shows POS badge with term but not translation", %{conn: conn} do
      word = noun_fixture(%{term: "pas", translation: "dog"})

      sentence_with_words_fixture(%{
        word: word,
        text_rs: "Vidim psa.",
        text_en: "I see a dog.",
        position: 1
      })

      {:ok, view, _html} = live(conn, ~p"/write")

      # Toggle to SR→EN
      html = view |> element("button[phx-click=toggle_direction]") |> render_click()

      # Should show POS badge
      assert html =~ "Noun"
      # Should show term in badge (without translation — that's the answer)
      assert html =~ "pas"
      refute html =~ "pas = dog"
      # English sentence words shown inline (not as "psa =" label)
      refute html =~ "psa ="
      # "I see a" should be visible, "dog" should be blanked
      assert html =~ "see"
    end

    test "SR→EN correct English answer shows success", %{conn: conn} do
      word = noun_fixture(%{term: "pas", translation: "dog"})

      sentence_with_words_fixture(%{
        word: word,
        text_rs: "Vidim psa.",
        text_en: "I see a dog.",
        form_tag: "acc_sg",
        position: 1
      })

      {:ok, view, _html} = live(conn, ~p"/write")

      # Toggle to SR→EN
      view |> element("button[phx-click=toggle_direction]") |> render_click()

      # Answer is English translation (position 3 = "dog" in ["I", "see", "a", "dog"])
      html = render_submit(view, "submit_answers", %{"answer" => %{"3" => "dog"}})

      assert html =~ "hero-check-circle"
      assert html =~ "dog"
      # English sentence should be revealed after submission
      assert html =~ "I see a dog."
    end

    test "SR→EN incorrect answer shows expected English form", %{conn: conn} do
      word = noun_fixture(%{term: "pas", translation: "dog"})

      sentence_with_words_fixture(%{
        word: word,
        text_rs: "Vidim psa.",
        text_en: "I see a dog.",
        form_tag: "acc_sg",
        position: 1
      })

      {:ok, view, _html} = live(conn, ~p"/write")

      # Toggle to SR→EN
      view |> element("button[phx-click=toggle_direction]") |> render_click()

      html = render_submit(view, "submit_answers", %{"answer" => %{"3" => "wrong"}})

      assert html =~ "Expected: dog"
    end

    test "SR→EN checks against exact English token, not dictionary translation", %{conn: conn} do
      word =
        noun_fixture(%{term: "pas", translation: "dog", translations: ["hound", "canine"]})

      sentence_with_words_fixture(%{
        word: word,
        text_rs: "Vidim psa.",
        text_en: "I see a dog.",
        form_tag: "acc_sg",
        position: 1
      })

      {:ok, view, _html} = live(conn, ~p"/write")

      # Toggle to SR→EN
      view |> element("button[phx-click=toggle_direction]") |> render_click()

      # Alternative translation should NOT be accepted — only the exact English word
      html = render_submit(view, "submit_answers", %{"answer" => %{"3" => "hound"}})

      assert html =~ "hero-x-circle"
      assert html =~ "Expected: dog"
    end

    test "SR→EN English sentence revealed only after submission", %{conn: conn} do
      word = noun_fixture(%{term: "pas", translation: "dog"})

      sentence_with_words_fixture(%{
        word: word,
        text_rs: "Vidim psa.",
        text_en: "I see a dog.",
        form_tag: "acc_sg",
        position: 1
      })

      {:ok, view, _html} = live(conn, ~p"/write")

      # Toggle to SR→EN
      html = view |> element("button[phx-click=toggle_direction]") |> render_click()

      # English sentence should NOT be fully visible before submission (dog is blanked)
      refute html =~ "I see a dog."

      # Submit answer (position 3 = "dog")
      html = render_submit(view, "submit_answers", %{"answer" => %{"3" => "dog"}})

      # English sentence should now be visible
      assert html =~ "I see a dog."
    end

    test "toggle direction resets submitted state", %{conn: conn} do
      word = noun_fixture(%{term: "pas", translation: "dog"})
      search_term_fixture(%{word: word, term: "psa", display_form: "psa", form_tag: "acc_sg"})

      sentence_with_words_fixture(%{
        word: word,
        text_rs: "Vidim psa.",
        text_en: "I see a dog.",
        form_tag: "acc_sg",
        position: 1
      })

      {:ok, view, _html} = live(conn, ~p"/write")

      # Submit in EN→SR mode
      render_submit(view, "submit_answers", %{"answer" => %{"1" => "psa"}})

      # Toggle direction should reset
      html = view |> element("button[phx-click=toggle_direction]") |> render_click()

      # Result feedback should be gone
      refute html =~ "hero-check-circle"
      refute html =~ "Expected:"
    end

    test "history preserves direction across next/previous", %{conn: conn} do
      word1 = noun_fixture(%{term: "pas", translation: "dog"})
      word2 = noun_fixture(%{term: "kuća", translation: "house"})
      sentence_with_words_fixture(%{word: word1, text_rs: "Vidim psa.", text_en: "I see a dog."})

      sentence_with_words_fixture(%{
        word: word2,
        text_rs: "Vidim kuću.",
        text_en: "I see a house."
      })

      {:ok, view, _html} = live(conn, ~p"/write")

      # Toggle to SR→EN
      view |> element("button[phx-click=toggle_direction]") |> render_click()

      # Click next
      view |> element("button[phx-click=next]") |> render_click()

      # Click previous — should restore SR→EN mode
      html = view |> element("button[phx-click=previous]") |> render_click()

      # Should still be in SR→EN mode
      assert html =~ "Translate the highlighted Serbian words into English"
    end

    test "SR→EN difficulty 3 only blanks annotated words", %{conn: conn} do
      word = noun_fixture(%{term: "pas", translation: "dog"})

      sentence =
        sentence_fixture(%{text_rs: "Vidim velikog psa.", text_en: "I see a big dog."})

      sentence_word_fixture(%{sentence: sentence, word: word, position: 2, form_tag: "acc_sg"})

      {:ok, view, _html} = live(conn, ~p"/write")

      # Toggle to SR→EN
      view |> element("button[phx-click=toggle_direction]") |> render_click()

      # Switch to difficulty 3
      html =
        view
        |> element(~s(button[phx-click="set_difficulty"][phx-value-level="3"]))
        |> render_click()

      # In SR→EN mode, difficulty 3 should only blank annotated words
      # Unannotated words "Vidim" and "velikog" should still be visible
      assert html =~ "Vidim"
      assert html =~ "velikog"
      # Annotated word "psa" should also be visible (highlighted, not blanked)
      assert html =~ "psa"
    end
  end
end
