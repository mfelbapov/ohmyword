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

  alias Ohmyword.Search
  alias Ohmyword.Utils.Transliteration

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header>
        Dictionary
        <:subtitle>Look up Serbian vocabulary</:subtitle>
      </.header>

      <div class="mt-6 flex justify-end">
        <.script_toggle script_mode={@script_mode} />
      </div>

      <form phx-change="search" phx-submit="search" class="mt-6">
        <input
          type="search"
          name="query"
          value={@query}
          placeholder="Search Serbian words..."
          phx-debounce="300"
          class="input input-bordered w-full"
          autofocus
        />
      </form>

      <%= if not @searched do %>
        <div class="mt-12 text-center">
          <.icon name="hero-book-open" class="mx-auto h-12 w-12 text-zinc-400" />
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
            <.icon name="hero-magnifying-glass" class="mx-auto h-12 w-12 text-zinc-400" />
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
              <div class="rounded-xl border border-zinc-200 bg-white p-6 shadow-sm dark:border-zinc-700 dark:bg-zinc-900">
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

                <%= if result.word.example_sentence_rs do %>
                  <div class="mt-4 rounded-lg bg-zinc-50 p-4 dark:bg-zinc-800">
                    <p class="text-sm italic text-zinc-700 dark:text-zinc-300">
                      {display_term(result.word.example_sentence_rs, @script_mode)}
                    </p>
                    <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                      {result.word.example_sentence_en}
                    </p>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  # Badge components (same as FlashcardLive)

  attr :part_of_speech, :atom, required: true

  defp pos_badge(assigns) do
    ~H"""
    <span class="inline-flex items-center rounded-full bg-zinc-100 px-2.5 py-0.5 text-xs font-medium text-zinc-800 dark:bg-zinc-800 dark:text-zinc-200">
      {Phoenix.Naming.humanize(@part_of_speech)}
    </span>
    """
  end

  attr :gender, :atom, required: true

  defp gender_badge(assigns) do
    colors = %{
      masculine: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200",
      feminine: "bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-200",
      neuter: "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200"
    }

    labels = %{
      masculine: "M",
      feminine: "F",
      neuter: "N"
    }

    assigns = assign(assigns, colors: colors, labels: labels)

    ~H"""
    <span class={"inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{@colors[@gender]}"}>
      {@labels[@gender]}
    </span>
    """
  end

  attr :aspect, :atom, required: true

  defp aspect_badge(assigns) do
    labels = %{
      perfective: "PF",
      imperfective: "IPF",
      biaspectual: "BI"
    }

    assigns = assign(assigns, labels: labels)

    ~H"""
    <span class="inline-flex items-center rounded-full bg-purple-100 px-2.5 py-0.5 text-xs font-medium text-purple-800 dark:bg-purple-900 dark:text-purple-200">
      {@labels[@aspect]}
    </span>
    """
  end

  defp animate_badge(assigns) do
    ~H"""
    <span class="inline-flex items-center rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-800 dark:bg-amber-900 dark:text-amber-200">
      Anim
    </span>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(query: "")
     |> assign(results: [])
     |> assign(searched: false)
     |> assign(script_mode: :latin)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, perform_search(socket, query)}
  end

  def handle_event("toggle_script", _params, socket) do
    new_mode = if socket.assigns.script_mode == :latin, do: :cyrillic, else: :latin
    {:noreply, assign(socket, script_mode: new_mode)}
  end

  defp perform_search(socket, query) when byte_size(query) < 2 do
    socket
    |> assign(query: query)
    |> assign(results: [])
    |> assign(searched: false)
  end

  defp perform_search(socket, query) do
    results = Search.lookup(query)

    socket
    |> assign(query: query)
    |> assign(results: results)
    |> assign(searched: true)
  end

  defp display_term(text, :latin), do: text
  defp display_term(text, :cyrillic), do: Transliteration.to_cyrillic(text)

  defp humanize_form_tag(form_tag) do
    form_tag
    |> String.split("_")
    |> Enum.map(&expand_abbreviation/1)
    |> Enum.join(" ")
  end

  defp expand_abbreviation("nom"), do: "Nominative"
  defp expand_abbreviation("gen"), do: "Genitive"
  defp expand_abbreviation("dat"), do: "Dative"
  defp expand_abbreviation("acc"), do: "Accusative"
  defp expand_abbreviation("voc"), do: "Vocative"
  defp expand_abbreviation("ins"), do: "Instrumental"
  defp expand_abbreviation("loc"), do: "Locative"
  defp expand_abbreviation("sg"), do: "Singular"
  defp expand_abbreviation("pl"), do: "Plural"
  defp expand_abbreviation("masc"), do: "Masculine"
  defp expand_abbreviation("fem"), do: "Feminine"
  defp expand_abbreviation("neut"), do: "Neuter"
  defp expand_abbreviation("def"), do: "Definite"
  defp expand_abbreviation("indef"), do: "Indefinite"
  defp expand_abbreviation("comp"), do: "Comparative"
  defp expand_abbreviation("super"), do: "Superlative"
  defp expand_abbreviation(other), do: String.capitalize(other)

  defp case_color_classes(form_tag) do
    cond do
      String.contains?(form_tag, "nom") ->
        "bg-zinc-100 text-zinc-800 dark:bg-zinc-700 dark:text-zinc-200"

      String.contains?(form_tag, "gen") ->
        "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"

      String.contains?(form_tag, "dat") ->
        "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"

      String.contains?(form_tag, "acc") ->
        "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200"

      String.contains?(form_tag, "voc") ->
        "bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-200"

      String.contains?(form_tag, "ins") ->
        "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"

      String.contains?(form_tag, "loc") ->
        "bg-teal-100 text-teal-800 dark:bg-teal-900 dark:text-teal-200"

      true ->
        "bg-zinc-100 text-zinc-800 dark:bg-zinc-700 dark:text-zinc-200"
    end
  end
end
