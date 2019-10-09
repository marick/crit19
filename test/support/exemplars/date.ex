defmodule Crit.Exemplars.Date do
  use Crit.Global.Constants

  def iso_today_or_earlier() do 
    iso = Faker.Date.backward(1000) |> Date.to_iso8601
    Enum.random([iso, @today])
  end

  def iso_later_than_today() do
    iso = Faker.Date.forward(1000) |> Date.to_iso8601
    Enum.random([iso, @never])
  end


  def date_pair() do
    import Faker.Date, only: [backward: 1, forward: 1]
    import Date, only: [add: 2]

    kind_of_start = Enum.random(["past", "today", "future"])
    use_never = Enum.random(["never", "some appropriate date"])

    s = &Date.to_iso8601/1

    case {kind_of_start, use_never} do
      {"past", "never"} ->
        { s.(backward(100)), "never"}
      {"past", _} ->
        { s.(backward(100) |> add(-100)), 
          s.(backward(100))
        }

      {"today", "never"} ->
        { "today", "never"}
      {"today", _} ->
        { "today", s.(forward(100)) }

      {"future", "never"} ->
        { s.(forward(100)) , "never" }
      {"future", _} ->
        { s.(forward(100)),
          s.(forward(100) |> add(100))
        }
    end
  end
end
