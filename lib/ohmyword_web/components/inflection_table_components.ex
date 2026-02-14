defmodule OhmywordWeb.InflectionTableComponents do
  @moduledoc """
  Function components for rendering POS-specific inflection tables.

  Extracted from WordDetailLive — pure rendering with no state management.
  """

  use Phoenix.Component

  import OhmywordWeb.WordComponents,
    only: [display_term: 2, humanize_form_tag: 1, case_color_classes: 1]

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

  attr :forms_map, :map, required: true
  attr :script_mode, :atom, required: true

  def noun_table(assigns) do
    assigns = assign(assigns, cases: @noun_cases)

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

  attr :forms_map, :map, required: true
  attr :script_mode, :atom, required: true

  def verb_table(assigns) do
    assigns =
      assigns
      |> assign(persons: @verb_persons)
      |> assign(person_labels: @person_labels)

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

  attr :forms_map, :map, required: true
  attr :script_mode, :atom, required: true

  def adjective_table(assigns) do
    assigns =
      assigns
      |> assign(cases: @noun_cases)
      |> assign(genders: @adj_genders)

    ~H"""
    <div class="space-y-8">
      <%= for {paradigm, paradigm_label} <- [{"indef", "Indefinite"}, {"def", "Definite"}] do %>
        <div>
          <h3 class="text-sm font-semibold text-zinc-700 dark:text-zinc-300 uppercase tracking-wide">
            {paradigm_label}
          </h3>
          <.case_gender_table
            forms_map={@forms_map}
            script_mode={@script_mode}
            prefix={paradigm}
            cases={@cases}
            genders={@genders}
          />
        </div>
      <% end %>

      <%!-- Comparative & Superlative --%>
      <%= if has_comparison?(@forms_map) do %>
        <%= for {paradigm, paradigm_label} <- [{"comp", "Comparative"}, {"super", "Superlative"}] do %>
          <div>
            <h3 class="text-sm font-semibold text-zinc-700 dark:text-zinc-300 uppercase tracking-wide">
              {paradigm_label}
            </h3>
            <.case_gender_table
              forms_map={@forms_map}
              script_mode={@script_mode}
              prefix={paradigm}
              cases={@cases}
              genders={@genders}
            />
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  attr :forms, :list, required: true
  attr :script_mode, :atom, required: true

  def generic_forms_table(assigns) do
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

  # Shared sub-component for case × gender tables (used by adjective indef/def/comp/super)
  attr :forms_map, :map, required: true
  attr :script_mode, :atom, required: true
  attr :prefix, :string, required: true
  attr :cases, :list, required: true
  attr :genders, :list, required: true

  defp case_gender_table(assigns) do
    ~H"""
    <div class="mt-2 overflow-x-auto">
      <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-700">
        <thead>
          <tr>
            <th class="py-2 pr-4 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
              Case
            </th>
            <%= for {_g, gl} <- Enum.zip(@genders, ["M", "F", "N"]) do %>
              <th class="px-3 py-2 text-left text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                {gl} sg
              </th>
            <% end %>
            <%= for {_g, gl} <- Enum.zip(@genders, ["M", "F", "N"]) do %>
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
                  {display_term(@forms_map["#{@prefix}_#{c}_sg_#{g}"] || "-", @script_mode)}
                </td>
              <% end %>
              <%= for g <- @genders do %>
                <td class="px-3 py-2 text-sm text-zinc-700 dark:text-zinc-300 font-mono">
                  {display_term(@forms_map["#{@prefix}_#{c}_pl_#{g}"] || "-", @script_mode)}
                </td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp has_comparison?(forms_map) do
    Enum.any?(forms_map, fn {tag, _} -> String.starts_with?(tag, "comp_") end)
  end
end
