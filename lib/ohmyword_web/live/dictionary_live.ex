defmodule OhmywordWeb.DictionaryLive do
  @moduledoc """
  LiveView for searching Serbian vocabulary words.

  Features:
  - Live search with debounce
  - Cyrillic/Latin input support
  - Script toggle for display
  - Shows matched inflected forms
  """

  use OhmywordWeb, :live_view

  import OhmywordWeb.WordComponents

  alias Ohmyword.Search
  alias Ohmyword.Exercises

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <.header>
        Dictionary
        <:subtitle>Look up Serbian vocabulary</:subtitle>
      </.header>

      <div class="mt-6 flex justify-end">
        <.script_toggle script_mode={@script_mode} />
      </div>

      <form phx-change="search" phx-submit="search" class="mt-2">
        <div class="relative">
          <.icon
            name="hero-magnifying-glass"
            class="pointer-events-none absolute left-3 top-1/2 size-5 -translate-y-1/2 text-zinc-400 dark:text-zinc-500"
          />
          <input
            type="search"
            name="query"
            value={@query}
            placeholder="Search Serbian words..."
            phx-debounce="300"
            class="w-full rounded-xl border border-zinc-200 bg-white py-2.5 pl-10 pr-4 text-zinc-900 shadow-sm placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-zinc-400 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-100 dark:placeholder:text-zinc-500 dark:focus:ring-zinc-500"
            autofocus
          />
        </div>
      </form>

      <%= if not @searched do %>
        <div class="mt-12 text-center">
          <.icon name="hero-book-open" class="mx-auto size-12 text-zinc-400" />
          <p class="mt-4 text-zinc-600 dark:text-zinc-400">
            Enter a Serbian word to look up its meaning
          </p>
          <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-500">
            Works with Latin or Cyrillic script, and inflected forms
          </p>
        </div>
      <% else %>
        <%= if @results == [] do %>
          <div class="mt-12 text-center">
            <.icon name="hero-magnifying-glass" class="mx-auto size-12 text-zinc-400" />
            <p class="mt-4 text-zinc-600 dark:text-zinc-400">
              No words found for "{@query}"
            </p>
            <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-500">
              Try a different spelling or the base form
            </p>
          </div>
        <% else %>
          <div class="mt-6 space-y-4">
            <%= for result <- @results do %>
              <div class="rounded-xl border border-zinc-200 bg-white card-default shadow-sm dark:border-zinc-700 dark:bg-zinc-900">
                <div class="flex flex-wrap items-center gap-2">
                  <h3 class="text-xl font-bold text-zinc-900 dark:text-zinc-100">
                    {display_term(result.word.term, @script_mode)}
                  </h3>
                  <.pos_badge part_of_speech={result.word.part_of_speech} />
                  <%= if result.word.gender do %>
                    <.gender_badge gender={result.word.gender} />
                  <% end %>
                  <%= if result.word.verb_aspect do %>
                    <.aspect_badge aspect={result.word.verb_aspect} />
                  <% end %>
                  <%= if result.word.animate do %>
                    <.animate_badge />
                  <% end %>
                </div>

                <%= if result.matched_form != result.word.term do %>
                  <div class="mt-2 flex items-center gap-2">
                    <span class={"inline-flex items-center rounded-full px-3 py-1 text-sm font-medium #{case_color_classes(result.form_tag)}"}>
                      {humanize_form_tag(result.form_tag)}
                    </span>
                    <span class="text-sm text-zinc-500 dark:text-zinc-400">
                      →
                      <span class="font-mono">{display_term(result.matched_form, @script_mode)}</span>
                    </span>
                  </div>
                <% end %>

                <p class="mt-3 text-lg text-zinc-800 dark:text-zinc-200">
                  {result.word.translation}
                </p>
                <%= if result.word.translations != [] do %>
                  <p class="text-zinc-600 dark:text-zinc-400">
                    {Enum.join(result.word.translations, ", ")}
                  </p>
                <% end %>

                <%= if sentence = @sentence_map[result.word.id] |> List.wrap() |> List.first() do %>
                  <div class="mt-4 rounded-lg bg-zinc-50 card-compact dark:bg-zinc-800">
                    <p class="text-sm italic text-zinc-700 dark:text-zinc-300">
                      {display_term(sentence.text_rs, @script_mode)}
                    </p>
                    <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                      {sentence.text_en}
                    </p>
                  </div>
                <% end %>

                <div class="mt-4 flex justify-end">
                  <.link
                    navigate={~p"/dictionary/#{result.word.id}"}
                    class="inline-flex items-center text-sm font-medium text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200"
                  >
                    View all forms <.icon name="hero-arrow-right" class="ml-1 size-4" />
                  </.link>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </.page_container>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(query: "")
     |> assign(results: [])
     |> assign(searched: false)
     |> assign(sentence_map: %{})}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, perform_search(socket, query)}
  end

  defp perform_search(socket, query) when byte_size(query) < 2 do
    socket
    |> assign(query: query)
    |> assign(results: [])
    |> assign(searched: false)
    |> assign(sentence_map: %{})
  end

  defp perform_search(socket, query) do
    results = Search.lookup(query)
    word_ids = results |> Enum.map(& &1.word.id) |> Enum.uniq()
    sentence_map = Exercises.get_sentence_map_for_words(word_ids)

    socket
    |> assign(query: query)
    |> assign(results: results)
    |> assign(searched: true)
    |> assign(sentence_map: sentence_map)
  end
end
