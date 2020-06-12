defmodule CritWeb.Setup.AnimalView do
  use CritWeb, :view
  alias CritWeb.Setup.AnimalController
  alias Phoenix.HTML.Form
  alias Ecto.Changeset

  def animal_form_id(animal) do
    "animal_#{animal.id}"
  end

  @new_service_gap_header ~E"""
    <h4 class="ui center aligned header">
      Add a gap during which the animal cannot be reserved
    </h4>
    """ |> safe_to_string

  @existing_service_gap_header ~E"""
    <h4 class="ui center aligned header">
      Edit or delete earlier gaps
    </h4>
    """ |> safe_to_string

  def nested_service_gap_forms(f, animal_changeset) do
    indexed =
      Changeset.get_field(animal_changeset, :service_gaps)
      |> Enum.with_index

    [empty_form | forms] = 
    for {sg, index} <- indexed do
      gap_f =
        form_for(Changeset.change(sg), "no route")
        |> Map.put(:hidden, [])
        |> Map.put(:id, "#{f.id}_service_gaps_#{index}")
        |> Map.put(:index, index)
        |> Map.put(:name, "#{f.name}[service_gaps][#{index}]")

      {:safe, iodata} = one_service_gap(gap_f, unique_snippet(animal_changeset, gap_f))
      iodata
    end

    new_with_header = 
      [@new_service_gap_header, empty_form]
    
    editable_with_header =
      if Enum.empty?(forms) do
        []
      else
        [@existing_service_gap_header | forms]
      end

    {:safe, [new_with_header, editable_with_header]}
  end    



  def one_service_gap(gap_f, unique_snippet) do
    parts = [
      small_calendar(gap_f, "Unavailable starting:",
        :in_service_datestring, unique: unique_snippet),
      small_calendar(gap_f, "Back on:",
        :out_of_service_datestring, unique: unique_snippet),
      labeled_text_field(gap_f, "Because: ",
        :reason),
      delete_if_exists(gap_f)
    ]
    ~E"""
    <div class="fields">
      <%= parts %>
    </div>
    """
  end

  defp delete_if_exists(f) do
    if Form.input_value(f, :id) do
      labeled_checkbox f, "Delete", :delete
    else
      []
    end
  end

  
end
