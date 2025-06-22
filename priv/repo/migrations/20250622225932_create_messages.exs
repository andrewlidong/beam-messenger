defmodule Messenger.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :room_id, :string
      add :user_id, :string
      add :username, :string
      add :text, :text
      add :timestamp, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
