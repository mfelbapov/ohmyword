defmodule OhmywordWeb.WordComponents do
  @moduledoc """
  Shared components for displaying word badges and formatting form tags.

  Used by DictionaryLive, FlashcardLive, and WordDetailLive.
  """

  use Phoenix.Component

  alias Ohmyword.Utils.Transliteration

  attr :part_of_speech, :atom, required: true

  def pos_badge(assigns) do
    ~H"""
    <span class="inline-flex items-center rounded-full bg-zinc-100 px-2.5 py-0.5 text-xs font-medium text-zinc-800 dark:bg-zinc-800 dark:text-zinc-200">
      {Phoenix.Naming.humanize(@part_of_speech)}
    </span>
    """
  end

  attr :gender, :atom, required: true

  def gender_badge(assigns) do
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

  def aspect_badge(assigns) do
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

  def animate_badge(assigns) do
    ~H"""
    <span class="inline-flex items-center rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-800 dark:bg-amber-900 dark:text-amber-200">
      Anim
    </span>
    """
  end

  def display_term(text, :latin), do: text
  def display_term(text, :cyrillic), do: Transliteration.to_cyrillic(text)

  def humanize_form_tag(form_tag) do
    form_tag
    |> String.split("_")
    |> Enum.map(&expand_abbreviation/1)
    |> Enum.join(" ")
  end

  def case_color_classes(form_tag) do
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

  # -- single_text_answer_box component --

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :answer, :string, default: nil
  attr :length, :integer, required: true
  attr :submitted, :boolean, default: false
  attr :autofocus, :boolean, default: false
  attr :result, :any, default: nil
  attr :form_tag, :string, default: nil
  attr :hint, :string, default: nil

  def single_text_answer_box(assigns) do
    ~H"""
    <div
      class="inline-flex flex-col items-center mx-2 min-w-0"
      id={@id}
      phx-hook="CharInputGroup"
      data-autofocus={to_string(@autofocus)}
      data-readonly={to_string(@submitted)}
    >
      <div class="inline-flex items-center gap-0.5">
        <%= for ci <- 0..(@length - 1) do %>
          <input
            type="text"
            maxlength="1"
            data-char-idx={ci}
            value={char_at(@answer, ci)}
            autocomplete="off"
            readonly={@submitted}
            placeholder="_"
            class={[
              "w-9 h-10 rounded border text-2xl text-center focus:outline-none focus:ring-2 focus:ring-zinc-400 dark:bg-zinc-800 dark:text-zinc-100 placeholder:text-sm placeholder:leading-[2.5rem] focus:placeholder-transparent",
              char_border_class(@result, @submitted)
            ]}
          />
        <% end %>
      </div>
      <input type="hidden" name={@name} value={@answer || ""} />
      <%= if @form_tag do %>
        <span class={"mt-1 text-xs font-medium #{case_color_classes(@form_tag)}"}>
          {humanize_form_tag(@form_tag)}
        </span>
      <% end %>
      <%= if @hint do %>
        <span class="mt-1 text-xs font-medium text-zinc-500 dark:text-zinc-400">
          {@hint}
        </span>
      <% end %>
    </div>
    """
  end

  defp char_at(nil, _idx), do: ""

  defp char_at(answer, idx) do
    answer |> String.graphemes() |> Enum.at(idx, "")
  end

  defp char_border_class(result, submitted) do
    if submitted do
      case result do
        {:correct, _} -> "border-green-500 bg-green-50 dark:bg-green-900/20"
        {:incorrect, _} -> "border-red-500 bg-red-50 dark:bg-red-900/20"
        _ -> "border-zinc-300 dark:border-zinc-600"
      end
    else
      "border-zinc-300 focus:border-zinc-500 dark:border-zinc-600 dark:focus:border-zinc-400"
    end
  end
end
