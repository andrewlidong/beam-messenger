defmodule Messenger.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Messenger.Accounts.User
  alias Messenger.Conversations.ConversationParticipant

  schema "conversations" do
    field :type, :string
    field :name, :string
    field :description, :string
    field :is_active, :boolean, default: true
    field :last_message_at, :utc_datetime
    field :last_message_text, :string

    belongs_to :created_by, User, foreign_key: :created_by_id
    has_many :participants, ConversationParticipant, foreign_key: :conversation_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:type, :name, :description, :is_active, :created_by_id, :last_message_at, :last_message_text])
    |> validate_required([:type, :created_by_id])
    |> validate_inclusion(:type, ["private", "group"])
    |> validate_group_name()
  end

  defp validate_group_name(changeset) do
    case get_field(changeset, :type) do
      "group" ->
        validate_required(changeset, [:name])
        |> validate_length(:name, min: 1, max: 100)
      _ ->
        changeset
    end
  end
end