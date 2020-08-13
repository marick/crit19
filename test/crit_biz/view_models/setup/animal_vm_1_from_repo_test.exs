defmodule CritBiz.ViewModels.Setup.AnimalVM.FromRepoTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM
  import Crit.Exemplars.Bossie, only: [repo_has_bossie: 1, bossie_has_service_gap: 1]
  alias Crit.RepoState
  alias Crit.Exemplars, as: Ex
  alias Ecto.Changeset
  use FlowAssertions
  use FlowAssertions.NoValueA, no_value: :nothing
  import Crit.Assertions.Changeset

  setup :repo_has_bossie

  # These tests are all about processing VM.Animal structs

  # ----------------------------------------------------------------------------
  describe "`fetch` provides different ways of fetching from database" do
    # Note that these tests implicitly test `lift`.
    setup :bossie_has_service_gap

    test "non-assoc fields are the same for all variants", %{repo: repo} do
      id = repo.bossie.id

      repo
      |> check( [:all_possible              ], :assert_expected_non_assoc_fields)
      |> check( [:all_for_summary_list, [id]], :assert_expected_non_assoc_fields)
      |> check( [:one_for_summary,       id ], :assert_expected_non_assoc_fields)
      |> check( [:one_for_edit,          id ], :assert_expected_non_assoc_fields)
    end

    test "which variants contain service gaps", %{repo: repo} do
      id = repo.bossie.id

      repo
      |> check( [:all_possible              ], :assert_no_service_gaps)
      |> check( [:all_for_summary_list, [id]], :assert_no_service_gaps)
      |> check( [:one_for_summary,       id ], :assert_no_service_gaps)
      
      |> check( [:one_for_edit,          id ], :assert_bossie_service_gap)
    end

    test "fetching is in alphabetical order", %{repo: repo} do
      ["bz", "b", "a"] |> Enum.map(&RepoState.animal(repo, &1))

      actual = 
        VM.Animal.fetch(:all_possible, @institution) |> EnumX.names

      assert actual == ["a", "b", "Bossie", "bz"]
    end
  end

  # ----------------------------------------------------------------------------
  describe "constructing a form changeset from an animal" do
    test "fresh form changeset - no service gaps", %{repo: repo} do
      VM.Animal.fetch(:one_for_edit, repo.bossie.id, @institution)
      |> VM.Animal.fresh_form_changeset
      |> assert_no_changes
      |> with_singleton(:old!, :service_gaps)
         |> assert_fields(reason: "",
                          in_service_datestring: "",
                          out_of_service_datestring: "")
    end

    test "fresh form changeset - a service gap", %{repo: repo} do
      Ex.Bossie.put_service_gap(repo, span: :first, reason: "exists")
      
      animal = 
        VM.Animal.fetch(:one_for_edit, repo.bossie.id, @institution)
        |> VM.Animal.fresh_form_changeset
        |> assert_no_changes
      
      [empty, only] = Changeset.fetch_field!(animal, :service_gaps)

      empty
      |> assert_fields(reason: "",
                       in_service_datestring: "",
                       out_of_service_datestring: "")

      only
      |> assert_field(reason: "exists")
      |> Ex.Datespan.assert_datestrings(:first)
    end
  end

  # ----------------------------------------------------------------------------
  
  def assert_expected_non_assoc_fields(list, repo) when is_list(list),
    do: singleton_content(list) |> assert_expected_non_assoc_fields(repo)

  def assert_expected_non_assoc_fields(view_model, repo), 
    do: Ex.Bossie.assert_view_model_for(view_model, id: repo.bossie.id)

  def assert_no_service_gaps(list, repo) when is_list(list),
    do: singleton_content(list) |> assert_no_service_gaps(repo)

  def assert_no_service_gaps(view_model, _repo),
    do: refute_assoc_loaded(view_model, :service_gaps)
    
  def assert_bossie_service_gap(view_model, _repo) do 
    view_model
    |> assert_assoc_loaded(:service_gaps)
    |> with_singleton_content(:service_gaps)
       |> assert_shape(%VM.ServiceGap{})
       |> Ex.Datespan.assert_datestrings(:first)
  end
    
  # ----------------------------------------------------------------------------

  def check(repo, arglist, assertion) do
    result = apply(VM.Animal, :fetch, arglist ++ [@institution])
    apply(__MODULE__, assertion, [result, repo])
    repo
  end
end
