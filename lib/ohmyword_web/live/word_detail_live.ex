defmodule OhmywordWeb.WordDetailLive do
  @moduledoc """
  LiveView for displaying the detail page of a single vocabulary word,
  including all inflected forms in POS-specific tables.
  """

  use OhmywordWeb, :live_view

  import OhmywordWeb.WordComponents
  import OhmywordWeb.InflectionTableComponents

  alias Ohmyword.Vocabulary
  alias Ohmyword.Exercises
  alias Ohmyword.Linguistics.Dispatcher

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <div class="mb-6">
        <.link
          navigate={~p"/dictionary"}
          class="inline-flex items-center text-sm text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200"
        >
          <.icon name="hero-arrow-left" class="mr-1 h-4 w-4" /> Back to Dictionary
        </.link>
      </div>

      <div class="flex flex-wrap items-center gap-3">
        <h1 class="text-3xl font-bold text-zinc-900 dark:text-zinc-100">
          {display_term(@word.term, @script_mode)}
        </h1>
        <.pos_badge part_of_speech={@word.part_of_speech} />
        <%= if @word.gender do %>
          <.gender_badge gender={@word.gender} />
        <% end %>
        <%= if @word.verb_aspect do %>
          <.aspect_badge aspect={@word.verb_aspect} />
        <% end %>
        <%= if @word.animate do %>
          <.animate_badge />
        <% end %>
      </div>

      <div class="mt-4 flex justify-end">
        <.script_toggle script_mode={@script_mode} />
      </div>

      <%!-- Translations --%>
      <div class="mt-6">
        <p class="text-xl text-zinc-800 dark:text-zinc-200">{@word.translation}</p>
        <%= if @word.translations != [] do %>
          <p class="mt-1 text-zinc-600 dark:text-zinc-400">
            {Enum.join(@word.translations, ", ")}
          </p>
        <% end %>
      </div>

      <%!-- Related adjective (for adverbs) --%>
      <%= if @related_adjective do %>
        <div class="mt-6">
          <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
            Related Adjective
          </h2>
          <div class="mt-2 rounded-lg bg-zinc-50 p-4 dark:bg-zinc-800">
            <div class="flex items-center gap-2">
              <.link
                navigate={~p"/dictionary/#{@related_adjective.word.id}"}
                class="text-base font-medium text-indigo-600 hover:text-indigo-500 dark:text-indigo-400 dark:hover:text-indigo-300"
              >
                {display_term(@related_adjective.word.term, @script_mode)}
                <.icon name="hero-arrow-right" class="ml-1 inline h-4 w-4" />
              </.link>
              <span class="text-sm text-zinc-500 dark:text-zinc-400">
                {@related_adjective.word.translation}
              </span>
            </div>
            <div class="mt-2 flex gap-3">
              <span class="inline-flex items-center rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                M {display_term(@related_adjective.nom_m, @script_mode)}
              </span>
              <span class="inline-flex items-center rounded-full bg-pink-100 px-2.5 py-0.5 text-xs font-medium text-pink-800 dark:bg-pink-900 dark:text-pink-200">
                F {display_term(@related_adjective.nom_f, @script_mode)}
              </span>
              <span class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-800 dark:bg-gray-800 dark:text-gray-200">
                N {display_term(@related_adjective.nom_n, @script_mode)}
              </span>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- Grammar details --%>
      <%= if has_grammar_details?(@word) do %>
        <div class="mt-6">
          <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">Grammar</h2>
          <dl class="mt-2 divide-y divide-zinc-100 dark:divide-zinc-800">
            <%= if @word.declension_class do %>
              <div class="flex gap-4 py-2">
                <dt class="w-40 flex-none text-sm font-medium text-zinc-500 dark:text-zinc-400">
                  Declension class
                </dt>
                <dd class="text-sm text-zinc-700 dark:text-zinc-300">{@word.declension_class}</dd>
              </div>
            <% end %>
            <%= if @word.conjugation_class do %>
              <div class="flex gap-4 py-2">
                <dt class="w-40 flex-none text-sm font-medium text-zinc-500 dark:text-zinc-400">
                  Conjugation class
                </dt>
                <dd class="text-sm text-zinc-700 dark:text-zinc-300">{@word.conjugation_class}</dd>
              </div>
            <% end %>
            <%= if @word.part_of_speech == :verb do %>
              <%= if @word.reflexive do %>
                <div class="flex gap-4 py-2">
                  <dt class="w-40 flex-none text-sm font-medium text-zinc-500 dark:text-zinc-400">
                    Reflexive
                  </dt>
                  <dd class="text-sm text-zinc-700 dark:text-zinc-300">Yes</dd>
                </div>
              <% end %>
              <%= if @word.transitive != nil do %>
                <div class="flex gap-4 py-2">
                  <dt class="w-40 flex-none text-sm font-medium text-zinc-500 dark:text-zinc-400">
                    Transitive
                  </dt>
                  <dd class="text-sm text-zinc-700 dark:text-zinc-300">
                    {if @word.transitive, do: "Yes", else: "No"}
                  </dd>
                </div>
              <% end %>
            <% end %>
          </dl>
        </div>
      <% end %>

      <%!-- Inflection tables --%>
      <div class="mt-8">
        <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">Inflected Forms</h2>
        <div class="mt-4">
          {render_inflection_table(assigns, @word.part_of_speech)}
        </div>
      </div>

      <%!-- Example sentences from sentence bank --%>
      <%= if @sentences != [] do %>
        <div class="mt-8">
          <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">Examples</h2>
          <div class="mt-2 space-y-3">
            <%= for sentence <- @sentences do %>
              <div class="rounded-lg bg-zinc-50 p-4 dark:bg-zinc-800">
                <p class="text-sm italic text-zinc-700 dark:text-zinc-300">
                  {display_term(sentence.text_rs, @script_mode)}
                </p>
                <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                  {sentence.text_en}
                </p>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <%!-- Usage notes --%>
      <%= if @word.usage_notes do %>
        <div class="mt-8">
          <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">Usage Notes</h2>
          <p class="mt-2 text-sm text-zinc-700 dark:text-zinc-300">{@word.usage_notes}</p>
        </div>
      <% end %>

      <%!-- Categories --%>
      <%= if @word.categories != [] do %>
        <div class="mt-8">
          <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">Categories</h2>
          <div class="mt-2 flex flex-wrap gap-2">
            <%= for cat <- @word.categories do %>
              <span class="inline-flex items-center rounded-full bg-zinc-100 px-3 py-1 text-sm font-medium text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300">
                {cat}
              </span>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    word = Vocabulary.get_word!(id)
    forms = Dispatcher.inflect(word)
    forms_map = Map.new(forms, fn {term, tag} -> {tag, term} end)
    sentences = Exercises.get_sentences_for_word(word.id)

    {:ok,
     socket
     |> assign(word: word)
     |> assign(forms: forms)
     |> assign(forms_map: forms_map)
     |> assign(sentences: sentences)
     |> assign_related_adjective(word)}
  end

  defp render_inflection_table(assigns, :noun) do
    ~H"<.noun_table forms_map={@forms_map} script_mode={@script_mode} />"
  end

  defp render_inflection_table(assigns, :verb) do
    ~H"<.verb_table forms_map={@forms_map} script_mode={@script_mode} />"
  end

  defp render_inflection_table(assigns, :adjective) do
    ~H"<.adjective_table forms_map={@forms_map} script_mode={@script_mode} />"
  end

  defp render_inflection_table(assigns, pos) when pos in [:pronoun, :numeral] do
    ~H"<.generic_forms_table forms={@forms} script_mode={@script_mode} />"
  end

  defp render_inflection_table(assigns, _pos) do
    ~H"<.generic_forms_table forms={@forms} script_mode={@script_mode} />"
  end

  defp assign_related_adjective(socket, %{part_of_speech: :adverb, grammar_metadata: meta})
       when is_map(meta) do
    case Map.get(meta, "derived_from") do
      nil ->
        assign(socket, related_adjective: nil)

      adj_term ->
        case Vocabulary.get_word_by_term_and_pos(adj_term, :adjective) do
          nil ->
            assign(socket, related_adjective: nil)

          adj_word ->
            adj_forms = Dispatcher.inflect(adj_word)
            adj_forms_map = Map.new(adj_forms, fn {term, tag} -> {tag, term} end)

            assign(socket,
              related_adjective: %{
                word: adj_word,
                nom_m: adj_forms_map["indef_nom_sg_m"] || adj_word.term,
                nom_f: adj_forms_map["indef_nom_sg_f"] || "-",
                nom_n: adj_forms_map["indef_nom_sg_n"] || "-"
              }
            )
        end
    end
  end

  defp assign_related_adjective(socket, _word) do
    assign(socket, related_adjective: nil)
  end

  defp has_grammar_details?(word) do
    word.declension_class || word.conjugation_class ||
      (word.part_of_speech == :verb && (word.reflexive || word.transitive != nil))
  end
end
