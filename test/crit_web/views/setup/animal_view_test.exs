defmodule CritWeb.Setup.AnimalViewTest do
  use CritWeb.ConnCase, async: true
  alias CritWeb.ViewModels.Setup, as: VM
  import Phoenix.HTML.Form
  import Phoenix.HTML
  alias CritWeb.Setup.AnimalView
  alias Crit.Exemplars, as: Ex
  alias Ecto.Changeset

  describe "Showing of nested service gaps in initial form" do
    defp to_form(%VM.Animal{} = animal) do
      VM.Animal.fresh_form_changeset(animal) |> to_form
    end

    defp to_form(%Changeset{} = changeset) do
      form = form_for(changeset, "unused")
      AnimalView.nested_service_gap_forms(form, changeset)
      |> safe_to_string
    end

    setup do
      repo = Ex.Bossie.create
      [repo: repo]
    end
    
    test "headings when there is no service gap to edit", %{repo: repo} do
      html =
        VM.Animal.fetch(:one_for_edit, repo.bossie.id, @institution)
        |> to_form
      
      assert html =~ "Add a gap"
      refute html =~ "Edit or delete" # no existing changesets
    end

    test "headings when there is a service gap to edit", %{repo: repo} do
      Ex.Bossie.put_service_gap(repo)
      html =
        VM.Animal.fetch(:one_for_edit, repo.bossie.id, @institution)
        |> to_form
      
      assert html =~ "Add a gap"
      assert html =~ "Edit or delete"
    end

    test "that there are distinct ids for the different subforms", %{repo: repo} do
      repo =
        Ex.Bossie.put_service_gap(repo, name: "sg")
      html =
        VM.Animal.fetch(:one_for_edit, repo.bossie.id, @institution)
        |> to_form

      expect = fn datekind, uniquifier ->
        ~s[class="ui calendar" id="#{datekind}_service_datestring__#{uniquifier}_calendar"]
      end
      
      assert html =~ expect.("in", "#{repo.bossie.id}_and_new")
      assert html =~ expect.("out_of", "#{repo.bossie.id}_and_new")

      assert html =~ expect.("in", "#{repo.bossie.id}_#{repo.sg.id}")
      assert html =~ expect.("out_of", "#{repo.bossie.id}_#{repo.sg.id}")
    end
  end
end
