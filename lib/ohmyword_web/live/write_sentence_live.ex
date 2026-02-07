defmodule OhmywordWeb.WriteSentenceLive do
  @moduledoc """
  LiveView for fill-in-the-blank Serbian sentence exercises.

  Features:
  - Display sentence with blank
  - User types inflected form
  - Diacritic-insensitive answer checking
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
        <:subtitle>Fill in the blank with the correct Serbian form</:subtitle>
      </.header>

      <div class="mt-6 flex items-center justify-between gap-2">
        <.pos_filter pos_filter={@pos_filter} available_pos={@available_pos} />
        <.script_toggle script_mode={@script_mode} />
      </div>

      <%= if @current_sentence do %>
        <div class="mt-6 rounded-xl border-2 border-zinc-300 bg-white p-8 shadow-lg dark:border-zinc-700 dark:bg-zinc-900">
          <!-- Sentence with blank -->
          <div class="text-center">
            <p class="text-2xl font-medium text-zinc-900 dark:text-zinc-100">
              {render_sentence_with_blank(@current_sentence.text, @script_mode)}
            </p>
            <p class="mt-2 text-lg text-zinc-500 dark:text-zinc-400 italic">
              {@current_sentence.translation}
            </p>
          </div>
          
    <!-- Word info -->
          <div class="mt-6 flex flex-wrap items-center justify-center gap-2">
            <.pos_badge part_of_speech={@current_sentence.word.part_of_speech} />
            <%= if @current_sentence.word.gender do %>
              <.gender_badge gender={@current_sentence.word.gender} />
            <% end %>
            <span class="rounded-full bg-zinc-100 px-3 py-1 text-sm text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300">
              {display_term(@current_sentence.word.term, @script_mode)} = {@current_sentence.word.translation}
            </span>
            <span class={"rounded-full px-3 py-1 text-sm font-medium #{case_color_classes(@current_sentence.blank_form_tag)}"}>
              {hint_text(@current_sentence)}
            </span>
          </div>
          
    <!-- Input form -->
          <form phx-submit="submit_answer" class="mt-6">
            <div class="flex gap-3">
              <input
                type="text"
                name="answer"
                value={@user_answer}
                placeholder={if @result, do: "Press Enter for next...", else: "Type your answer..."}
                autocomplete="off"
                autofocus
                readonly={@result != nil}
                class={[
                  "flex-1 rounded-lg border-2 px-4 py-3 text-lg focus:outline-none dark:bg-zinc-800 dark:text-zinc-100",
                  if(@result,
                    do: "border-zinc-200 text-zinc-400 dark:border-zinc-700 dark:text-zinc-500",
                    else:
                      "border-zinc-300 focus:border-zinc-500 dark:border-zinc-600 dark:focus:border-zinc-400"
                  )
                ]}
              />
              <button
                type="submit"
                class={[
                  "rounded-lg px-6 py-3 text-lg font-semibold",
                  if(@result,
                    do:
                      "bg-zinc-700 text-white hover:bg-zinc-600 dark:bg-zinc-200 dark:text-zinc-900 dark:hover:bg-zinc-300",
                    else:
                      "bg-zinc-900 text-white hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
                  )
                ]}
              >
                {if @result, do: "Next →", else: "Check"}
              </button>
            </div>
          </form>
          
    <!-- Result feedback -->
          <%= if @result do %>
            <div class={[
              "mt-6 rounded-lg p-4 text-center",
              if(elem(@result, 0) == :correct,
                do: "bg-green-100 dark:bg-green-900/30",
                else: "bg-red-100 dark:bg-red-900/30"
              )
            ]}>
              <%= if elem(@result, 0) == :correct do %>
                <p class="text-lg font-semibold text-green-800 dark:text-green-200">
                  <.icon name="hero-check-circle" class="inline h-6 w-6 mr-1" /> Correct!
                </p>
                <p class="mt-1 text-green-700 dark:text-green-300">
                  {display_term(elem(@result, 1), @script_mode)}
                </p>
              <% else %>
                <p class="text-lg font-semibold text-red-800 dark:text-red-200">
                  <.icon name="hero-x-circle" class="inline h-6 w-6 mr-1" /> Not quite
                </p>
                <p class="mt-1 text-red-700 dark:text-red-300">
                  Expected: {display_expected_forms(elem(@result, 1), @script_mode)}
                </p>
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

    {:ok,
     socket
     |> assign(current_sentence: sentence)
     |> assign(user_answer: "")
     |> assign(result: nil)
     |> assign(history: [])
     |> assign(script_mode: :latin)
     |> assign(pos_filter: :all)
     |> assign(available_pos: available_pos)}
  end

  @impl true
  def handle_event("submit_answer", _params, %{assigns: %{result: result}} = socket)
      when result != nil do
    # Result already showing — advance to next sentence
    handle_event("next", %{}, socket)
  end

  def handle_event("submit_answer", %{"answer" => answer}, socket) do
    sentence = socket.assigns.current_sentence
    result = Exercises.check_answer(sentence, answer)
    {:noreply, assign(socket, user_answer: answer, result: result)}
  end

  def handle_event("next", _params, socket) do
    sentence = get_filtered_sentence(socket.assigns.pos_filter)

    history =
      if socket.assigns.current_sentence do
        [socket.assigns.current_sentence | socket.assigns.history]
      else
        socket.assigns.history
      end

    {:noreply,
     socket
     |> assign(current_sentence: sentence)
     |> assign(user_answer: "")
     |> assign(result: nil)
     |> assign(history: history)}
  end

  def handle_event("previous", _params, %{assigns: %{history: [prev | rest]}} = socket) do
    {:noreply,
     socket
     |> assign(current_sentence: prev)
     |> assign(user_answer: "")
     |> assign(result: nil)
     |> assign(history: rest)}
  end

  def handle_event("previous", _params, socket), do: {:noreply, socket}

  def handle_event("toggle_script", _params, socket) do
    new_mode = if socket.assigns.script_mode == :latin, do: :cyrillic, else: :latin
    {:noreply, assign(socket, script_mode: new_mode)}
  end

  def handle_event("filter_pos", %{"pos" => pos_value}, socket) do
    pos_filter =
      case pos_value do
        "all" -> :all
        pos -> String.to_existing_atom(pos)
      end

    sentence = get_filtered_sentence(pos_filter)
    available_pos = get_available_pos()

    {:noreply,
     socket
     |> assign(pos_filter: pos_filter)
     |> assign(current_sentence: sentence)
     |> assign(user_answer: "")
     |> assign(result: nil)
     |> assign(available_pos: available_pos)}
  end

  # Private functions

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

  defp render_sentence_with_blank(text, script_mode) do
    text
    |> String.replace("{blank}", "_____")
    |> display_term(script_mode)
  end

  defp hint_text(%{hint: hint}) when is_binary(hint) and hint != "", do: hint
  defp hint_text(%{blank_form_tag: tag}), do: humanize_form_tag(tag)

  defp display_expected_forms(forms, script_mode) do
    forms
    |> Enum.map(&display_term(&1, script_mode))
    |> Enum.join(" / ")
  end

  defp empty_state_title(:all), do: "No sentences available"
  defp empty_state_title(pos), do: "No #{Phoenix.Naming.humanize(pos)} sentences"

  defp empty_state_message(:all),
    do: "No fill-in-the-blank sentences in the database. Run seeds to populate."

  defp empty_state_message(_pos),
    do: "No sentences match the current filter. Try a different type."
end
