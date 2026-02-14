defmodule OhmywordWeb.WordDetailLive do
  @moduledoc """
  LiveView for displaying the detail page of a single vocabulary word,
  including all inflected forms in POS-specific tables.
  """

  use OhmywordWeb, :live_view

  import OhmywordWeb.WordComponents

  alias Ohmyword.Vocabulary
  alias Ohmyword.Exercises
  alias Ohmyword.Linguistics.Dispatcher

  @noun_cases ~w(nom gen dat acc voc ins loc)
  @verb_persons ~w(1sg 2sg 3sg 1pl 2pl 3pl)
  @person_labels %{
    "1sg" => "ja",
    "2sg" => "ti",
    "3sg" => "on/ona/ono",
    "1pl" => "mi",
    "2pl" => "vi",
    "3pl" => "oni/one/ona"
  }
  @adj_genders ~w(m f n)
  @adj_gender_labels %{"m" => "M", "f" => "F", "n" => "N"}

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
          {render_inflection_table(assigns)}
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
     |> assign(script_mode: :latin)
     |> assign_related_adjective(word)}
  end

  @impl true
  def handle_event("toggle_script", _params, socket) do
    new_mode = if socket.assigns.script_mode == :latin, do: :cyrillic, else: :latin
    {:noreply, assign(socket, script_mode: new_mode)}
  end

  # Inflection table rendering by POS

  defp render_inflection_table(%{word: %{part_of_speech: :noun}} = assigns) do
    cases = @noun_cases
    assigns = assign(assigns, cases: cases)

    ~H"""
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-700">
        <thead>
          <tr>
            <th class="py-2 pr-4 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
              Case
            </th>
            <th class="px-4 py-2 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
              Singular
            </th>
            <th class="px-4 py-2 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
              Plural
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
          <%= for c <- @cases do %>
            <tr>
              <td class={"py-2 pr-4 text-sm font-medium #{case_color_classes(c <> "_sg")}  rounded-l px-2"}>
                {humanize_form_tag(c)}
              </td>
              <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                {display_term(@forms_map[c <> "_sg"] || "-", @script_mode)}
              </td>
              <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                {display_term(@forms_map[c <> "_pl"] || "-", @script_mode)}
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp render_inflection_table(%{word: %{part_of_speech: :verb}} = assigns) do
    persons = @verb_persons
    person_labels = @person_labels

    assigns =
      assigns
      |> assign(persons: persons)
      |> assign(person_labels: person_labels)

    ~H"""
    <div class="space-y-8">
      <%!-- Infinitive --%>
      <div>
        <h3 class="text-sm font-semibold text-zinc-700 dark:text-zinc-300 uppercase tracking-wide">
          Infinitive
        </h3>
        <p class="mt-1 text-sm font-mono text-zinc-700 dark:text-zinc-300">
          {display_term(@forms_map["inf"] || "-", @script_mode)}
        </p>
      </div>

      <%!-- Present tense --%>
      <div>
        <h3 class="text-sm font-semibold text-zinc-700 dark:text-zinc-300 uppercase tracking-wide">
          Present Tense
        </h3>
        <table class="mt-2 min-w-full divide-y divide-zinc-200 dark:divide-zinc-700">
          <thead>
            <tr>
              <th class="py-2 pr-4 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                Person
              </th>
              <th class="px-4 py-2 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                Form
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
            <%= for p <- @persons do %>
              <tr>
                <td class="py-2 pr-4 text-sm text-zinc-500 dark:text-zinc-400">
                  {display_term(@person_labels[p], @script_mode)}
                </td>
                <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                  {display_term(@forms_map["pres_" <> p] || "-", @script_mode)}
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

      <%!-- Past participle --%>
      <div>
        <h3 class="text-sm font-semibold text-zinc-700 dark:text-zinc-300 uppercase tracking-wide">
          Past Participle
        </h3>
        <table class="mt-2 min-w-full divide-y divide-zinc-200 dark:divide-zinc-700">
          <thead>
            <tr>
              <th class="py-2 pr-4 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                Gender
              </th>
              <th class="px-4 py-2 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                Singular
              </th>
              <th class="px-4 py-2 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                Plural
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
            <tr>
              <td class="py-2 pr-4 text-sm text-zinc-500 dark:text-zinc-400">Masculine</td>
              <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                {display_term(@forms_map["past_m_sg"] || "-", @script_mode)}
              </td>
              <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                {display_term(@forms_map["past_m_pl"] || "-", @script_mode)}
              </td>
            </tr>
            <tr>
              <td class="py-2 pr-4 text-sm text-zinc-500 dark:text-zinc-400">Feminine</td>
              <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                {display_term(@forms_map["past_f_sg"] || "-", @script_mode)}
              </td>
              <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                {display_term(@forms_map["past_f_pl"] || "-", @script_mode)}
              </td>
            </tr>
            <tr>
              <td class="py-2 pr-4 text-sm text-zinc-500 dark:text-zinc-400">Neuter</td>
              <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                {display_term(@forms_map["past_n_sg"] || "-", @script_mode)}
              </td>
              <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                {display_term(@forms_map["past_n_pl"] || "-", @script_mode)}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <%!-- Imperative --%>
      <div>
        <h3 class="text-sm font-semibold text-zinc-700 dark:text-zinc-300 uppercase tracking-wide">
          Imperative
        </h3>
        <table class="mt-2 min-w-full divide-y divide-zinc-200 dark:divide-zinc-700">
          <thead>
            <tr>
              <th class="py-2 pr-4 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                Person
              </th>
              <th class="px-4 py-2 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                Form
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
            <tr>
              <td class="py-2 pr-4 text-sm text-zinc-500 dark:text-zinc-400">
                {display_term("ti", @script_mode)}
              </td>
              <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                {display_term(@forms_map["imp_2sg"] || "-", @script_mode)}
              </td>
            </tr>
            <tr>
              <td class="py-2 pr-4 text-sm text-zinc-500 dark:text-zinc-400">
                {display_term("mi", @script_mode)}
              </td>
              <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                {display_term(@forms_map["imp_1pl"] || "-", @script_mode)}
              </td>
            </tr>
            <tr>
              <td class="py-2 pr-4 text-sm text-zinc-500 dark:text-zinc-400">
                {display_term("vi", @script_mode)}
              </td>
              <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                {display_term(@forms_map["imp_2pl"] || "-", @script_mode)}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp render_inflection_table(%{word: %{part_of_speech: :adjective}} = assigns) do
    cases = @noun_cases
    genders = @adj_genders
    gender_labels = @adj_gender_labels

    assigns =
      assigns
      |> assign(cases: cases)
      |> assign(genders: genders)
      |> assign(gender_labels: gender_labels)

    ~H"""
    <div class="space-y-8">
      <%= for {paradigm, paradigm_label} <- [{"indef", "Indefinite"}, {"def", "Definite"}] do %>
        <div>
          <h3 class="text-sm font-semibold text-zinc-700 dark:text-zinc-300 uppercase tracking-wide">
            {paradigm_label}
          </h3>
          <div class="mt-2 overflow-x-auto">
            <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-700">
              <thead>
                <tr>
                  <th class="py-2 pr-4 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                    Case
                  </th>
                  <%= for {g, gl} <- Enum.zip(@genders, ["M", "F", "N"]) do %>
                    <th class="px-3 py-2 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                      {gl} sg
                    </th>
                  <% end %>
                  <%= for {g, gl} <- Enum.zip(@genders, ["M", "F", "N"]) do %>
                    <th class="px-3 py-2 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                      {gl} pl
                    </th>
                  <% end %>
                </tr>
              </thead>
              <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
                <%= for c <- @cases do %>
                  <tr>
                    <td class={"py-2 pr-4 text-sm font-medium #{case_color_classes(c <> "_sg")} rounded-l px-2"}>
                      {humanize_form_tag(c)}
                    </td>
                    <%= for g <- @genders do %>
                      <td class="px-3 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                        {display_term(@forms_map["#{paradigm}_#{c}_sg_#{g}"] || "-", @script_mode)}
                      </td>
                    <% end %>
                    <%= for g <- @genders do %>
                      <td class="px-3 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                        {display_term(@forms_map["#{paradigm}_#{c}_pl_#{g}"] || "-", @script_mode)}
                      </td>
                    <% end %>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% end %>

      <%!-- Comparative & Superlative --%>
      <%= if has_comparison?(@forms_map) do %>
        <%= for {paradigm, paradigm_label} <- [{"comp", "Comparative"}, {"super", "Superlative"}] do %>
          <div>
            <h3 class="text-sm font-semibold text-zinc-700 dark:text-zinc-300 uppercase tracking-wide">
              {paradigm_label}
            </h3>
            <div class="mt-2 overflow-x-auto">
              <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-700">
                <thead>
                  <tr>
                    <th class="py-2 pr-4 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                      Case
                    </th>
                    <%= for {g, gl} <- Enum.zip(@genders, ["M", "F", "N"]) do %>
                      <th class="px-3 py-2 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                        {gl} sg
                      </th>
                    <% end %>
                    <%= for {g, gl} <- Enum.zip(@genders, ["M", "F", "N"]) do %>
                      <th class="px-3 py-2 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                        {gl} pl
                      </th>
                    <% end %>
                  </tr>
                </thead>
                <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
                  <%= for c <- @cases do %>
                    <tr>
                      <td class={"py-2 pr-4 text-sm font-medium #{case_color_classes(c <> "_sg")} rounded-l px-2"}>
                        {humanize_form_tag(c)}
                      </td>
                      <%= for g <- @genders do %>
                        <td class="px-3 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                          {display_term(@forms_map["#{paradigm}_#{c}_sg_#{g}"] || "-", @script_mode)}
                        </td>
                      <% end %>
                      <%= for g <- @genders do %>
                        <td class="px-3 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                          {display_term(@forms_map["#{paradigm}_#{c}_pl_#{g}"] || "-", @script_mode)}
                        </td>
                      <% end %>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp render_inflection_table(%{word: %{part_of_speech: pos}} = assigns)
       when pos in [:pronoun, :numeral] do
    sorted_forms =
      assigns.forms
      |> Enum.sort_by(fn {_term, tag} -> tag end)

    assigns = assign(assigns, sorted_forms: sorted_forms)

    ~H"""
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-700">
        <thead>
          <tr>
            <th class="py-2 pr-4 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
              Form
            </th>
            <th class="px-4 py-2 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
              Value
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
          <%= for {term, tag} <- @sorted_forms do %>
            <tr>
              <td class="py-2 pr-4 text-sm font-medium text-zinc-500 dark:text-zinc-400">
                {humanize_form_tag(tag)}
              </td>
              <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                {display_term(term, @script_mode)}
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  # Invariables (adverbs, prepositions, conjunctions, etc.)
  defp render_inflection_table(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-700">
        <thead>
          <tr>
            <th class="py-2 pr-4 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
              Form
            </th>
            <th class="px-4 py-2 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
              Value
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-zinc-100 dark:divide-zinc-800">
          <%= for {term, tag} <- @forms do %>
            <tr>
              <td class="py-2 pr-4 text-sm font-medium text-zinc-500 dark:text-zinc-400">
                {humanize_form_tag(tag)}
              </td>
              <td class="px-4 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                {display_term(term, @script_mode)}
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
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

  defp has_comparison?(forms_map) do
    Enum.any?(forms_map, fn {tag, _} -> String.starts_with?(tag, "comp_") end)
  end
end
