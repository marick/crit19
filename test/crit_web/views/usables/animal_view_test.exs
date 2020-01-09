defmodule CritWeb.Usables.AnimalViewTest do
  use CritWeb.ConnCase, async: true
  import Phoenix.HTML.Form
  import Phoenix.HTML, only: [safe_to_string: 1]
  import CritWeb.Usables.AnimalView
  alias Crit.Usables.Schemas.BulkAnimal

  # Since JavaScript does much of the work, this isn't much of a test.
  test "calendar_with_alternatives" do
    path = "--some--path--"
    label = "--some--longish-label-for-the-whole-collection--"
    advice = "--some--advice--"
    
    calendar = form_for(BulkAnimal.changeset(%BulkAnimal{}, %{}), path, (fn f ->
      calendar_with_alternatives(f, label, :in_service_gap,
          advice: advice,
          alternative: "Today")
        end)) |> safe_to_string


    # Boilerplate text
    assert calendar =~ label
    assert calendar =~ advice

    # Certain values provided to Stimulus
    assert calendar =~ ~S|jquery-arg="#in_service_gap_calendar"|
    # Note that it's downcased from the `alternate` text, which is used as a
    # `<label>`. What we see below is a value for the controller to stuff
    # into the all-important `hidden` field.
    assert calendar =~ ~S|radio-value="today"|

    assert calendar =~ ~S|<label for="in_service_gap_radio">Today</label>|

    


    # I'm leaving behind detailed regexes for old versions, should I ever
    # be made enough to want to use such. (I did this because I wanted to
    # see how it would look with space-ignoring regexes.)
    #
    # Note that this:
    #        calendar |> :binary.bin_to_list |> :xmerl_scan.string
    # ... doesn't work because `form_for` generates two `input` fields that
    # aren't properly closed, as far as XML is concerned. 
    
    
    # # Positioning of helpful text
    # assert calendar =~ ~r|<label .*? for="bulk_animal_#{tag}" .*? > [[:space:]]*
    #                          #{label_text} [[:space:]]*
    #                       </label>  [[:space:]]*
    #                       #{advice}
    #                       |sx

    # # The text input                          
    # assert calendar =~ ~r|<input [[:space:]]
    #                           class="input"  .*?
    #                           id="bulk_animal_#{tag} .*?
    #                       >
    #                      |sx

    # # Where the controllers go
    # assert calendar =~ ~r|<div                                          [[:space:]]
    #                            data-controller="calendar"              .*?>.*?
    #                         <div                                        [[:space:]]
    #                              class="field"                          [[:space:]]+
    #                              data-target="calendar.wrapper"        .*?>.*?
    #                           <input                                   .*?
    #                               data-action="click.*?#calendar.reveal .*?
    #                               data-target="calendar.inp ut"        .*?>.*?
    #                         </div>                                      [[:space:]]*
    #                         <div                                        [[:space:]]
    #                              data-target="calendar.div"             [[:space:]]
    #                              display="none"                         >[[:space:]]
    #                              # This is where the calendar goes.
    #                         </div>
    #                      |sx
  end
end
