defmodule BoilerWeb.CoreComponentsTest do
  use BoilerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component
  import BoilerWeb.CoreComponents

  describe "flash/1" do
    test "renders info flash with correct classes and icon" do
      assigns = %{kind: :info, flash: %{}, id: "test-flash"}

      html =
        rendered_to_string(~H"""
        <.flash kind={@kind} id={@id}>Test info message</.flash>
        """)

      assert html =~ "alert-info"
      assert html =~ "hero-information-circle"
      assert html =~ "Test info message"
    end

    test "renders success flash with correct classes and icon" do
      assigns = %{kind: :success, flash: %{}, id: "test-flash"}

      html =
        rendered_to_string(~H"""
        <.flash kind={@kind} id={@id}>Test success message</.flash>
        """)

      assert html =~ "alert-success"
      assert html =~ "hero-check-circle"
      assert html =~ "Test success message"
    end

    test "renders warning flash with correct classes and icon" do
      assigns = %{kind: :warning, flash: %{}, id: "test-flash"}

      html =
        rendered_to_string(~H"""
        <.flash kind={@kind} id={@id}>Test warning message</.flash>
        """)

      assert html =~ "alert-warning"
      assert html =~ "hero-exclamation-triangle"
      assert html =~ "Test warning message"
    end

    test "renders error flash with correct classes and icon" do
      assigns = %{kind: :error, flash: %{}, id: "test-flash"}

      html =
        rendered_to_string(~H"""
        <.flash kind={@kind} id={@id}>Test error message</.flash>
        """)

      assert html =~ "alert-error"
      assert html =~ "hero-exclamation-circle"
      assert html =~ "Test error message"
    end

    test "renders flash with title" do
      assigns = %{kind: :success, flash: %{}, id: "test-flash", title: "Success!"}

      html =
        rendered_to_string(~H"""
        <.flash kind={@kind} id={@id} title={@title}>Operation completed</.flash>
        """)

      assert html =~ "Success!"
      assert html =~ "Operation completed"
    end
  end

  describe "input/1" do
    test "renders basic input without variant" do
      form = %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Map,
        id: "test_form",
        name: "test",
        data: %{},
        params: %{},
        errors: []
      }

      field = %Phoenix.HTML.FormField{
        id: "test_form_name",
        name: "test[name]",
        errors: [],
        field: :name,
        form: form,
        value: nil
      }

      assigns = %{field: field, type: "text", label: "Name"}

      html =
        rendered_to_string(~H"""
        <.input field={@field} type={@type} label={@label} />
        """)

      assert html =~ "w-full input"
      assert html =~ "Name"
      refute html =~ "input-primary"
    end

    test "renders input with primary variant" do
      form = %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Map,
        id: "test_form",
        name: "test",
        data: %{},
        params: %{},
        errors: []
      }

      field = %Phoenix.HTML.FormField{
        id: "test_form_email",
        name: "test[email]",
        errors: [],
        field: :email,
        form: form,
        value: nil
      }

      assigns = %{field: field, type: "email", label: "Email", variant: "primary"}

      html =
        rendered_to_string(~H"""
        <.input field={@field} type={@type} label={@label} variant={@variant} />
        """)

      assert html =~ "input-primary"
      assert html =~ "Email"
    end

    test "renders input with bordered variant" do
      form = %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Map,
        id: "test_form",
        name: "test",
        data: %{},
        params: %{},
        errors: []
      }

      field = %Phoenix.HTML.FormField{
        id: "test_form_username",
        name: "test[username]",
        errors: [],
        field: :username,
        form: form,
        value: nil
      }

      assigns = %{field: field, type: "text", label: "Username", variant: "bordered"}

      html =
        rendered_to_string(~H"""
        <.input field={@field} type={@type} label={@label} variant={@variant} />
        """)

      assert html =~ "input-bordered"
    end

    test "renders input with ghost variant" do
      form = %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Map,
        id: "test_form",
        name: "test",
        data: %{},
        params: %{},
        errors: []
      }

      field = %Phoenix.HTML.FormField{
        id: "test_form_search",
        name: "test[search]",
        errors: [],
        field: :search,
        form: form,
        value: nil
      }

      assigns = %{field: field, type: "search", label: "Search", variant: "ghost"}

      html =
        rendered_to_string(~H"""
        <.input field={@field} type={@type} label={@label} variant={@variant} />
        """)

      assert html =~ "input-ghost"
    end

    test "renders input with xs size" do
      form = %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Map,
        id: "test_form",
        name: "test",
        data: %{},
        params: %{},
        errors: []
      }

      field = %Phoenix.HTML.FormField{
        id: "test_form_compact",
        name: "test[compact]",
        errors: [],
        field: :compact,
        form: form,
        value: nil
      }

      assigns = %{field: field, type: "text", label: "Compact", size: "xs"}

      html =
        rendered_to_string(~H"""
        <.input field={@field} type={@type} label={@label} size={@size} />
        """)

      assert html =~ "input-xs"
    end

    test "renders input with lg size" do
      form = %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Map,
        id: "test_form",
        name: "test",
        data: %{},
        params: %{},
        errors: []
      }

      field = %Phoenix.HTML.FormField{
        id: "test_form_large",
        name: "test[large]",
        errors: [],
        field: :large,
        form: form,
        value: nil
      }

      assigns = %{field: field, type: "text", label: "Large", size: "lg"}

      html =
        rendered_to_string(~H"""
        <.input field={@field} type={@type} label={@label} size={@size} />
        """)

      assert html =~ "input-lg"
    end

    test "renders input with variant and size combined" do
      form = %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Map,
        id: "test_form",
        name: "test",
        data: %{},
        params: %{},
        errors: []
      }

      field = %Phoenix.HTML.FormField{
        id: "test_form_combined",
        name: "test[combined]",
        errors: [],
        field: :combined,
        form: form,
        value: nil
      }

      assigns = %{field: field, type: "text", label: "Combined", variant: "primary", size: "lg"}

      html =
        rendered_to_string(~H"""
        <.input field={@field} type={@type} label={@label} variant={@variant} size={@size} />
        """)

      assert html =~ "input-primary"
      assert html =~ "input-lg"
    end

    test "renders select with variant" do
      form = %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Map,
        id: "test_form",
        name: "test",
        data: %{},
        params: %{},
        errors: []
      }

      field = %Phoenix.HTML.FormField{
        id: "test_form_role",
        name: "test[role]",
        errors: [],
        field: :role,
        form: form,
        value: nil
      }

      assigns = %{
        field: field,
        type: "select",
        label: "Role",
        variant: "primary",
        options: ["Admin", "User"]
      }

      html =
        rendered_to_string(~H"""
        <.input
          field={@field}
          type={@type}
          label={@label}
          variant={@variant}
          options={@options}
        />
        """)

      assert html =~ "select-primary"
      assert html =~ "Admin"
      assert html =~ "User"
    end

    test "renders textarea with variant and size" do
      form = %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Map,
        id: "test_form",
        name: "test",
        data: %{},
        params: %{},
        errors: []
      }

      field = %Phoenix.HTML.FormField{
        id: "test_form_bio",
        name: "test[bio]",
        errors: [],
        field: :bio,
        form: form,
        value: nil
      }

      assigns = %{field: field, type: "textarea", label: "Bio", variant: "ghost", size: "sm"}

      html =
        rendered_to_string(~H"""
        <.input field={@field} type={@type} label={@label} variant={@variant} size={@size} />
        """)

      assert html =~ "textarea-ghost"
      assert html =~ "textarea-sm"
    end

    test "renders input with error state overriding variant" do
      # Pass errors directly instead of through field to ensure they're detected
      assigns = %{
        type: "text",
        name: "test[invalid]",
        id: "test_form_invalid",
        label: "Invalid Field",
        variant: "primary",
        value: nil,
        errors: ["can't be blank"]
      }

      html =
        rendered_to_string(~H"""
        <.input
          type={@type}
          name={@name}
          id={@id}
          label={@label}
          variant={@variant}
          value={@value}
          errors={@errors}
        />
        """)

      assert html =~ "input-error"
      refute html =~ "input-primary"
    end

    test "renders checkbox with variant" do
      form = %Phoenix.HTML.Form{
        source: %{},
        impl: Phoenix.HTML.FormData.Map,
        id: "test_form",
        name: "test",
        data: %{},
        params: %{},
        errors: []
      }

      field = %Phoenix.HTML.FormField{
        id: "test_form_agree",
        name: "test[agree]",
        errors: [],
        field: :agree,
        form: form,
        value: false
      }

      assigns = %{field: field, type: "checkbox", label: "I agree", variant: "primary"}

      html =
        rendered_to_string(~H"""
        <.input field={@field} type={@type} label={@label} variant={@variant} />
        """)

      assert html =~ "checkbox-primary"
      assert html =~ "I agree"
    end
  end

  describe "table/1" do
    test "renders table with default settings" do
      assigns = %{
        id: "test_table",
        rows: [%{name: "Alice", email: "alice@example.com"}]
      }

      html =
        rendered_to_string(~H"""
        <.table id={@id} rows={@rows}>
          <:col :let={row} label="Name">{row.name}</:col>
          <:col :let={row} label="Email">{row.email}</:col>
        </.table>
        """)

      assert html =~ "table"
      assert html =~ "table-zebra"
      assert html =~ "Alice"
      assert html =~ "alice@example.com"
      refute html =~ "table-xs"
      refute html =~ "table-sm"
      refute html =~ "table-lg"
    end

    test "renders table with xs size" do
      assigns = %{
        id: "test_table",
        rows: [%{name: "Bob"}],
        size: "xs"
      }

      html =
        rendered_to_string(~H"""
        <.table id={@id} rows={@rows} size={@size}>
          <:col :let={row} label="Name">{row.name}</:col>
        </.table>
        """)

      assert html =~ "table-xs"
    end

    test "renders table with sm size" do
      assigns = %{
        id: "test_table",
        rows: [%{name: "Charlie"}],
        size: "sm"
      }

      html =
        rendered_to_string(~H"""
        <.table id={@id} rows={@rows} size={@size}>
          <:col :let={row} label="Name">{row.name}</:col>
        </.table>
        """)

      assert html =~ "table-sm"
    end

    test "renders table with lg size" do
      assigns = %{
        id: "test_table",
        rows: [%{name: "David"}],
        size: "lg"
      }

      html =
        rendered_to_string(~H"""
        <.table id={@id} rows={@rows} size={@size}>
          <:col :let={row} label="Name">{row.name}</:col>
        </.table>
        """)

      assert html =~ "table-lg"
    end

    test "renders table without zebra striping" do
      assigns = %{
        id: "test_table",
        rows: [%{name: "Eve"}],
        zebra: false
      }

      html =
        rendered_to_string(~H"""
        <.table id={@id} rows={@rows} zebra={@zebra}>
          <:col :let={row} label="Name">{row.name}</:col>
        </.table>
        """)

      refute html =~ "table-zebra"
    end

    test "renders table with pinned rows" do
      assigns = %{
        id: "test_table",
        rows: [%{name: "Frank"}],
        pin_rows: true
      }

      html =
        rendered_to_string(~H"""
        <.table id={@id} rows={@rows} pin_rows={@pin_rows}>
          <:col :let={row} label="Name">{row.name}</:col>
        </.table>
        """)

      assert html =~ "table-pin-rows"
    end

    test "renders table with pinned columns" do
      assigns = %{
        id: "test_table",
        rows: [%{name: "Grace"}],
        pin_cols: true
      }

      html =
        rendered_to_string(~H"""
        <.table id={@id} rows={@rows} pin_cols={@pin_cols}>
          <:col :let={row} label="Name">{row.name}</:col>
        </.table>
        """)

      assert html =~ "table-pin-cols"
    end

    test "renders table with all modifiers combined" do
      assigns = %{
        id: "test_table",
        rows: [%{id: 1, name: "Helen", status: "active"}],
        size: "sm",
        zebra: true,
        pin_rows: true,
        pin_cols: true
      }

      html =
        rendered_to_string(~H"""
        <.table
          id={@id}
          rows={@rows}
          size={@size}
          zebra={@zebra}
          pin_rows={@pin_rows}
          pin_cols={@pin_cols}
        >
          <:col :let={row} label="ID">{row.id}</:col>
          <:col :let={row} label="Name">{row.name}</:col>
          <:col :let={row} label="Status">{row.status}</:col>
        </.table>
        """)

      assert html =~ "table-sm"
      assert html =~ "table-zebra"
      assert html =~ "table-pin-rows"
      assert html =~ "table-pin-cols"
      assert html =~ "Helen"
      assert html =~ "active"
    end
  end

  describe "button/1" do
    test "renders button with all semantic variants" do
      variants = ~w(primary secondary accent ghost link info success warning error neutral)

      for variant <- variants do
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <.button variant={@variant}>Test</.button>
          """)

        assert html =~ "btn-#{variant}", "Should render btn-#{variant} class"
      end
    end

    test "renders button with all sizes" do
      sizes = ~w(xs sm md lg)

      for size <- sizes do
        assigns = %{size: size}

        html =
          rendered_to_string(~H"""
          <.button size={@size}>Test</.button>
          """)

        if size == "md" do
          # md is default, shouldn't have explicit class
          refute html =~ "btn-md"
        else
          assert html =~ "btn-#{size}", "Should render btn-#{size} class"
        end
      end
    end

    test "renders button with modifiers" do
      assigns = %{}

      # Test outline
      html =
        rendered_to_string(~H"""
        <.button outline>Test</.button>
        """)

      assert html =~ "btn-outline"

      # Test wide
      html =
        rendered_to_string(~H"""
        <.button wide>Test</.button>
        """)

      assert html =~ "btn-wide"

      # Test block
      html =
        rendered_to_string(~H"""
        <.button block>Test</.button>
        """)

      assert html =~ "btn-block"

      # Test circle
      html =
        rendered_to_string(~H"""
        <.button circle>Test</.button>
        """)

      assert html =~ "btn-circle"

      # Test square
      html =
        rendered_to_string(~H"""
        <.button square>Test</.button>
        """)

      assert html =~ "btn-square"
    end
  end
end
