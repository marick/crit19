# A testing language for Phoenix form processing

This file describes a "little language" for testing Phoenix form
handling. Form handling is similar enough from one form to another
that it's fairly easy to make a language to describe test cases in a way
that's concise, declarative, and easy to write.

There are cases where a more procedural, ["arrange, act, assert"](https://xp123.com/articles/3a-arrange-act-assert/) style is
needed. The little language can help with those as well, but I don't
talk about it here.

## Background

Unusually for a Phoenix app (I think), I use two separate Ecto schemas
to translate from a form on a webpage to rows to be inserted or
updated in a Postgres table.  This approach isn't tied to that,
but I need to describe it so the examples make sense.


For each form-to-table transformation, there's a responsible module in
[`lib/crit_biz/view_models`](/lib/crit_biz/view_models). I'll use
[`BulkAnimal`](/lib/crit_biz/view_models/setup/bulk_animal_vm.ex) for these examples. In code,
it's always aliased to `VM.BulkAnimal`.


It describes the fields on a form used to create many animals. That
form looks like this:

![Creating animals](pics/create_animals.png)

In this example, three new horses named "Jake", "Bouncer", and
"Galaxy" are being entered into service starting today, with an end
date a few months from now. `VM.BulkAnimal` describes that form:

```elixir
  @primary_key false
  embedded_schema do
    field :names, :string,                      default: ""
    field :species_id, :integer
    field :in_service_datestring, :string,      default: @today
    field :out_of_service_datestring, :string,  default: @never
```

Code in the module is an implicit state machine that handles three
steps in processing the form: *validation*, *lowering*, and
*insertion*.

1. **Validation** looks for errors in user input. For example, the
   `names` field can't be empty or something nonsensical like `",
   "`. The out-of-service datestring can't be before today.
   
   If there's a validation error, a form populated with an error message
   is to be sent back by the controller. The mechanism to do this in Phoenix
   is to populate the form with a `Changeset`, which is a structure that
   contains both form values and error messages (as well as some other things).
   
   If there's no error, ...
   
2. **Lowering** converts the `VM.BulkAnimal` structure into one or more
   `Schemas.Animal` structures that look like this:
   
        ```elixir
        schema "animals" do
          field :name, TrimmedString
          field :span, Datespan
          field :available, :boolean, default: true
          field :lock_version, :integer, default: 1
          belongs_to :species, Schemas.Species
          has_many :service_gaps, Schemas.ServiceGap
          timestamps()
        end
        ```
   
   Things to note: 
   * The `names` field has gone away. Each animal has its own `name`. 
   * Some fields irrelevant to creation (`available` and `lock_version`)
     are filled with defaults here.
   * The two strings describing the dates the animal is in service have
     been converted to a single `Datespan` (which, in turn, will become
     a Postgres range of dates). 

   Lowering (so called because the value closer to the user is converted
   to one closer to the database) does this convertion. Note that it
   can't fail (unless there's a bug). So the next step is always...
   
3. **Inserting** the three `Schema.Animals` is a simple transactional
   insert with only one interesting thing about it: there's a database
   uniqueness constraint on animal names. So the insertion can
   fail. If so, the original `VM.BulkAnimal` is used to indicate the
   error. 
   
   
I find separating what's on the form and what's in the database is
less confusing, as is not trying to handle both validation and
constraint errors in the same way. 


## Exemplars

One of my slogans for testing is that you should avoid using words in
a test that aren't relevant to the purpose of the test. That makes
tests more readable. More precisely, it makes them more *skimmable*,
as Geepaw Hill explains. When you read a test some time after it was
written, you're typically coming to it with some narrow question that
you want to answer quickly. You're acting according to the surgeon's
motto: Get In, Get Done, and Get Out.

Sometimes you want to find out why this test is failing. Sometimes
you're skimming through tests to find how each test differs from
similar tests. For this reason, a regular structure is useful. I'm
fond of tables, but also of hierarchical structures.

Moreover, a complete set of tests for a particular module should
suggest, through examples, a complete list of the kinds of values the
module will have to process. Each one should represent - skimmably -
something special that required special code to be written.

I've taken to calling these "exemplars". They're not just any old
examples: they're "a model or pattern to be copied or imitated", a
"*typical* example or instance". I've also started putting those
exemplars in files where they serve as pictures of the kinds of data
the module processes.

## The description language, up through validation

Here's the very rough structure of a set of exemplars for `VM.BulkAnimal`:

```elixir
  @test_data build(
    module_under_test: VM.BulkAnimal,
    produces: Schemas.Animal,

    exemplars: [...])
```

If I were test-driving the `module_under_test`, I'd probably start by
thinking about a valid case. What's an exemplary creation of animals?
How about this?

```elixir
      valid: %{params: to_strings(%{names: "a, b, c",
                                    species_id: @bovine_id,
                                    in_service_datestring: @iso_date_1,
                                    out_of_service_datestring: @iso_date_2}),
              },
```

The most important bit is the `names` field, which declares this
example is about the creation of three animals. `to_strings` converts
the easier-to-type parameters into the fully-stringified form that
would be passed to a Phoenix Controller in real life (and thus
immediately passed to `VM.BulkAnimal`). That real data would look like this:

```elixir
%{
  "in_service_datestring" => "2201-01-01",
  "names" => "a, b, c",
  "out_of_service_datestring" => "2202-02-02",
  "species_id" => "1"
}
```

Although I might think about this exemplar first, I'd probably start
test-driving the module with an error case. The reason is that
validation will immediately fail, so I don't have to worry about
lowering a `VM.BulkAnimal` into several `Schemas.Animals`. I'll
arbitrarily pick a case where dates are out of order:

```elixir
      out_of_order: %{
        params: like(:valid,
          except: %{in_service_datestring: @iso_date_4,
                    out_of_service_datestring: @iso_date_3}),
        errors: [out_of_service_datestring: @date_misorder_message]}
```  

Notice that the parameters are described as being `like` the `:valid`
parameters except that they have datestrings in the opposite
order. The names being created aren't relevant in this case, so I
don't want to mention them.

The invalid params should add a particular error message ("should not
be before the start date") to the changeset, identifying the error
with the second datestring.

When the form is re-displayed to the user, all of the parameters
should have the values the user set. For example, the text field for
the `:names` should have whatever the `:valid` value is, not be blank
like in the original form. There's nothing about that in the test
because I think that goes without saying. It's only worth highlighting
any case where that *doesn't* happen.

Therefore, checking an exemplar means checking that the changeset
resulting from the validation step is populated with the values from
the params. I find it convenient to list the fields that the module-under-test is "about" up at the top of the description:


```elixir
  @test_data build(
    module_under_test: VM.BulkAnimal,
    produces: Schemas.Animal,
    validates: [:names,
                :species_id,
                :in_service_datestring, :out_of_service_datestring],
```

(Individual exemplars can't override the global data.)

## Describing dependencies

There's more than one way a pair of datestrings can be wrong. In the
exemplar we've been working with, it's because an explicit ISO8601
datestring is not before another one. But what if the form uses
"today" instead of an explicit value? That's also an error. Should
there be a separate `VM.BulkAnimal` test for that?

Well, consider: pairs of in-service and out-of service dates are all
over the code. You'd expect there to be a single function to call to
check such pairs. There is, it's called `FieldValidators.date_order`,
it's got its own tests, and it's used by `VM.BulkAnimal.accept_form`:


```elixir
  def accept_form(params, institution) do
    changeset = 
      %__MODULE__{institution: institution}
      |> changeset(params)
      |> FieldValidators.date_order
      |> FieldValidators.namelist(:names)
    summarize_validation(changeset, changeset.valid?, error_subtype: :form)
```

There's already a test showing that `date_order` works for all *its*
relevant exemplars. We only care about how `accept_form` *uses* the
results from `date_order`. And what it does with the results
is... nothing, really. Specifically, `FieldValidators.date_order` just
(maybe) adds an error to a changeset, and `accept_form` just passes
the resulting changeset on.

So parameters that use "today" incorrectly tells us nothing exemplary
about `VM.BulkAnimal`... *provided* we know that it uses
`FieldValidators.namelist`. That's an interesting fact we might want
to document, so long as it's easy. For example, we don't really want
someone else to come across these exemplars, tut-tut about a missing
case, and add it.

So we'll use the single exemplar to document the fact that the
correctness of our module-under-test depends on the correctness of
some other module:

```elixir
      out_of_order: %{
        shows_delegation: {FieldValidators, :date_order},   #<<<<<
        params: like(:valid,
          except: %{in_service_datestring: @iso_date_4,
                    out_of_service_datestring: @iso_date_3}),
        errors: [out_of_service_datestring: @date_misorder_message],
```

The test runner watches (using [Mockery](https://github.com/appunite/mockery)) to see whether the execution
of the `out_of_order` test calls `FieldValidators.date_order` and
fails if it doesn't.

## Lowering

Lowering only applies when the parameters have passed the validation
check. Lowering uses the information from the "higher" structure to
fill in fields in the lower structure. Given the context of
transforming form values into database values, there really aren't a
lot of possibilities. In the case of a lowering from `VM.BulkAnimal`
to `Schemas.Animal`, there are three:


1. The `species_id` is just a validated field copied from one to the other. That will
   happen in exactly the same way no matter what the HTTP parameters
   are, so long as they're valid. So we can state that fact at the
   global scope:

   ```elixir
    module_under_test: VM.BulkAnimal,
    produces: Schemas.Animal,
    validates: [:names, ...],
    lowering_retains: [:species_id],     # <<<<<<
   ```
   
2. `Schemas.Animal` has a `span` field that's synthesized from the two
   datestrings. Its value depends on the specific parameter values. So
   we have to describe it in the exemplar:

   ```
   %{params: to_strings(%{names: "a, b, c",
                          species_id: @bovine_id,
                          in_service_datestring: @iso_date_1,
                          out_of_service_datestring: @iso_date_2}),
               lowering_adds: %{span: Datespan.customary(@date_1, @date_2)},
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   ```

   (Note that this test depends on knowing that `@date_1` is the
   `Date` corresponding to the string `@iso_date_1`. Even if a reader
   didn't know that coming to this code - hard to do, since the
   predefined dates are used everywhere - I don't think that's a very
   difficult inference to make.

3. Finally, the `"a, b, c"` in the `:names` field are used to create
   three different `Schemas.Animal` structures. That can be represented
   straightforwardly. Since that's a fact true for all valid values of `:names`,
   it can also be stated at the top level:
   
   ```elixir
    module_under_test: VM.BulkAnimal,
    produces: Schemas.Animal,
    validates: [:names, ...],
    lowering_retains: [:species_id],
    lowering_splits: %{:names => :name},   #<<<<<
   ```
   
   We don't have to describe how many different `Schemas.Animals` are
   created; that's implied by the data. We don't have to extract the
   individual names ourselves: the test runner can use the same
   (tested) comma-separated-string-handling code the code being tested
   does.
   
   This same notation works for different transformation. For example,
   a single form lets you create the same procedure (same name) for N
   different species. Here's its test description:

   ```elixir
     @test_data build(
       ...
       validates: [:name, :species_ids, :frequency_id],
         
       lowering_splits: %{:species_ids => :species_id},   #<<<<
       lowering_retains: [:name, :frequency_id],
   
       exemplars: [
         two_species: %{
           categories: [:valid, :filled],
           params: to_strings(%{name: "two species",
                                species_ids: [@bovine_id, @equine_id],  #<<<<
                                frequency_id: @once_per_week_frequency_id}),
         },
   ```
       
   When the test runner sees that the `species_ids` field has a list value,
   it knows that each element of a `VM.BulkProcedure` should be used to
   create a `Schemas.Procedure` with a different `:species_id` field.
