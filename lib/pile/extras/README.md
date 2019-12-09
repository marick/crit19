These are useful extensions to Elixir, Phoenix, or Ecto data
types. Because Elixir doesn't let you add to an API by aliasing it
twice (as, say, Elm) does, I have a naming convention:

```elixir

alias Ecto.Changeset
alias Ecto.ChangesetX

alias MapX

...

    |> Changeset.add_error(field, message)
    |> ChangesetX.ensure_forms_display_errors

```


