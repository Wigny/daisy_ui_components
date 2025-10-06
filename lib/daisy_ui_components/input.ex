defmodule DaisyUIComponents.Input do
  @moduledoc """
  Generic Input component
  """

  use DaisyUIComponents, :component

  import DaisyUIComponents.Checkbox
  import DaisyUIComponents.Radio
  import DaisyUIComponents.Range
  import DaisyUIComponents.Select
  import DaisyUIComponents.Textarea
  import DaisyUIComponents.TextInput
  import DaisyUIComponents.Toggle

  @doc """
  Renders a generic input based on type.

  ## Examples

      <.input type="email" />
      <.input name="my-input" type="checkbox" value="false" />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select autocomplete tel text textarea time url week toggle)

  attr :color, :string, values: [nil] ++ colors(), default: nil

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :class, :any, default: nil
  attr :ghost, :boolean, default: nil
  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :on_query, :any,
    doc: "the JS event to trigger when a value is searched in autocomplete inputs"

  attr :rest, :global,
    include: ~w(autocomplete cols disabled form list max maxlength min minlength
                pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    # If form field is sent, this components delegates it's implementation to the form_input component
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> assign_new(:color, fn -> assigns.errors != [] && "error" end)
    |> DaisyUIComponents.Form.form_input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assigns
      |> assign_new(:value, fn -> nil end)
      |> assign_new(:name, fn -> nil end)
      |> assign_new(:checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <.checkbox
      id={@id}
      name={@name}
      class={@class}
      color={@color}
      checked={@checked}
      value={@value}
      {@rest}
    />
    """
  end

  def input(%{type: "toggle"} = assigns) do
    assigns =
      assigns
      |> assign_new(:value, fn -> nil end)
      |> assign_new(:name, fn -> nil end)
      |> assign_new(:checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <.toggle
      id={@id}
      name={@name}
      class={@class}
      color={@color}
      checked={@checked}
      value={@value}
      {@rest}
    />
    """
  end

  def input(%{type: "radio"} = assigns) do
    assigns =
      assigns
      |> assign_new(:value, fn -> nil end)
      |> assign_new(:name, fn -> nil end)
      |> assign_new(:checked, fn ->
        Phoenix.HTML.Form.normalize_value("radio", assigns[:value])
      end)

    ~H"""
    <.radio
      id={@id}
      name={@name}
      class={@class}
      color={@color}
      checked={@checked}
      value={@value}
      {@rest}
    />
    """
  end

  def input(%{type: "select"} = assigns) do
    assigns =
      assigns
      |> assign_new(:name, fn -> nil end)
      |> assign_new(:value, fn -> nil end)

    ~H"""
    <.select
      id={@id}
      name={@name}
      class={@class}
      color={@color}
      ghost={@ghost}
      multiple={@multiple}
      {@rest}
    >
      <option :if={@prompt} value="">{@prompt}</option>
      {Phoenix.HTML.Form.options_for_select(@options, @value)}
    </.select>
    """
  end

  def input(%{type: "autocomplete"} = assigns) do
    selected_label =
      Enum.find_value(assigns.options, fn {label, value} ->
        if to_string(value) == to_string(assigns.value), do: label
      end)

    assigns =
      assigns
      |> assign(:selected, selected_label)
      |> update(:on_query, fn
        %JS{} = js -> js
        event when is_binary(event) -> JS.push(event)
      end)

    ~H"""
    <div class="dropdown">
      <.input
        tabindex="0"
        id={@id <> "_label"}
        type="text"
        class={@class}
        color={@color}
        name="label"
        phx-change={
          @on_query
          |> JS.set_attribute({"value", ""}, to: "##{@id}")
          |> JS.dispatch("change", to: "##{@id}")
        }
        phx-debounce={300}
        autocomplete="off"
        value={@selected}
        placeholder={@rest[:placeholder]}
      />
      <ul
        tabindex="1"
        class="menu dropdown-content bg-base-100 rounded-box z-1 max-h-80 p-2 w-full shadow flex-nowrap overflow-auto"
      >
        <li :for={{label, value} <- @options}>
          <button
            type="button"
            class={to_string(value) == to_string(@value) && "menu-active"}
            onclick="document.activeElement.blur()"
            phx-click={
              JS.set_attribute({"value", value}, to: "##{@id}")
              |> JS.dispatch("change", to: "##{@id}")
            }
          >
            {label}
          </button>
        </li>
      </ul>
    </div>
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "textarea"} = assigns) do
    assigns =
      assigns
      |> assign_new(:name, fn -> nil end)
      |> assign_new(:value, fn -> nil end)

    ~H"""
    <.textarea id={@id} name={@name} class={@class} color={@color} ghost={@ghost} {@rest}>
      {Phoenix.HTML.Form.normalize_value(@type, @value)}
    </.textarea>
    """
  end

  def input(%{type: "range"} = assigns) do
    assigns =
      assigns
      |> assign_new(:name, fn -> nil end)
      |> assign_new(:value, fn -> nil end)

    ~H"""
    <.range
      id={@id}
      name={@name}
      class={@class}
      color={@color}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      {@rest}
    />
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    assigns =
      assigns
      |> assign_new(:name, fn -> nil end)
      |> assign_new(:value, fn -> nil end)

    ~H"""
    <.text_input
      id={@id}
      name={@name}
      class={@class}
      color={@color}
      ghost={@ghost}
      type={@type}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      {@rest}
    />
    """
  end
end
