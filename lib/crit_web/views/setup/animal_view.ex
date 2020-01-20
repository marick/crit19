defmodule CritWeb.Setup.AnimalView do
  use CritWeb, :view
  alias CritWeb.Setup.AnimalController

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
    {:safe, [empty_form | forms]} = 
      inputs_for(f, :service_gaps, fn gap_f ->
        one_service_gap(gap_f, unique_snippet(animal_changeset, gap_f))
      end)

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
end
