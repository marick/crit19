defmodule Crit.Reservations.RestPeriod do
  import Ecto.Query
  alias Crit.Sql
  alias Crit.Schemas.{Animal,Procedure, Use, Reservation}
  alias Ecto.Datespan
  import Ecto.Datespan  # This has to be imported for query construction.

  def unavailable_by(struct, institution) do
    chosen_procedures =
      Procedure.Get.all_by_ids(struct.chosen_procedure_ids,
        institution,
        preload: [:frequency])
    
    pairs =
      EnumX.cross_product(struct.chosen_animal_ids, chosen_procedures)

    [first | rest] = 
    for {animal_id, procedure} <- pairs do
      query = (from a in Animal, where: [id: ^animal_id])
      one_procedure_uses(query, procedure.frequency.calculation_name, struct.date, procedure.id)
    end

    Enum.reduce(rest, first, fn q, acc ->
      union(acc, ^q)
    end)
    |> Sql.all(institution)
  end

  def one_procedure_uses(query, "once per day", desired_date, procedure_id) do
    where_uses_centered_range(desired_date, 1) |> full_query(query, procedure_id)
  end

  def one_procedure_uses(query, "once per week", desired_date, procedure_id) do
    where_uses_centered_range(desired_date, 7) |> full_query(query, procedure_id)
  end

  def one_procedure_uses(query, "twice per week", desired_date, procedure_id) do
    two_days =
      where_uses_centered_range(desired_date, 2) |> full_query(query, procedure_id)
    week =
      where_uses_week_range(desired_date) |> full_query(query, procedure_id)

    union(two_days, ^week)
  end

  def one_procedure_uses(query, "unlimited", _desired_date, procedure_id) do
    f = fn query ->
      where(query, [_a], 1 == 2)
    end

    full_query(f, query, procedure_id)
  end

  #-----------------------------------------------------

  def joins(query, procedure_id) do
    from a in query,
      join: p in Procedure, on: p.id == ^procedure_id,
      join: u in Use, on: u.procedure_id == ^procedure_id,
      join: r in Reservation, on: u.reservation_id == r.id,
      group_by: [a.name, p.name]
  end

  def where_uses_centered_range(desired_date, days) do
    conflicting_range = centered_date_range(desired_date, days)
    fn query -> 
      where(query, [..., r], contains_point_fragment(^conflicting_range, r.date))
    end
  end

  def where_uses_week_range(desired_date) do
    conflicting_range = week_date_range(desired_date)
    fn query ->
      query
      |> where([..., r], contains_point_fragment(^conflicting_range, r.date))
      |> having([a], count(a.id) > 1)
    end
  end

  def describe_result(query) do
    from [a, p, _u, r] in query,
      select: %{animal_name: a.name,
                procedure_name: p.name,
                dates: fragment("array_agg(?)", r.date)}
  end

  def full_query(where_maker, query, procedure_id) do
    joins(query, procedure_id)
    |> where_maker.()
    |> describe_result
  end

  #-----------------------------------------------------
  
  defp week_date_range(date) do 
    day_of_week = Calendar.Date.day_of_week_zb(date)
    sunday =           Date.add(date, 0 - day_of_week)
    following_sunday = Date.add(date, 7 - day_of_week)
    date_range(sunday, following_sunday)
  end

  defp centered_date_range(date, width) do
    first = Date.add(date, -(width - 1))
    after_last = Date.add(date, width)
    date_range(first, after_last)
  end

  defp date_range(first, after_last) do
    Datespan.customary(first, after_last) |> Datespan.dump!
  end
end
