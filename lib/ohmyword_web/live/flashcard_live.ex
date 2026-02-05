defmodule OhmywordWeb.FlashcardLive do
  @moduledoc """
  LiveView for practicing Serbian vocabulary with flashcards.

  Features:
  - Random word selection
  - Card flip interaction
  - Script toggle (Latin/Cyrillic)
  - Linguistic badges (gender, verb aspect)
  """

  use OhmywordWeb, :live_view

  import OhmywordWeb.WordComponents

  alias Ohmyword.Vocabulary

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header>
        Flashcards
        <:subtitle>Practice Serbian vocabulary</:subtitle>
      </.header>

      <div class="mt-6 flex justify-between">
        <.direction_toggle direction_mode={@direction_mode} />
        <.script_toggle script_mode={@script_mode} />
      </div>

      <%= if @current_word do %>
        <div
          class="mt-6 min-h-80 cursor-pointer select-none"
          phx-click="flip"
        >
          <div class={"relative h-80 perspective-1000 transform-style-3d transition-transform duration-500 #{if @flipped, do: "rotate-y-180", else: ""}"}>
            <!-- Front of card -->
            <div class={"absolute inset-0 rounded-xl border-2 border-zinc-300 bg-white p-8 shadow-lg backface-hidden dark:border-zinc-700 dark:bg-zinc-900 #{if @flipped, do: "invisible", else: ""}"}>
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
                  <p class="text-center text-4xl font-bold text-zinc-900 dark:text-zinc-100">
                    {display_term(@current_word.term, @script_mode)}
                  </p>
                <% else %>
                  <p class="text-center text-4xl font-bold text-zinc-900 dark:text-zinc-100">
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
            <div class={"absolute inset-0 rounded-xl border-2 border-zinc-300 bg-white p-8 shadow-lg backface-hidden rotate-y-180 dark:border-zinc-700 dark:bg-zinc-900 #{if not @flipped, do: "invisible", else: ""}"}>
              <div class="flex h-full flex-col items-center justify-center">
                <%= if @direction_mode == :serbian_to_english do %>
                  <p class="text-center text-3xl font-bold text-zinc-900 dark:text-zinc-100">
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
                  <p class="text-center text-3xl font-bold text-zinc-900 dark:text-zinc-100">
                    {display_term(@current_word.term, @script_mode)}
                  </p>
                <% end %>
                <%= if @current_word.example_sentence_rs do %>
                  <div class="mt-6 w-full rounded-lg bg-zinc-100 p-4 dark:bg-zinc-800">
                    <p class="text-sm italic text-zinc-700 dark:text-zinc-300">
                      {display_term(@current_word.example_sentence_rs, @script_mode)}
                    </p>
                    <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                      {@current_word.example_sentence_en}
                    </p>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-6 flex justify-center">
          <button
            phx-click="next"
            class="inline-flex items-center rounded-md bg-zinc-900 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
          >
            Next Card <.icon name="hero-arrow-right" class="ml-2 h-4 w-4" />
          </button>
        </div>
      <% else %>
        <div class="mt-8 rounded-lg border-2 border-dashed border-zinc-300 p-12 text-center dark:border-zinc-700">
          <.icon name="hero-book-open" class="mx-auto h-12 w-12 text-zinc-400" />
          <h3 class="mt-2 text-sm font-semibold text-zinc-900 dark:text-zinc-100">No vocabulary</h3>
          <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
            No words in the database. Run seeds to populate vocabulary.
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    word = Vocabulary.get_random_word()

    {:ok,
     socket
     |> assign(current_word: word)
     |> assign(flipped: false)
     |> assign(script_mode: :latin)
     |> assign(direction_mode: :serbian_to_english)}
  end

  @impl true
  def handle_event("flip", _params, socket) do
    {:noreply, assign(socket, flipped: not socket.assigns.flipped)}
  end

  def handle_event("next", _params, socket) do
    word = Vocabulary.get_random_word()
    {:noreply, socket |> assign(current_word: word) |> assign(flipped: false)}
  end

  def handle_event("toggle_script", _params, socket) do
    new_mode = if socket.assigns.script_mode == :latin, do: :cyrillic, else: :latin
    {:noreply, assign(socket, script_mode: new_mode)}
  end

  def handle_event("toggle_direction", _params, socket) do
    new_mode =
      if socket.assigns.direction_mode == :serbian_to_english,
        do: :english_to_serbian,
        else: :serbian_to_english

    {:noreply, assign(socket, direction_mode: new_mode)}
  end
end
