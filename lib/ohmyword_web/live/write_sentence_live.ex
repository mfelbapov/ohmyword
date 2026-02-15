defmodule OhmywordWeb.WriteSentenceLive do
  @moduledoc """
  LiveView for multi-blank Serbian sentence exercises.

  Features:
  - Full sentences with multiple blankable words
  - Difficulty selector (1 word / some / all)
  - Per-blank answer checking
  - Script toggle (Latin/Cyrillic)
  - Direction toggle (EN→SR / SR→EN)
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
    <.page_container>
      <.header>
        Write the Word
        <:subtitle>
          <%= if @direction_mode == :english_to_serbian do %>
            Fill in the blanks with the correct Serbian forms
          <% else %>
            Translate the highlighted Serbian words into English
          <% end %>
        </:subtitle>
      </.header>

      <div class="mt-6 flex items-center justify-between gap-2">
        <.pos_filter pos_filter={@pos_filter} available_pos={@available_pos} />
        <div class="flex items-center gap-2">
          <.direction_toggle direction_mode={@direction_mode} />
          <.difficulty_selector difficulty={@difficulty} />
          <.script_toggle script_mode={@script_mode} />
        </div>
      </div>

      <%= if @current_sentence do %>
        <div class="mt-6 rounded-xl border-2 border-zinc-300 bg-white card-spacious shadow-lg dark:border-zinc-700 dark:bg-zinc-900">
          <!-- Sentence + input + button: fixed-height section -->
          <div class="flex min-h-64 flex-col items-center justify-center space-y-6">
            <%= if @direction_mode == :english_to_serbian do %>
              <.render_en_to_sr {assigns} />
            <% else %>
              <.render_sr_to_en {assigns} />
            <% end %>
          </div>
          
    <!-- Result feedback -->
          <%= if @submitted do %>
            <div class="mt-6 space-y-2">
              <% result_positions =
                if @direction_mode == :serbian_to_english,
                  do: @english_blanked_positions,
                  else: @blanked_positions %>
              <%= for pos <- Enum.sort(MapSet.to_list(result_positions)) do %>
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
                        class="size-5 text-green-600 dark:text-green-400"
                      />
                      <span class="text-green-800 dark:text-green-200">
                        {display_result_form(elem(result, 1), @script_mode, @direction_mode)}
                      </span>
                    <% else %>
                      <.icon name="hero-x-circle" class="size-5 text-red-600 dark:text-red-400" />
                      <span class="text-red-800 dark:text-red-200">
                        Expected: {display_expected_forms(
                          elem(result, 1),
                          @script_mode,
                          @direction_mode
                        )}
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
            class="inline-flex w-32 items-center justify-center rounded-md bg-zinc-900 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-zinc-700 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
          >
            <.icon name="hero-arrow-left" class="mr-2 size-4" /> Previous
          </button>
          <button
            phx-click="next"
            class="inline-flex w-32 items-center justify-center rounded-md bg-zinc-900 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
          >
            Next <.icon name="hero-arrow-right" class="ml-2 size-4" />
          </button>
        </div>
      <% else %>
        <div class="mt-8 rounded-lg border-2 border-dashed border-zinc-300 card-empty text-center dark:border-zinc-700">
          <.icon name="hero-pencil-square" class="mx-auto size-12 text-zinc-400" />
          <h3 class="mt-2 text-sm font-semibold text-zinc-900 dark:text-zinc-100">
            {empty_state_title(@pos_filter)}
          </h3>
          <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
            {empty_state_message(@pos_filter)}
          </p>
        </div>
      <% end %>
    </.page_container>
    """
  end

  # EN→SR mode: show English translation, Serbian sentence with inline blanks
  defp render_en_to_sr(assigns) do
    ~H"""
    <!-- Translation -->
    <div class="text-center">
      <p class="text-2xl font-medium text-zinc-900 dark:text-zinc-100">
        {@current_sentence.text_en}
      </p>
    </div>

    <!-- Sentence with blanks -->
    <form phx-submit="submit_answers" class="flex flex-col items-center space-y-6">
      <div class="flex flex-wrap items-baseline gap-1 text-2xl font-medium text-zinc-900 dark:text-zinc-100 justify-center">
        <%= for {token, idx} <- Enum.with_index(@tokens) do %>
          <%= if idx in @blanked_positions do %>
            <% sw = Enum.find(@blanked_words, &(&1.position == idx)) %>
            <.single_text_answer_box
              id={"blank-#{@current_sentence.id}-#{idx}"}
              name={"answer[#{idx}]"}
              answer={@answers[idx]}
              length={String.length(token)}
              submitted={@submitted}
              autofocus={idx == @first_blank}
              result={@results[idx]}
              form_tag={if @difficulty == 1 && sw, do: sw.form_tag}
            />
          <% else %>
            <span class="mx-0.5">
              {display_term(token, @script_mode)}
            </span>
          <% end %>
        <% end %>
      </div>
      
    <!-- Word info badges (Easy only) -->
      <%= if @difficulty == 1 do %>
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
      <% end %>
      
    <!-- Submit / Next button -->
      <button
        type="submit"
        class={[
          "rounded-md px-4 py-2 text-sm font-semibold",
          if(@submitted,
            do:
              "bg-zinc-700 text-white hover:bg-zinc-600 dark:bg-zinc-200 dark:text-zinc-900 dark:hover:bg-zinc-300",
            else:
              "bg-zinc-900 text-white hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
          )
        ]}
      >
        {if @submitted, do: "Next \u2192", else: "Check"}
      </button>
    </form>
    """
  end

  # SR→EN mode: full Serbian sentence with highlighted words, English sentence with inline blanks
  defp render_sr_to_en(assigns) do
    ~H"""
    <!-- Full Serbian sentence with highlighted annotated words -->
    <div class="text-center">
      <p class="flex flex-wrap items-baseline gap-1 text-2xl font-medium text-zinc-900 dark:text-zinc-100 justify-center">
        <%= for {token, idx} <- Enum.with_index(@tokens) do %>
          <%= if idx in @blanked_positions do %>
            <span class="font-bold">
              {display_term(token, @script_mode)}
            </span>
          <% else %>
            <span class="mx-0.5">
              {display_term(token, @script_mode)}
            </span>
          <% end %>
        <% end %>
      </p>
    </div>

    <!-- English sentence with inline blanks -->
    <form phx-submit="submit_answers" class="flex flex-col items-center space-y-6">
      <div class="flex flex-wrap items-baseline gap-1 text-2xl font-medium text-zinc-900 dark:text-zinc-100 justify-center">
        <%= for {token, idx} <- Enum.with_index(@english_tokens) do %>
          <%= if idx in @english_blanked_positions do %>
            <.single_text_answer_box
              id={"blank-#{@current_sentence.id}-en-#{idx}"}
              name={"answer[#{idx}]"}
              answer={@answers[idx]}
              length={String.length(token)}
              submitted={@submitted}
              autofocus={idx == @first_blank}
              result={@results[idx]}
            />
          <% else %>
            <span class="mx-0.5">{token}</span>
          <% end %>
        <% end %>
      </div>
      
    <!-- Word info badges (Easy only) -->
      <%= if @difficulty == 1 do %>
        <div class="flex flex-wrap items-center justify-center gap-2">
          <%= for sw <- @blanked_words do %>
            <div class="flex items-center gap-1">
              <.pos_badge part_of_speech={sw.word.part_of_speech} />
              <span class="rounded-full bg-zinc-100 px-2 py-0.5 text-xs text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300">
                {display_term(sw.word.term, @script_mode)}
              </span>
            </div>
          <% end %>
        </div>
      <% end %>
      
    <!-- Revealed English sentence after submission -->
      <%= if @submitted do %>
        <div class="text-center">
          <p class="text-lg text-zinc-500 dark:text-zinc-400 italic">
            {@current_sentence.text_en}
          </p>
        </div>
      <% end %>
      
    <!-- Submit / Next button -->
      <button
        type="submit"
        class={[
          "rounded-md px-4 py-2 text-sm font-semibold",
          if(@submitted,
            do:
              "bg-zinc-700 text-white hover:bg-zinc-600 dark:bg-zinc-200 dark:text-zinc-900 dark:hover:bg-zinc-300",
            else:
              "bg-zinc-900 text-white hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
          )
        ]}
      >
        {if @submitted, do: "Next \u2192", else: "Check"}
      </button>
    </form>
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
        pos_filter: :all,
        available_pos: available_pos,
        direction_mode: :english_to_serbian,
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
    # Convert string position keys to integers and store user answers
    answers =
      Map.new(answers_map, fn {pos_str, val} ->
        {String.to_integer(pos_str), val}
      end)

    results = check_answers(socket, answers)

    # Check if any results have :error (stale data) — skip to next if so
    has_errors =
      Enum.any?(results, fn {_pos, result} -> elem(result, 0) == :error end)

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
            direction_mode: socket.assigns.direction_mode,
            blanked_words: socket.assigns.blanked_words,
            blanked_positions: socket.assigns.blanked_positions,
            tokens: socket.assigns.tokens,
            english_tokens: socket.assigns.english_tokens,
            english_annotation_map: socket.assigns.english_annotation_map,
            english_blanked_positions: socket.assigns.english_blanked_positions,
            first_blank: socket.assigns.first_blank
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
        direction_mode: prev.direction_mode,
        blanked_words: prev.blanked_words,
        blanked_positions: prev.blanked_positions,
        tokens: prev.tokens,
        english_tokens: prev.english_tokens,
        english_annotation_map: prev.english_annotation_map,
        english_blanked_positions: prev.english_blanked_positions,
        first_blank: prev.first_blank,
        submitted: false,
        answers: %{},
        results: %{},
        history: rest
      )

    {:noreply, socket}
  end

  def handle_event("previous", _params, socket), do: {:noreply, socket}

  def handle_event("set_difficulty", %{"level" => level_str}, socket) do
    difficulty = String.to_integer(level_str)

    socket =
      socket
      |> assign(difficulty: difficulty, submitted: false, answers: %{}, results: %{})
      |> assign_blanks()

    {:noreply, socket}
  end

  def handle_event("toggle_direction", _params, socket) do
    new_mode =
      if socket.assigns.direction_mode == :serbian_to_english,
        do: :english_to_serbian,
        else: :serbian_to_english

    socket =
      socket
      |> assign(direction_mode: new_mode, submitted: false, answers: %{}, results: %{})
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

  defp check_answers(socket, answers) do
    if socket.assigns.direction_mode == :serbian_to_english do
      check_answers_sr_to_en(socket, answers)
    else
      check_answers_en_to_sr(socket, answers)
    end
  end

  defp check_answers_en_to_sr(socket, answers) do
    sentence = socket.assigns.current_sentence
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

    Map.merge(annotated_results, unannotated_results)
  end

  defp check_answers_sr_to_en(socket, answers) do
    english_tokens = socket.assigns.english_tokens

    Map.new(answers, fn {pos, input} ->
      expected = Enum.at(english_tokens, pos)
      {pos, check_simple_answer(input, expected || "")}
    end)
  end

  defp assign_blanks(socket) do
    case socket.assigns.current_sentence do
      nil ->
        assign(socket,
          tokens: [],
          blanked_words: [],
          blanked_positions: MapSet.new(),
          first_blank: nil,
          english_tokens: [],
          english_annotation_map: %{},
          english_blanked_positions: MapSet.new()
        )

      sentence ->
        tokens = Exercises.tokenize(sentence.text_rs)
        blanked = Exercises.select_blanks(sentence, socket.assigns.difficulty)
        annotated_positions = MapSet.new(blanked, & &1.position)

        # Difficulty 3 (Hard): blank ALL tokens in EN→SR
        blanked_positions =
          if socket.assigns.difficulty == 3 &&
               socket.assigns.direction_mode == :english_to_serbian do
            MapSet.new(0..(length(tokens) - 1))
          else
            annotated_positions
          end

        # English token data for SR→EN mode
        english_tokens = Exercises.tokenize(sentence.text_en)
        english_annotation_map = match_english_annotations(english_tokens, blanked)

        english_blanked_positions =
          if socket.assigns.difficulty == 3 do
            MapSet.new(0..(length(english_tokens) - 1))
          else
            MapSet.new(Map.keys(english_annotation_map))
          end

        first_blank =
          if socket.assigns.direction_mode == :serbian_to_english do
            english_blanked_positions |> Enum.min(fn -> nil end)
          else
            blanked_positions |> Enum.min(fn -> nil end)
          end

        assign(socket,
          tokens: tokens,
          blanked_words: blanked,
          blanked_positions: blanked_positions,
          first_blank: first_blank,
          english_tokens: english_tokens,
          english_annotation_map: english_annotation_map,
          english_blanked_positions: english_blanked_positions
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

  defp display_result_form(form, _script_mode, :serbian_to_english), do: form

  defp display_result_form(form, script_mode, _direction_mode),
    do: display_term(form, script_mode)

  defp display_expected_forms(forms, _script_mode, :serbian_to_english) do
    forms
    |> Enum.join(" / ")
  end

  defp display_expected_forms(forms, script_mode, _direction_mode) do
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

  defp match_english_annotations(english_tokens, blanked_words) do
    tokens_with_idx = Enum.with_index(english_tokens)

    {annotation_map, _claimed} =
      Enum.reduce(blanked_words, {%{}, MapSet.new()}, fn sw, {map, claimed} ->
        candidates =
          [sw.word.translation | sw.word.translations || []]
          |> Enum.map(&strip_verb_prefix/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.uniq()
          |> Enum.sort_by(&(-String.length(&1)))

        case find_matching_token(tokens_with_idx, candidates, claimed) do
          nil -> {map, claimed}
          idx -> {Map.put(map, idx, sw), MapSet.put(claimed, idx)}
        end
      end)

    annotation_map
  end

  defp find_matching_token(tokens_with_idx, candidates, claimed) do
    Enum.find_value(candidates, fn candidate ->
      pattern = ~r/^#{Regex.escape(candidate)}\w*$/i

      Enum.find_value(tokens_with_idx, fn {token, idx} ->
        if !MapSet.member?(claimed, idx) && Regex.match?(pattern, token), do: idx
      end)
    end)
  end

  defp strip_verb_prefix("to " <> rest), do: rest
  defp strip_verb_prefix(other), do: other
end
