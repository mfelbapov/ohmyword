defmodule OhmywordWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: OhmywordWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil

  attr :kind, :atom,
    values: [:info, :success, :warning, :error],
    doc: "used for styling and flash lookup"

  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :success && "alert-success",
        @kind == :warning && "alert-warning",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :success} name="hero-check-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :warning} name="hero-exclamation-triangle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with full DaisyUI variant support and navigation.

  ## Examples

      <.button>Send!</.button>
      <.button variant="primary">Send!</.button>
      <.button variant="ghost" size="sm">Small Ghost</.button>
      <.button variant="primary" outline block>Full Width Outline</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :string, default: nil

  attr :variant, :string,
    default: nil,
    doc:
      "button variant (primary, secondary, accent, ghost, link, info, success, warning, error, neutral)"

  attr :size, :string, default: "md", values: ~w(xs sm md lg)
  attr :outline, :boolean, default: false
  attr :wide, :boolean, default: false
  attr :block, :boolean, default: false
  attr :circle, :boolean, default: false
  attr :square, :boolean, default: false
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    # Build button classes from component attributes
    button_classes =
      build_button_classes(
        assigns.variant,
        assigns.size,
        assigns.outline,
        assigns.wide,
        assigns.block,
        assigns.circle,
        assigns.square,
        assigns.class
      )

    assigns = assign(assigns, :button_classes, button_classes)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@button_classes} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@button_classes} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  # Build DaisyUI button classes from component attributes
  defp build_button_classes(variant, size, outline, wide, block, circle, square, custom_class) do
    base = ["btn"]

    # Add variant class (e.g., btn-primary, btn-ghost)
    variant_class = if variant, do: ["btn-#{variant}"], else: []

    # Add size class (skip md as it's default)
    size_class = if size != "md", do: ["btn-#{size}"], else: []

    # Add modifier classes
    modifier_classes =
      [
        outline && "btn-outline",
        wide && "btn-wide",
        block && "btn-block",
        circle && "btn-circle",
        square && "btn-square"
      ]
      |> Enum.filter(& &1)

    # Combine all classes
    [base, variant_class, size_class, modifier_classes, custom_class]
    |> List.flatten()
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :variant, :string,
    default: nil,
    doc:
      "the DaisyUI variant style (bordered, ghost, primary, secondary, accent, info, success, warning, error)"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg),
    doc: "the DaisyUI size"

  attr :class, :string, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :string, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={
              @class ||
                build_input_classes("checkbox", @variant, @size, @errors != [], nil, @error_class)
            }
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={
            @class ||
              build_input_classes("w-full select", @variant, @size, @errors != [], nil, @error_class)
          }
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={
            @class ||
              build_input_classes(
                "w-full textarea",
                @variant,
                @size,
                @errors != [],
                nil,
                @error_class
              )
          }
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={
            @class ||
              build_input_classes("w-full input", @variant, @size, @errors != [], nil, @error_class)
          }
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used to build input classes based on variant and size
  defp build_input_classes(base_class, variant, size, has_errors, custom_class, error_class) do
    # Extract component type (last word in base_class like "input", "select", etc.)
    component_type =
      base_class
      |> String.split(" ")
      |> List.last()

    base = [base_class]

    variant_class =
      cond do
        has_errors && error_class -> [error_class]
        has_errors -> ["#{component_type}-error"]
        variant -> ["#{component_type}-#{variant}"]
        true -> []
      end

    size_class = if size != "md", do: ["#{component_type}-#{size}"], else: []

    [base, variant_class, size_class, custom_class]
    |> List.flatten()
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  attr :size, :string, default: "md", values: ~w(xs sm md lg), doc: "the DaisyUI table size"
  attr :zebra, :boolean, default: true, doc: "enable zebra striping"
  attr :pin_rows, :boolean, default: false, doc: "pin header and footer rows"
  attr :pin_cols, :boolean, default: false, doc: "pin first column"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class={[
      "table",
      @size != "md" && "table-#{@size}",
      @zebra && "table-zebra",
      @pin_rows && "table-pin-rows",
      @pin_cols && "table-pin-cols"
    ]}>
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Renders a Latin/Cyrillic script toggle button.

  ## Examples

      <.script_toggle script_mode={@script_mode} />
  """
  attr :script_mode, :atom, required: true, values: [:latin, :cyrillic]

  def script_toggle(assigns) do
    ~H"""
    <button
      phx-click="toggle_script"
      class="inline-flex items-center rounded-md bg-zinc-100 px-3 py-2 text-sm font-medium text-zinc-700 hover:bg-zinc-200 dark:bg-zinc-800 dark:text-zinc-300 dark:hover:bg-zinc-700"
    >
      <span class="mr-2">Ćć</span>
      <span class="text-zinc-400 dark:text-zinc-500">↔</span>
      <span class="ml-2">Ћћ</span>
      <span class="ml-2 rounded bg-zinc-200 px-1.5 py-0.5 text-xs dark:bg-zinc-700">
        {if @script_mode == :latin, do: "LAT", else: "ЋИР"}
      </span>
    </button>
    """
  end

  @doc """
  Renders a toggle button for flashcard direction (Serbian to English or English to Serbian).

  ## Examples

      <.direction_toggle direction_mode={@direction_mode} />
  """
  attr :direction_mode, :atom, required: true, values: [:serbian_to_english, :english_to_serbian]

  def direction_toggle(assigns) do
    ~H"""
    <button
      phx-click="toggle_direction"
      class="inline-flex items-center rounded-md bg-zinc-100 px-3 py-2 text-sm font-medium text-zinc-700 hover:bg-zinc-200 dark:bg-zinc-800 dark:text-zinc-300 dark:hover:bg-zinc-700"
    >
      <span class="mr-2">SR</span>
      <span class="text-zinc-400 dark:text-zinc-500">↔</span>
      <span class="ml-2">EN</span>
      <span class="ml-2 rounded bg-zinc-200 px-1.5 py-0.5 text-xs dark:bg-zinc-700">
        {if @direction_mode == :serbian_to_english, do: "SR→EN", else: "EN→SR"}
      </span>
    </button>
    """
  end

  @doc """
  Renders a dropdown filter for part of speech.

  ## Examples

      <.pos_filter pos_filter={@pos_filter} available_pos={@available_pos} />
  """
  attr :pos_filter, :atom, required: true
  attr :available_pos, :list, required: true

  def pos_filter(assigns) do
    ~H"""
    <form phx-change="filter_pos">
      <select
        name="pos"
        class="rounded-md border-0 bg-zinc-100 px-3 py-2 text-sm font-medium text-zinc-700 hover:bg-zinc-200 dark:bg-zinc-800 dark:text-zinc-300 dark:hover:bg-zinc-700"
      >
        <option value="all" selected={@pos_filter == :all}>All types</option>
        <%= for pos <- @available_pos do %>
          <option value={pos} selected={@pos_filter == pos}>
            {Phoenix.Naming.humanize(pos)}
          </option>
        <% end %>
      </select>
    </form>
    """
  end

  @doc """
  Renders a category filter dropdown for vocabulary filtering.
  """
  attr :category_filter, :string, required: true
  attr :available_categories, :list, required: true

  def category_filter(assigns) do
    ~H"""
    <form phx-change="filter_category">
      <select
        name="category"
        class="rounded-md border-0 bg-zinc-100 px-3 py-2 text-sm font-medium text-zinc-700 hover:bg-zinc-200 dark:bg-zinc-800 dark:text-zinc-300 dark:hover:bg-zinc-700"
      >
        <option value="all" selected={@category_filter == "all"}>All categories</option>
        <%= if @available_categories == [] do %>
          <option value="none" disabled>No categories</option>
        <% else %>
          <%= for cat <- @available_categories do %>
            <option value={cat} selected={@category_filter == cat}>
              {cat}
            </option>
          <% end %>
        <% end %>
      </select>
    </form>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(OhmywordWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(OhmywordWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
