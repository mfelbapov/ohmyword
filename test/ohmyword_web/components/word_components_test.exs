defmodule OhmywordWeb.WordComponentsTest do
  use OhmywordWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component
  import OhmywordWeb.WordComponents

  describe "single_text_answer_box/1" do
    test "renders correct number of char inputs" do
      assigns = %{id: "test-1", name: "answer[0]", length: 5}

      html =
        rendered_to_string(~H"""
        <.single_text_answer_box id={@id} name={@name} length={@length} />
        """)

      assert length(Regex.scan(~r/maxlength="1"/, html)) == 5
    end

    test "renders with answer filled in" do
      assigns = %{id: "test-2", name: "answer[0]", length: 3, answer: "abc"}

      html =
        rendered_to_string(~H"""
        <.single_text_answer_box id={@id} name={@name} length={@length} answer={@answer} />
        """)

      assert html =~ ~s(value="a")
      assert html =~ ~s(value="b")
      assert html =~ ~s(value="c")
    end

    test "renders with nil answer" do
      assigns = %{id: "test-3", name: "answer[0]", length: 3}

      html =
        rendered_to_string(~H"""
        <.single_text_answer_box id={@id} name={@name} length={@length} />
        """)

      # All char inputs should have empty value
      assert length(Regex.scan(~r/value=""/, html)) >= 3
    end

    test "renders hidden input with answer value" do
      assigns = %{id: "test-4", name: "answer[2]", length: 3, answer: "dog"}

      html =
        rendered_to_string(~H"""
        <.single_text_answer_box id={@id} name={@name} length={@length} answer={@answer} />
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="answer[2]")
      assert html =~ ~s(value="dog")
    end

    test "renders with autofocus data attr" do
      assigns = %{id: "test-5", name: "answer[0]", length: 3, autofocus: true}

      html =
        rendered_to_string(~H"""
        <.single_text_answer_box id={@id} name={@name} length={@length} autofocus={@autofocus} />
        """)

      assert html =~ ~s(data-autofocus="true")
    end

    test "renders without autofocus by default" do
      assigns = %{id: "test-6", name: "answer[0]", length: 3}

      html =
        rendered_to_string(~H"""
        <.single_text_answer_box id={@id} name={@name} length={@length} />
        """)

      assert html =~ ~s(data-autofocus="false")
    end

    test "renders readonly when submitted" do
      assigns = %{id: "test-7", name: "answer[0]", length: 3, submitted: true}

      html =
        rendered_to_string(~H"""
        <.single_text_answer_box id={@id} name={@name} length={@length} submitted={@submitted} />
        """)

      assert html =~ "readonly"
    end

    test "renders correct result border class" do
      assigns = %{
        id: "test-8",
        name: "answer[0]",
        length: 3,
        submitted: true,
        result: {:correct, "cat"}
      }

      html =
        rendered_to_string(~H"""
        <.single_text_answer_box
          id={@id}
          name={@name}
          length={@length}
          submitted={@submitted}
          result={@result}
        />
        """)

      assert html =~ "border-green-500"
    end

    test "renders incorrect result border class" do
      assigns = %{
        id: "test-9",
        name: "answer[0]",
        length: 3,
        submitted: true,
        result: {:incorrect, ["cat"]}
      }

      html =
        rendered_to_string(~H"""
        <.single_text_answer_box
          id={@id}
          name={@name}
          length={@length}
          submitted={@submitted}
          result={@result}
        />
        """)

      assert html =~ "border-red-500"
    end

    test "renders default border class when not submitted" do
      assigns = %{id: "test-10", name: "answer[0]", length: 3}

      html =
        rendered_to_string(~H"""
        <.single_text_answer_box id={@id} name={@name} length={@length} />
        """)

      assert html =~ "border-zinc-300"
      refute html =~ "border-green-500"
      refute html =~ "border-red-500"
    end

    test "renders form_tag label" do
      assigns = %{id: "test-11", name: "answer[0]", length: 3, form_tag: "nom_sg"}

      html =
        rendered_to_string(~H"""
        <.single_text_answer_box id={@id} name={@name} length={@length} form_tag={@form_tag} />
        """)

      assert html =~ "Nominative Singular"
    end

    test "omits form_tag label when nil" do
      assigns = %{id: "test-12", name: "answer[0]", length: 3}

      html =
        rendered_to_string(~H"""
        <.single_text_answer_box id={@id} name={@name} length={@length} />
        """)

      refute html =~ "mt-1 text-xs font-medium"
    end

    test "renders CharInputGroup hook" do
      assigns = %{id: "test-13", name: "answer[0]", length: 3}

      html =
        rendered_to_string(~H"""
        <.single_text_answer_box id={@id} name={@name} length={@length} />
        """)

      assert html =~ ~s(phx-hook="CharInputGroup")
    end
  end
end
