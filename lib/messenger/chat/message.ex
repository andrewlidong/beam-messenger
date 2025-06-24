defmodule Messenger.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias Messenger.Accounts.User
  alias Messenger.Conversations.Conversation

  schema "messages" do
    field :timestamp, :utc_datetime
    field :text, :string
    field :username, :string
    field :room_id, :string
    field :user_id, :string
    field :message_type, :string, default: "text"

    belongs_to :conversation, Conversation
    belongs_to :sender, User
    belongs_to :reply_to, __MODULE__, foreign_key: :reply_to_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:room_id, :user_id, :username, :text, :timestamp])
    |> validate_required([:room_id, :user_id, :username, :text, :timestamp])
  end

  @doc false
  def conversation_changeset(message, attrs) do
    message
    |> cast(attrs, [:conversation_id, :sender_id, :text, :timestamp, :message_type, :reply_to_id])
    |> validate_required([:conversation_id, :sender_id, :text, :timestamp])
    |> validate_inclusion(:message_type, ["text", "image", "file", "audio"])
  end
end
