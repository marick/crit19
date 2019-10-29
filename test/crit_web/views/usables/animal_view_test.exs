defmodule CritWeb.Usables.AnimalViewTest do
  use CritWeb.ConnCase, async: true
  import Phoenix.HTML.Form
  import Phoenix.HTML, only: [safe_to_string: 1]
  import CritWeb.Usables.AnimalView
  alias Crit.Usables.Schemas.BulkAnimal

  test "full example" do
    path = "--some--path--"
    tag = :"--some--tag--"
    label_text = "--some--label--"
    advice = "--some--advice--"
    controller = "--some-controller--"
    
    calendar = form_for(BulkAnimal.changeset(%BulkAnimal{}, %{}), path, (fn f ->
      big_calendar_widget f,
      tag: tag,
      label: label_text,
      advice: advice,
      controller: controller
    end)) |> safe_to_string

    
    # It's a form
    assert calendar =~ ~r|action="#{path}"|

    # Positioning of helpful text
    assert calendar =~ ~r|<label .*? for="bulk_animal_#{tag}" .*? > [[:space:]]*
                             #{label_text} [[:space:]]*
                          </label>  [[:space:]]*
                          #{advice}
                          |sx

    # The text input                          
    assert calendar =~ ~r|<input [[:space:]]
                              class="input"  .*?
                              id="bulk_animal_#{tag} .*?
                          >
                         |sx

    # Where the controllers go
    assert calendar =~ ~r|<div                                          [[:space:]]
                               data-controller="calendar"              .*?>.*?
                            <div                                        [[:space:]]
                                 class="field"                          [[:space:]]+
                                 data-target="calendar.wrapper"        .*?>.*?
                              <input                                   .*?
                                  data-action="click.*?#calendar.reveal .*?
                                  data-target="calendar.inp ut"        .*?>.*?
                            </div>                                      [[:space:]]*
                            <div                                        [[:space:]]
                                 data-target="calendar.div"             [[:space:]]
                                 display="none"                         >[[:space:]]
                                 # This is where the calendar goes.
                            </div>
                         |sx
  end
end
