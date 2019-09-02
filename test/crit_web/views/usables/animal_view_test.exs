defmodule CritWeb.Usables.AnimalViewTest do
  use CritWeb.ConnCase, async: true
  import Phoenix.View
  alias Ecto.Changeset
  import Phoenix.HTML.Form
  import Phoenix.HTML, only: [safe_to_string: 1]
  import CritWeb.Usables.AnimalView
  alias Crit.Usables.Animal

  test "full example" do
    path = "--some--path--"
    tag = :"--some--tag--"
    label_text = "--some--label--"
    advice = "--some--advice--"
    default = "--some-default-text"
    controller = "--some-controller--"
    
    calendar = form_for(Animal.changeset(%Animal{}, %{}), path, (fn f ->
      calendar_widget f,
      tag: tag,
      label: label_text,
      advice: advice,
      default: default,
      controller: controller
    end)) |> safe_to_string

    # It's a form
    assert calendar =~ ~r|action="#{path}"|

    # Positioning of helpful text
    assert calendar =~ ~r|<label .*? for="animal_#{tag}" .*? > [[:space:]]*
                             #{label_text} [[:space:]]*
                          </label>  [[:space:]]*
                          #{advice}
                          |sx

    # The text input                          
    assert calendar =~ ~r|<input [[:space:]]
                              class="input"  .*?
                              id="animal_#{tag} .*?
                              value="#{default}"
                              .*?
                          >
                         |sx

    # Where the controllers go
    assert calendar =~ ~r|<div                                          [[:space:]]
                               data-controller="#{controller}"              .*?>.*?
                            <div                                        [[:space:]]
                                 class="field"                          [[:space:]]+
                                 data-target="#{controller}.wrapper"        .*?>.*?
                              <input                                            .*?
                                     data-action="click.*?#{controller}.reveal  .*?
                                     data-target="#{controller}.input"      .*?>.*?
                            </div>                                      [[:space:]]*
                            <div                                        [[:space:]]
                                 id="#{controller}"                     [[:space:]]
                                 display="none"                         >[[:space:]]
                                 # This is where the calendar goes.
                            </div>
                         |sx

#                             
                            #             .*?>

    # assert calendar =~ ~r[]
    # assert calendar =~ ~r[]
    # assert calendar =~ ~r[]

                                  # </label> [[:space]]*
 # {label_text}

    IO.inspect ~S[kjasdlfkj"kjsdlfjk"]
  end

end
