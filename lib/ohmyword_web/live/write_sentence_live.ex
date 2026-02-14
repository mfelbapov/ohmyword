defmodule OhmywordWeb.WriteSentenceLive do
  @moduledoc """
  LiveView for multi-blank Serbian sentence exercises.

  Features:
  - Full sentences with multiple blankable words
  - Difficulty selector (1 word / some / all)
  - Per-blank answer checking
  - Script toggle (Latin/Cyrillic)
  - POS filter
  - Navigation (next/previous)
  """

  use OhmywordWeb, :live_view

  import OhmywordWeb.WordComponents

  alias Ohmyword.Exercises
  alias Ohmyword.Vocabulary

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header>
        Write the Word
        <:subtitle>Fill in the blanks with the correct Serbian forms</:subtitle>
      </.header>

      <div class="mt-6 flex items-center justify-between gap-2">
        <.pos_filter pos_filter={@pos_filter} available_pos={@available_pos} />
        <div class="flex items-center gap-2">
          <.difficulty_selector difficulty={@difficulty} />
          <.script_toggle script_mode={@script_mode} />
        </div>
      </div>

      <%= if @current_sentence do %>
        <div class="mt-6 rounded-xl border-2 border-zinc-300 bg-white p-8 shadow-lg dark:border-zinc-700 dark:bg-zinc-900">
          <!-- Translation -->
          <div class="text-center mb-6">
            <p class="text-lg text-zinc-500 dark:text-zinc-400 italic">
              {@current_sentence.text_en}
            </p>
          </div>
          
    <!-- Sentence with blanks -->
          <form phx-submit="submit_answers" class="space-y-6">
            <div class="flex flex-wrap items-baseline gap-1 text-2xl font-medium text-zinc-900 dark:text-zinc-100 justify-center">
              <%= for {token, idx} <- Enum.with_index(@tokens) do %>
                <%= if idx in @blanked_positions do %>
                  <% sw = Enum.find(@blanked_words, & &1.position == idx) %>
                  <div
                    class="inline-flex flex-col items-center mx-2 min-w-0"
                    id={"blank-#{@current_sentence.id}-#{idx}"}
                    phx-hook="CharInputGroup"
                    data-autofocus={to_string(idx == @first_blank)}
                    data-readonly={to_string(@submitted)}
                  >
                    <div class="inline-flex items-center gap-0.5">
                      <%= for ci <- 0..(String.length(token) - 1) do %>
                        <input
                          type="text"
                          maxlength="1"
                          data-char-idx={ci}
                          value={char_at(@answers[idx], ci)}
                          autocomplete="off"
                          readonly={@submitted}
                          placeholder="_"
                          class={[
                            "w-8 h-10 rounded border text-2xl text-center focus:outline-none focus:ring-2 focus:ring-zinc-400 dark:bg-zinc-800 dark:text-zinc-100",
                            char_border_class(@results, idx, @submitted)
                          ]}
                        />
                      <% end %>
                    </div>
                    <input type="hidden" name={"answer[#{idx}]"} value={@answers[idx] || ""} />
                    <%= if sw do %>
                      <span class={"mt-1 text-xs font-medium #{case_color_classes(sw.form_tag)}"}>
                        {humanize_form_tag(sw.form_tag)}
                      </span>
                    <% end %>
                  </div>
                <% else %>
                  <span class="mx-0.5">
                    {display_term(token, @script_mode)}
                  </span>
                <% end %>
              <% end %>
            </div>
            
    <!-- Word info badges -->
            <div class="flex flex-wrap items-center justify-center gap-2">
              <%= for sw <- @blanked_words do %>
                <div class="flex items-center gap-1">
                  <.pos_badge part_of_speech={sw.word.part_of_speech} />
                  <span class="rounded-full bg-zinc-100 px-2 py-0.5 text-xs text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300">
                    {display_term(sw.word.term, @script_mode)} = {sw.word.translation}
                  </span>
                </div>
              <% end %>
            </div>
            
    <!-- Submit / Next button -->
            <div class="flex justify-center">
              <button
                type="submit"
                class={[
                  "rounded-lg px-6 py-3 text-lg font-semibold",
                  if(@submitted,
                    do:
                      "bg-zinc-700 text-white hover:bg-zinc-600 dark:bg-zinc-200 dark:text-zinc-900 dark:hover:bg-zinc-300",
                    else:
                      "bg-zinc-900 text-white hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
                  )
                ]}
              >
                {if @submitted, do: "Next →", else: "Check"}
              </button>
            </div>
          </form>
          
    <!-- Result feedback -->
          <%= if @submitted do %>
            <div class="mt-6 space-y-2">
              <%= for pos <- Enum.sort(MapSet.to_list(@blanked_positions)) do %>
                <% result = @results[pos] %>
                <%= if result do %>
                  <div class={[
                    "rounded-lg p-3 flex items-center gap-2",
                    if(elem(result, 0) == :correct,
                      do: "bg-green-100 dark:bg-green-900/30",
                      else: "bg-red-100 dark:bg-red-900/30"
                    )
                  ]}>
                    <%= if elem(result, 0) == :correct do %>
                      <.icon
                        name="hero-check-circle"
                        class="h-5 w-5 text-green-600 dark:text-green-400"
                      />
                      <span class="text-green-800 dark:text-green-200">
                        {display_term(elem(result, 1), @script_mode)}
                      </span>
                    <% else %>
                      <.icon name="hero-x-circle" class="h-5 w-5 text-red-600 dark:text-red-400" />
                      <span class="text-red-800 dark:text-red-200">
                        Expected: {display_expected_forms(elem(result, 1), @script_mode)}
                      </span>
                    <% end %>
                  </div>
                <% end %>
              <% end %>
            </div>
          <% end %>
        </div>
        
    <!-- Navigation buttons -->
        <div class="mt-6 flex justify-center gap-3">
          <button
            phx-click="previous"
            disabled={@history == []}
            class="inline-flex items-center rounded-md bg-zinc-900 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-zinc-700 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
          >
            <.icon name="hero-arrow-left" class="mr-2 h-4 w-4" /> Previous
          </button>
          <button
            phx-click="next"
            class="inline-flex items-center rounded-md bg-zinc-900 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
          >
            Next <.icon name="hero-arrow-right" class="ml-2 h-4 w-4" />
          </button>
        </div>
      <% else %>
        <div class="mt-8 rounded-lg border-2 border-dashed border-zinc-300 p-12 text-center dark:border-zinc-700">
          <.icon name="hero-pencil-square" class="mx-auto h-12 w-12 text-zinc-400" />
          <h3 class="mt-2 text-sm font-semibold text-zinc-900 dark:text-zinc-100">
            {empty_state_title(@pos_filter)}
          </h3>
          <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
            {empty_state_message(@pos_filter)}
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    sentence = Exercises.get_random_sentence()
    available_pos = get_available_pos()

    socket =
      socket
      |> assign(
        current_sentence: sentence,
        difficulty: 1,
        script_mode: :latin,
        pos_filter: :all,
        available_pos: available_pos,
        history: [],
        submitted: false,
        answers: %{},
        results: %{}
      )
      |> assign_blanks()

    {:ok, socket}
  end

  @impl true
  def handle_event("submit_answers", _params, %{assigns: %{submitted: true}} = socket) do
    # Already submitted — advance to next sentence
    handle_event("next", %{}, socket)
  end

  def handle_event("submit_answers", %{"answer" => answers_map}, socket) do
    sentence = socket.assigns.current_sentence

    # Convert string position keys to integers and store user answers
    answers =
      Map.new(answers_map, fn {pos_str, val} ->
        {String.to_integer(pos_str), val}
      end)

    tokens = socket.assigns.tokens
    annotated_positions = MapSet.new(socket.assigns.blanked_words, & &1.position)

    # Split answers into annotated (check via search_terms) and unannotated (simple match)
    {annotated_answers, unannotated_answers} =
      answers
      |> Enum.filter(fn {pos, _} -> pos in socket.assigns.blanked_positions end)
      |> Enum.split_with(fn {pos, _} -> pos in annotated_positions end)

    annotated_results = Exercises.check_all_answers(sentence, Map.new(annotated_answers))

    unannotated_results =
      Map.new(unannotated_answers, fn {pos, input} ->
        expected = Enum.at(tokens, pos)
        {pos, check_simple_answer(input, expected)}
      end)

    results = Map.merge(annotated_results, unannotated_results)

    # Check if any annotated results have :error (stale data) — skip to next if so
    has_errors =
      Enum.any?(annotated_results, fn {_pos, result} -> elem(result, 0) == :error end)

    if has_errors do
      new_sentence = get_filtered_sentence(socket.assigns.pos_filter)

      socket =
        socket
        |> assign(current_sentence: new_sentence, submitted: false, answers: %{}, results: %{})
        |> assign_blanks()
        |> put_flash(:info, "That sentence is no longer available. Here's a new one.")

      {:noreply, socket}
    else
      {:noreply, assign(socket, submitted: true, answers: answers, results: results)}
    end
  end

  def handle_event("submit_answers", _params, socket) do
    # No answers submitted (empty form)
    {:noreply, socket}
  end

  def handle_event("next", _params, socket) do
    sentence = get_filtered_sentence(socket.assigns.pos_filter)

    history =
      if socket.assigns.current_sentence do
        [
          %{
            sentence: socket.assigns.current_sentence,
            difficulty: socket.assigns.difficulty,
            blanked_words: socket.assigns.blanked_words,
            blanked_positions: socket.assigns.blanked_positions,
            tokens: socket.assigns.tokens
          }
          | socket.assigns.history
        ]
      else
        socket.assigns.history
      end

    socket =
      socket
      |> assign(
        current_sentence: sentence,
        submitted: false,
        answers: %{},
        results: %{},
        history: history
      )
      |> assign_blanks()

    {:noreply, socket}
  end

  def handle_event("previous", _params, %{assigns: %{history: [prev | rest]}} = socket) do
    socket =
      socket
      |> assign(
        current_sentence: prev.sentence,
        difficulty: prev.difficulty,
        blanked_words: prev.blanked_words,
        blanked_positions: prev.blanked_positions,
        tokens: prev.tokens,
        submitted: false,
        answers: %{},
        results: %{},
        history: rest
      )

    {:noreply, socket}
  end

  def handle_event("previous", _params, socket), do: {:noreply, socket}

  def handle_event("toggle_script", _params, socket) do
    new_mode = if socket.assigns.script_mode == :latin, do: :cyrillic, else: :latin
    {:noreply, assign(socket, script_mode: new_mode)}
  end

  def handle_event("set_difficulty", %{"level" => level_str}, socket) do
    difficulty = String.to_integer(level_str)

    socket =
      socket
      |> assign(difficulty: difficulty, submitted: false, answers: %{}, results: %{})
      |> assign_blanks()

    {:noreply, socket}
  end

  def handle_event("filter_pos", %{"pos" => pos_value}, socket) do
    pos_filter =
      case pos_value do
        "all" -> :all
        pos -> String.to_existing_atom(pos)
      end

    sentence = get_filtered_sentence(pos_filter)
    available_pos = get_available_pos()

    socket =
      socket
      |> assign(
        pos_filter: pos_filter,
        current_sentence: sentence,
        submitted: false,
        answers: %{},
        results: %{},
        available_pos: available_pos
      )
      |> assign_blanks()

    {:noreply, socket}
  end

  # Private functions

  defp assign_blanks(socket) do
    case socket.assigns.current_sentence do
      nil ->
        assign(socket, tokens: [], blanked_words: [], blanked_positions: MapSet.new(), first_blank: nil)

      sentence ->
        tokens = Exercises.tokenize(sentence.text_rs)
        blanked = Exercises.select_blanks(sentence, socket.assigns.difficulty)
        annotated_positions = MapSet.new(blanked, & &1.position)

        # Difficulty 3: blank ALL token positions, not just annotated ones
        blanked_positions =
          if socket.assigns.difficulty == 3 do
            MapSet.new(0..(length(tokens) - 1))
          else
            annotated_positions
          end

        first_blank = blanked_positions |> Enum.min(fn -> nil end)

        assign(socket,
          tokens: tokens,
          blanked_words: blanked,
          blanked_positions: blanked_positions,
          first_blank: first_blank
        )
    end
  end

  defp get_filtered_sentence(:all), do: Exercises.get_random_sentence()
  defp get_filtered_sentence(pos), do: Exercises.get_random_sentence(part_of_speech: pos)

  defp get_available_pos do
    sentence_pos = Exercises.list_available_parts_of_speech()

    if sentence_pos == [] do
      Vocabulary.list_available_parts_of_speech()
    else
      sentence_pos
    end
  end

  defp char_at(nil, _idx), do: ""

  defp char_at(answer, idx) do
    answer |> String.graphemes() |> Enum.at(idx, "")
  end

  defp char_border_class(results, position, submitted) do
    if submitted do
      case Map.get(results, position) do
        {:correct, _} -> "border-green-500 bg-green-50 dark:bg-green-900/20"
        {:incorrect, _} -> "border-red-500 bg-red-50 dark:bg-red-900/20"
        _ -> "border-zinc-300 dark:border-zinc-600"
      end
    else
      "border-zinc-300 focus:border-zinc-500 dark:border-zinc-600 dark:focus:border-zinc-400"
    end
  end

  defp display_expected_forms(forms, script_mode) do
    forms
    |> Enum.map(&display_term(&1, script_mode))
    |> Enum.join(" / ")
  end

  defp empty_state_title(:all), do: "No sentences available"
  defp empty_state_title(pos), do: "No #{Phoenix.Naming.humanize(pos)} sentences"

  defp check_simple_answer(input, expected) do
    normalized_input = normalize_simple(input)
    normalized_expected = normalize_simple(expected)

    if normalized_input == normalized_expected do
      {:correct, expected}
    else
      {:incorrect, [expected]}
    end
  end

  defp normalize_simple(text) do
    text
    |> String.trim()
    |> Ohmyword.Utils.Transliteration.to_latin()
    |> Ohmyword.Utils.Transliteration.strip_diacritics()
    |> String.downcase()
  end

  defp empty_state_message(:all),
    do: "No sentences in the database. Run seeds to populate."

  defp empty_state_message(_pos),
    do: "No sentences match the current filter. Try a different type."
end
