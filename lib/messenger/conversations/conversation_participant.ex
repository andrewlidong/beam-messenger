defmodule Messenger.Conversations.ConversationParticipant do
  use Ecto.Schema
  import Ecto.Changeset

  alias Messenger.Accounts.User
  alias Messenger.Conversations.Conversation

  schema "conversation_participants" do
    field :role, :string, default: "member"
    field :joined_at, :utc_datetime
    field :last_read_at, :utc_datetime
    field :is_active, :boolean, default: true

    belongs_to :conversation, Conversation
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation_participant, attrs) do
    conversation_participant
    |> cast(attrs, [:conversation_id, :user_id, :role, :joined_at, :last_read_at, :is_active])
    |> validate_required([:conversation_id, :user_id])
    |> validate_inclusion(:role, ["admin", "member"])
    |> unique_constraint([:conversation_id, :user_id])
  end
end