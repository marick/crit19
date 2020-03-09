defmodule CritWeb.Fomantic.ListProducing do
  use Phoenix.HTML
  import CritWeb.Fomantic.Helpers

  @moduledoc """
  This module creates HTML that delivers list values to a controller action.
  For example, producing a list of ideas like %{"ids" => ["0", "5", "10"]
  """

  @doc """
  Like `multiple_select`, but more convenient for user.
  The `tuples` argument is a list of pairs like {"name", 5}.
  The first element is the text displayed next to the checkbox.
  The second is the value to send to the controller action.
  
  The `checkbox_field` is something like `:chosen_ids`. The params
  delivered to the controller action will have that key bound to
  an array of values (like an array of chosen ids).

  The checkboxes are all part of one `class="field"`, so they
  will all be on the same line.
  """

  def multiple_checkbox_row(f, [{_,_}|_]=tuples, checkbox_field, opts \\ []) do
    opts = Enum.into(opts, %{checked: []})

    ~E"""
    <div class="field">
      <%= for tuple <- tuples,
            do: one_checkbox(f, tuple, checkbox_field, opts.checked)
       %>
     </div>
    """
  end
  
  @doc """
  Like `multiple_checkbox_row`, except that
  1. The values will be stacked horizontally.
  2. Instead of tuples, structs are passed in. The `displayed_field:`
     and `send_field:` options identify the keys in the
     structure to use. They default to `:name` and `:id`. 
  """
  def multiple_checkbox_column(f, structs, checkbox_field, opts \\ []) do
    defaults = %{sent_field: :id, displayed_field: :name, checked: []}
    opts = Enum.into(opts, defaults)
    for struct <- structs do
      sent_value = Map.fetch!(struct, opts.sent_field)
      label_value = Map.fetch!(struct, opts.displayed_field)

      ~E"""
      <div class="field">
        <%= one_checkbox(f, {label_value, sent_value}, checkbox_field, opts.checked) %>
      </div>
      """
    end
  end
  
  defp one_checkbox(f, {label_value, sent_value}, checkbox_field, all_checked) do 
    checkbox_id = input_id(f, checkbox_field, sent_value)
    checkbox_name = input_list_name(f, checkbox_field)

    check_this? = Enum.member?(all_checked, sent_value)

    checkbox_tag = tag(:input,
      name: checkbox_name,
      id: checkbox_id,
      type: "checkbox",
      checked: check_this?,
      value: sent_value)

    label_tag = content_tag(:label, label_value, for: checkbox_id)
    
    ~E"""
    <div class="ui checkbox">
      <%= checkbox_tag %>
      <%= label_tag %>
    </div>
    """
  end
end
