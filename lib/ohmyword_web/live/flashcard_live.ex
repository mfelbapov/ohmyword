defmodule OhmywordWeb.FlashcardLive do
  @moduledoc """
  LiveView for practicing Serbian vocabulary with flashcards.

  Features:
  - Random word selection
  - Card flip interaction
  - Write mode with per-character input
  - Script toggle (Latin/Cyrillic)
  - Linguistic badges (gender, verb aspect)
  """

  use OhmywordWeb, :live_view

  import OhmywordWeb.WordComponents

  alias Ohmyword.Vocabulary
  alias Ohmyword.Exercises

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <.header>
        Flashcards
        <:subtitle>Practice Serbian vocabulary</:subtitle>
      </.header>

      <div class="mt-6 flex items-center justify-between gap-2">
        <.direction_toggle direction_mode={@direction_mode} />
        <.practice_mode_toggle practice_mode={@practice_mode} />
        <.pos_filter pos_filter={@pos_filter} available_pos={@available_pos} />
        <.category_filter
          category_filter={@category_filter}
          available_categories={@available_categories}
        />
        <.script_toggle script_mode={@script_mode} />
      </div>

      <%= if @current_word do %>
        <%= if @practice_mode == :flip do %>
          <div
            class="mt-6 min-h-80 cursor-pointer select-none"
            phx-click="flip"
          >
            <div class={"relative h-80 perspective-1000 transform-style-3d transition-transform duration-500 #{if @flipped, do: "rotate-y-180", else: ""}"}>
              <!-- Front of card -->
              <div class={"absolute inset-0 rounded-xl border-2 border-zinc-300 bg-white card-spacious shadow-lg backface-hidden dark:border-zinc-700 dark:bg-zinc-900 #{if @flipped, do: "invisible", else: ""}"}>
                <div class="flex h-full flex-col items-center justify-center">
                  <%= if @direction_mode == :serbian_to_english do %>
                    <div class="mb-4 flex flex-wrap gap-2 justify-center">
                      <.pos_badge part_of_speech={@current_word.part_of_speech} />
                      <%= if @current_word.gender do %>
                        <.gender_badge gender={@current_word.gender} />
                      <% end %>
                      <%= if @current_word.verb_aspect do %>
                        <.aspect_badge aspect={@current_word.verb_aspect} />
                      <% end %>
                      <%= if @current_word.animate do %>
                        <.animate_badge />
                      <% end %>
                    </div>
                    <%= if @example_sentence do %>
                      <p class="text-center text-2xl font-medium text-zinc-900 dark:text-zinc-100 px-6">
                        {display_term(@example_sentence.text_rs, @script_mode)}
                      </p>
                    <% else %>
                      <p class="text-center text-prompt font-bold text-zinc-900 dark:text-zinc-100">
                        {display_term(@current_word.term, @script_mode)}
                      </p>
                    <% end %>
                  <% else %>
                    <p class="text-center text-prompt font-bold text-zinc-900 dark:text-zinc-100">
                      {@current_word.translation}
                    </p>
                    <%= if @current_word.translations != [] do %>
                      <p class="mt-2 text-center text-lg text-zinc-600 dark:text-zinc-400">
                        {Enum.join(@current_word.translations, ", ")}
                      </p>
                    <% end %>
                  <% end %>
                  <p class="mt-4 text-sm text-zinc-500 dark:text-zinc-400">
                    Click to reveal translation
                  </p>
                </div>
              </div>
              
    <!-- Back of card -->
              <div class={"absolute inset-0 rounded-xl border-2 border-zinc-300 bg-white card-spacious shadow-lg backface-hidden rotate-y-180 dark:border-zinc-700 dark:bg-zinc-900 #{if not @flipped, do: "invisible", else: ""}"}>
                <div class="flex h-full flex-col items-center justify-center">
                  <%= if @direction_mode == :serbian_to_english do %>
                    <p class="text-center text-answer font-bold text-zinc-900 dark:text-zinc-100">
                      {@current_word.translation}
                    </p>
                    <%= if @current_word.translations != [] do %>
                      <p class="mt-2 text-center text-lg text-zinc-600 dark:text-zinc-400">
                        {Enum.join(@current_word.translations, ", ")}
                      </p>
                    <% end %>
                  <% else %>
                    <div class="mb-4 flex flex-wrap gap-2 justify-center">
                      <.pos_badge part_of_speech={@current_word.part_of_speech} />
                      <%= if @current_word.gender do %>
                        <.gender_badge gender={@current_word.gender} />
                      <% end %>
                      <%= if @current_word.verb_aspect do %>
                        <.aspect_badge aspect={@current_word.verb_aspect} />
                      <% end %>
                      <%= if @current_word.animate do %>
                        <.animate_badge />
                      <% end %>
                    </div>
                    <p class="text-center text-answer font-bold text-zinc-900 dark:text-zinc-100">
                      {display_term(@current_word.term, @script_mode)}
                    </p>
                  <% end %>
                  <%= if @example_sentence && @direction_mode == :english_to_serbian do %>
                    <div class="mt-6 w-full rounded-lg bg-zinc-100 card-compact dark:bg-zinc-800">
                      <p class="text-sm italic text-zinc-700 dark:text-zinc-300">
                        {display_term(@example_sentence.text_rs, @script_mode)}
                      </p>
                      <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                        {@example_sentence.text_en}
                      </p>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <!-- Write mode -->
          <div class="mt-6 rounded-xl border-2 border-zinc-300 bg-white card-spacious shadow-lg dark:border-zinc-700 dark:bg-zinc-900">
            <!-- Prompt + input + button: fixed-height section -->
            <div class="flex min-h-64 flex-col items-center justify-center">
              <%= if @direction_mode == :serbian_to_english do %>
                <div class="mb-4 flex flex-wrap gap-2 justify-center">
                  <.pos_badge part_of_speech={@current_word.part_of_speech} />
                  <%= if @current_word.gender do %>
                    <.gender_badge gender={@current_word.gender} />
                  <% end %>
                  <%= if @current_word.verb_aspect do %>
                    <.aspect_badge aspect={@current_word.verb_aspect} />
                  <% end %>
                  <%= if @current_word.animate do %>
                    <.animate_badge />
                  <% end %>
                </div>
                <%= if @example_sentence do %>
                  <p class="text-center text-2xl font-medium text-zinc-900 dark:text-zinc-100 mb-6 px-6">
                    {display_term(@example_sentence.text_rs, @script_mode)}
                  </p>
                <% else %>
                  <p class="text-center text-prompt font-bold text-zinc-900 dark:text-zinc-100 mb-6">
                    {display_term(@current_word.term, @script_mode)}
                  </p>
                <% end %>
              <% else %>
                <p class="text-center text-prompt font-bold text-zinc-900 dark:text-zinc-100 mb-2">
                  {@current_word.translation}
                </p>
                <p class="mb-6 min-h-7 text-center text-lg text-zinc-600 dark:text-zinc-400">
                  <%= if @current_word.translations != [] do %>
                    {Enum.join(@current_word.translations, ", ")}
                  <% end %>
                </p>
              <% end %>

              <form phx-submit="submit_answer" class="flex flex-col items-center gap-4">
                <.single_text_answer_box
                  id={"flashcard-answer-#{@current_word.id}-#{@answer_key}"}
                  name="answer"
                  answer={@answer}
                  length={answer_length(@current_word, @direction_mode)}
                  submitted={@submitted}
                  autofocus={true}
                  result={@result}
                />
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
                  {if @submitted, do: "Next →", else: "Check"}
                </button>
              </form>
            </div>
            
    <!-- Result feedback -->
            <%= if @submitted do %>
              <div class="mt-6 w-full">
                <div class={[
                  "rounded-lg p-3 flex items-center gap-2",
                  if(elem(@result, 0) == :correct,
                    do: "bg-green-100 dark:bg-green-900/30",
                    else: "bg-red-100 dark:bg-red-900/30"
                  )
                ]}>
                  <%= if elem(@result, 0) == :correct do %>
                    <.icon
                      name="hero-check-circle"
                      class="size-5 text-green-600 dark:text-green-400"
                    />
                    <span class="text-green-800 dark:text-green-200">
                      Correct!
                    </span>
                  <% else %>
                    <.icon
                      name="hero-x-circle"
                      class="size-5 text-red-600 dark:text-red-400"
                    />
                    <span class="text-red-800 dark:text-red-200">
                      Expected: {display_expected(elem(@result, 1), @direction_mode, @script_mode)}
                    </span>
                  <% end %>
                </div>
              </div>
              <%= if @example_sentence && @direction_mode == :english_to_serbian do %>
                <div class="mt-4 w-full rounded-lg bg-zinc-100 card-compact dark:bg-zinc-800">
                  <p class="text-sm italic text-zinc-700 dark:text-zinc-300">
                    {display_term(@example_sentence.text_rs, @script_mode)}
                  </p>
                  <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                    {@example_sentence.text_en}
                  </p>
                </div>
              <% end %>
            <% end %>
          </div>
        <% end %>

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
          <.icon name="hero-book-open" class="mx-auto size-12 text-zinc-400" />
          <h3 class="mt-2 text-sm font-semibold text-zinc-900 dark:text-zinc-100">
            {empty_state_title(@pos_filter, @category_filter)}
          </h3>
          <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
            {empty_state_message(@pos_filter, @category_filter)}
          </p>
        </div>
      <% end %>
    </.page_container>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    word = Vocabulary.get_random_word()

    {:ok,
     socket
     |> assign(current_word: word)
     |> assign(flipped: false)
     |> assign(history: [])
     |> assign(direction_mode: :english_to_serbian)
     |> assign(pos_filter: :all)
     |> assign(available_pos: Vocabulary.list_available_parts_of_speech())
     |> assign(category_filter: "all")
     |> assign(available_categories: Vocabulary.list_available_categories())
     |> assign(practice_mode: :flip)
     |> assign(answer: nil, submitted: false, result: nil, answer_key: 0)
     |> assign_example_sentence(word)}
  end

  @impl true
  def handle_event("flip", _params, socket) do
    {:noreply, assign(socket, flipped: not socket.assigns.flipped)}
  end

  def handle_event("next", _params, socket) do
    word = get_filtered_word(socket)
    history = [socket.assigns.current_word | socket.assigns.history]

    {:noreply,
     socket
     |> assign(current_word: word, history: history, flipped: false)
     |> reset_write_state()
     |> assign_example_sentence(word)}
  end

  def handle_event("previous", _params, %{assigns: %{history: [prev | rest]}} = socket) do
    {:noreply,
     socket
     |> assign(current_word: prev, history: rest, flipped: false)
     |> reset_write_state()
     |> assign_example_sentence(prev)}
  end

  def handle_event("toggle_direction", _params, socket) do
    new_mode =
      if socket.assigns.direction_mode == :serbian_to_english,
        do: :english_to_serbian,
        else: :serbian_to_english

    {:noreply,
     socket
     |> assign(direction_mode: new_mode)
     |> reset_write_state()}
  end

  def handle_event("toggle_practice_mode", _params, socket) do
    new_mode = if socket.assigns.practice_mode == :flip, do: :write, else: :flip

    {:noreply,
     socket
     |> assign(practice_mode: new_mode)
     |> reset_write_state()}
  end

  def handle_event("submit_answer", _params, %{assigns: %{submitted: true}} = socket) do
    handle_event("next", %{}, socket)
  end

  def handle_event("submit_answer", %{"answer" => answer}, socket) do
    result =
      Exercises.check_flashcard_answer(
        socket.assigns.current_word,
        answer,
        socket.assigns.direction_mode
      )

    {:noreply, assign(socket, submitted: true, answer: answer, result: result)}
  end

  def handle_event("submit_answer", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("filter_pos", %{"pos" => pos_value}, socket) do
    pos_filter =
      case pos_value do
        "all" -> :all
        pos -> String.to_existing_atom(pos)
      end

    socket =
      socket
      |> assign(pos_filter: pos_filter)
      |> update_available_options()

    word = get_filtered_word(socket)

    {:noreply,
     socket
     |> assign(current_word: word)
     |> assign(flipped: false)
     |> reset_write_state()
     |> assign_example_sentence(word)}
  end

  def handle_event("filter_category", %{"category" => cat_value}, socket) do
    socket =
      socket
      |> assign(category_filter: cat_value)
      |> update_available_options()

    word = get_filtered_word(socket)

    {:noreply,
     socket
     |> assign(current_word: word)
     |> assign(flipped: false)
     |> reset_write_state()
     |> assign_example_sentence(word)}
  end

  defp reset_write_state(socket) do
    assign(socket,
      answer: nil,
      submitted: false,
      result: nil,
      answer_key: socket.assigns.answer_key + 1
    )
  end

  defp answer_length(word, :serbian_to_english),
    do: word.translation |> String.replace(" ", "") |> String.length()

  defp answer_length(word, :english_to_serbian),
    do: word.term |> String.replace(" ", "") |> String.length()

  defp display_expected(forms, :english_to_serbian, script_mode) do
    forms
    |> Enum.map(&display_term(&1, script_mode))
    |> Enum.join(" / ")
  end

  defp display_expected(forms, :serbian_to_english, _script_mode) do
    Enum.join(forms, " / ")
  end

  defp update_available_options(socket) do
    %{pos_filter: pos, category_filter: cat} = socket.assigns

    pos_opts = if cat != "all", do: [category: cat], else: []
    cat_opts = if pos != :all, do: [part_of_speech: pos], else: []

    socket
    |> assign(available_pos: Vocabulary.list_available_parts_of_speech(pos_opts))
    |> assign(available_categories: Vocabulary.list_available_categories(cat_opts))
  end

  defp get_filtered_word(socket) do
    opts = build_filter_opts(socket.assigns)
    Vocabulary.get_random_word(opts)
  end

  defp build_filter_opts(assigns) do
    opts = []

    opts =
      if assigns.pos_filter != :all,
        do: [{:part_of_speech, assigns.pos_filter} | opts],
        else: opts

    opts =
      if assigns.category_filter != "all",
        do: [{:category, assigns.category_filter} | opts],
        else: opts

    opts
  end

  defp empty_state_title(:all, "all"), do: "No vocabulary"
  defp empty_state_title(:all, cat), do: "No #{cat} words"
  defp empty_state_title(pos, "all"), do: "No #{Phoenix.Naming.humanize(pos)} words"
  defp empty_state_title(pos, cat), do: "No #{Phoenix.Naming.humanize(pos)} words in #{cat}"

  defp empty_state_message(:all, "all"),
    do: "No words in the database. Run seeds to populate vocabulary."

  defp empty_state_message(_pos, _cat),
    do: "No words match the current filters. Try a different combination."

  defp assign_example_sentence(socket, nil), do: assign(socket, example_sentence: nil)

  defp assign_example_sentence(socket, word) do
    sentence =
      Exercises.get_sentences_for_word(word.id, limit: 1)
      |> List.first()

    assign(socket, example_sentence: sentence)
  end
end
