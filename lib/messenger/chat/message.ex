defmodule Messenger.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :timestamp, :utc_datetime
    field :text, :string
    field :username, :string
    field :room_id, :string
    field :user_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:room_id, :user_id, :username, :text, :timestamp])
    |> validate_required([:room_id, :user_id, :username, :text, :timestamp])
  end
end
