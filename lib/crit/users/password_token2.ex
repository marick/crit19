defmodule Crit.Users.PasswordToken2 do
  use Ecto.Schema
  alias Crit.EmailToken
#  import Ecto.Changeset
#  import Ecto.Query
#  alias Crit.Sql
#  alias Crit.Institutions.Institution

  @schema_prefix "clients"
  
  schema "all_password_tokens" do
    field :text, :string
    field :user_id, :id
    field :institution_short_name, :string

    timestamps(inserted_at: false)
  end

  def new(user_id, institution) do
    %__MODULE__{user_id: user_id,
                institution_short_name: institution,
                text: EmailToken.generate()
    }
  end

  defmodule Query do
    import Ecto.Query
    alias Crit.Users.PasswordToken2

    def by_text(text),
      do: from PasswordToken2, where: [text: ^text]
  
  end
  
end
